import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/features/routes/routeconstants.dart';
import 'package:rescueeats/core/model/restaurantModel.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/screens/admin/provider/adminProvider.dart';
import 'package:rescueeats/screens/admin/widgets/emptyState.dart';
import 'package:rescueeats/screens/admin/widgets/errorWidget.dart';
import 'package:rescueeats/screens/admin/widgets/loadingShimmer.dart';

class AdminRestaurantsTab extends ConsumerStatefulWidget {
  const AdminRestaurantsTab({super.key});

  @override
  ConsumerState<AdminRestaurantsTab> createState() =>
      _AdminRestaurantsTabState();
}

class _AdminRestaurantsTabState extends ConsumerState<AdminRestaurantsTab> {
  String _searchQuery = '';
  bool? _filterOpen;

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(allRestaurantsProvider);

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
                  hintText: 'Search restaurants...',
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
              // Status Filter and Add Button
              Row(
                children: [
                  _buildFilterChip('All', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Open', true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Closed', false),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push(RouteConstants.createRestaurant);
                    },
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text(
                      'Add',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Restaurants List
        Expanded(
          child: restaurantsAsync.when(
            loading: () =>
                const LoadingShimmer(type: ShimmerType.list, count: 5),
            error: (err, stack) => ErrorStateWidget(
              error: err.toString(),
              onRetry: () => ref.invalidate(allRestaurantsProvider),
            ),
            data: (restaurants) {
              // Filter restaurants
              var filteredRestaurants = restaurants.where((restaurant) {
                final matchesSearch = restaurant.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
                final matchesStatus =
                    _filterOpen == null || restaurant.isOpen == _filterOpen;
                return matchesSearch && matchesStatus;
              }).toList();

              if (filteredRestaurants.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.store_outlined,
                  title: 'No Restaurants Found',
                  message: _searchQuery.isNotEmpty
                      ? 'No restaurants match your search'
                      : 'No restaurants available',
                  actionLabel: 'Refresh',
                  onAction: () => ref.invalidate(allRestaurantsProvider),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(allRestaurantsProvider),
                child: ListView.separated(
                  padding: EdgeInsets.all(context.padding.medium),
                  itemCount: filteredRestaurants.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildRestaurantCard(filteredRestaurants[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool? status) {
    final isSelected = _filterOpen == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterOpen = selected ? status : null);
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

  Widget _buildRestaurantCard(RestaurantModel restaurant) {
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
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: restaurant.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: restaurant.image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            title: Text(
              restaurant.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  restaurant.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      restaurant.isOpen ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: restaurant.isOpen ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      restaurant.isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        fontSize: 12,
                        color: restaurant.isOpen ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${restaurant.openingTime} - ${restaurant.closingTime}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        restaurant.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
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
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(Icons.toggle_on, size: 20),
                      SizedBox(width: 8),
                      Text('Toggle Status'),
                    ],
                  ),
                ),
                // Delete Restaurant disabled - backend doesn't support this operation
                /*
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
                */
              ],
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    _showRestaurantDetails(restaurant);
                    break;
                  case 'toggle':
                    _toggleRestaurantStatus(restaurant);
                    break;
                  // Delete disabled - not supported by backend
                }
              },
            ),
          ),
          // Cuisines
          if (restaurant.cuisines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: restaurant.cuisines.map((cuisine) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cuisine,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.restaurant, color: Colors.grey),
    );
  }

  void _toggleRestaurantStatus(RestaurantModel restaurant) async {
    try {
      await ref
          .read(adminControllerProvider.notifier)
          .toggleRestaurantStatus(restaurant.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restaurant status toggled to ${!restaurant.isOpen ? "Open" : "Closed"}',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRestaurantDetails(RestaurantModel restaurant) {
    showDialog(
      context: context,
      builder: (context) => _RestaurantDetailsDialog(restaurant: restaurant),
    );
  }
}

class _RestaurantDetailsDialog extends ConsumerStatefulWidget {
  final RestaurantModel restaurant;

  const _RestaurantDetailsDialog({required this.restaurant});

  @override
  ConsumerState<_RestaurantDetailsDialog> createState() =>
      _RestaurantDetailsDialogState();
}

class _RestaurantDetailsDialogState
    extends ConsumerState<_RestaurantDetailsDialog> {
  String? _selectedOwnerId;
  bool _isAssigning = false;

  @override
  Widget build(BuildContext context) {
    final restaurantOwnersAsync = ref.watch(restaurantOwnersProvider);

    return AlertDialog(
      title: Text(widget.restaurant.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Description', widget.restaurant.description),
            _buildDetailRow('Address', widget.restaurant.address),
            _buildDetailRow('Phone', widget.restaurant.phone),
            _buildDetailRow(
              'Hours',
              '${widget.restaurant.openingTime} - ${widget.restaurant.closingTime}',
            ),
            _buildDetailRow(
              'Status',
              widget.restaurant.isOpen ? 'Open' : 'Closed',
            ),
            _buildDetailRow('Cuisines', widget.restaurant.cuisines.join(', ')),
            const Divider(height: 24),
            const Text(
              'Owner Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Owner ID',
              widget.restaurant.ownerId ?? 'Not Assigned',
            ),
            _buildDetailRow(
              'Owner Name',
              widget.restaurant.ownerName ?? 'Not Assigned',
            ),
            _buildDetailRow(
              'Owner Email',
              widget.restaurant.ownerEmail ?? 'Not Assigned',
            ),
            const SizedBox(height: 16),
            const Text(
              'Assign Owner',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            restaurantOwnersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Text(
                'Error loading owners: $err',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
              data: (owners) {
                if (owners.isEmpty) {
                  return const Text(
                    'No restaurant owners available',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedOwnerId,
                      decoration: InputDecoration(
                        hintText: 'Select owner',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: owners.map((owner) {
                        return DropdownMenuItem(
                          value: owner.id,
                          child: Text(
                            '${owner.name} (${owner.email})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedOwnerId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedOwnerId == null || _isAssigning
                            ? null
                            : () => _assignOwner(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isAssigning
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Assign Owner',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _assignOwner() async {
    if (_selectedOwnerId == null) return;

    setState(() => _isAssigning = true);

    try {
      await ref
          .read(adminControllerProvider.notifier)
          .assignOwner(widget.restaurant.id, _selectedOwnerId!);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign owner: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }
}
