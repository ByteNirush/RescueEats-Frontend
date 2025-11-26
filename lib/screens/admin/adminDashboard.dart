import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/features/routes/routeconstants.dart';
import 'package:rescueeats/screens/admin/tabs/adminOrdersTab.dart';
import 'package:rescueeats/screens/admin/tabs/adminOverviewTab.dart';
import 'package:rescueeats/screens/admin/tabs/adminRestaurantsTab.dart';
import 'package:rescueeats/screens/admin/tabs/adminUsersTab.dart';
import 'package:rescueeats/screens/auth/provider/authprovider.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () {
              // Refresh all providers
              setState(() {});
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Users"),
            Tab(text: "Restaurants"),
            Tab(text: "Orders"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminOverviewTab(),
          AdminUsersTab(),
          AdminRestaurantsTab(),
          AdminOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF8C42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Administrator",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDrawerItem(
            Icons.dashboard_outlined,
            "Dashboard",
            () => Navigator.pop(context),
          ),
          _buildDrawerItem(Icons.people_outline, "Users", () {
            Navigator.pop(context);
            _tabController.animateTo(1);
          }),
          _buildDrawerItem(Icons.store_outlined, "Restaurants", () {
            Navigator.pop(context);
            _tabController.animateTo(2);
          }),
          _buildDrawerItem(Icons.receipt_long_outlined, "Orders", () {
            Navigator.pop(context);
            _tabController.animateTo(3);
          }),
          const Divider(),
          _buildDrawerItem(Icons.analytics_outlined, "Analytics", () {
            Navigator.pop(context);
            _tabController.animateTo(0);
          }),
          const Spacer(),
          const Divider(),
          _buildDrawerItem(Icons.logout, "Logout", () {
            Navigator.pop(context);
            _showLogoutDialog(context);
          }, isDestructive: true),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black54),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              context.go(RouteConstants.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
