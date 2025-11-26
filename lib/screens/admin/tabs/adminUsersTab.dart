import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/model/userModel.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/screens/admin/provider/adminProvider.dart';
import 'package:rescueeats/screens/admin/widgets/emptyState.dart';
import 'package:rescueeats/screens/admin/widgets/errorWidget.dart';
import 'package:rescueeats/screens/admin/widgets/loadingShimmer.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  String _searchQuery = '';
  UserRole? _filterRole;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: EdgeInsets.all(context.padding.medium),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search users by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              // Role Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Customers', UserRole.user),
                    const SizedBox(width: 8),
                    _buildFilterChip('Restaurants', UserRole.restaurant),
                    const SizedBox(width: 8),
                    _buildFilterChip('Delivery', UserRole.delivery),
                    const SizedBox(width: 8),
                    _buildFilterChip('Admins', UserRole.admin),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Users List
        Expanded(
          child: usersAsync.when(
            loading: () =>
                const LoadingShimmer(type: ShimmerType.list, count: 6),
            error: (err, stack) => ErrorStateWidget(
              error: err.toString(),
              onRetry: () => ref.invalidate(allUsersProvider),
            ),
            data: (users) {
              // Filter users
              var filteredUsers = users.where((user) {
                final matchesSearch =
                    user.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    user.email.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
                final matchesRole =
                    _filterRole == null || user.role == _filterRole;
                return matchesSearch && matchesRole;
              }).toList();

              if (filteredUsers.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.people_outlined,
                  title: 'No Users Found',
                  message: _searchQuery.isNotEmpty
                      ? 'No users match your search'
                      : 'No users available',
                  actionLabel: 'Refresh',
                  onAction: () => ref.invalidate(allUsersProvider),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(allUsersProvider),
                child: ListView.separated(
                  padding: EdgeInsets.all(context.padding.medium),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildUserCard(filteredUsers[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, UserRole? role) {
    final isSelected = _filterRole == role;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterRole = selected ? role : null);
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
          child: Icon(
            _getRoleIcon(user.role),
            color: _getRoleColor(user.role),
            size: 28,
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.email, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user.email,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  user.phoneNumber ?? 'N/A',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getRoleName(user.role),
                    style: TextStyle(
                      fontSize: 11,
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Joined ${dateFormat.format(user.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit Role'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showUserDetails(user);
                break;
              case 'edit':
                _showEditRoleDialog(user);
                break;
              case 'delete':
                _showDeleteConfirmation(user);
                break;
            }
          },
        ),
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
              child: Icon(
                _getRoleIcon(user.role),
                color: _getRoleColor(user.role),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(user.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Phone', user.phoneNumber ?? 'N/A'),
              _buildDetailRow('Role', _getRoleName(user.role)),
              _buildDetailRow('User ID', user.id),
              _buildDetailRow('Joined', dateFormat.format(user.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(UserModel user) {
    UserRole selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Change role for ${user.name}'),
              const SizedBox(height: 16),
              ...UserRole.values.map(
                (role) => RadioListTile<UserRole>(
                  title: Text(_getRoleName(role)),
                  value: role,
                  groupValue: selectedRole,
                  onChanged: (value) {
                    setState(() => selectedRole = value!);
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(adminControllerProvider.notifier)
                    .updateUserRole(user.id, selectedRole);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'User role updated to ${_getRoleName(selectedRole)}',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(adminControllerProvider.notifier).deleteUser(user.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'Customer';
      case UserRole.restaurant:
        return 'Restaurant';
      case UserRole.delivery:
        return 'Delivery Partner';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Icons.person;
      case UserRole.restaurant:
        return Icons.store;
      case UserRole.delivery:
        return Icons.delivery_dining;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Colors.blue;
      case UserRole.restaurant:
        return Colors.orange;
      case UserRole.delivery:
        return Colors.green;
      case UserRole.admin:
        return Colors.purple;
    }
  }
}
