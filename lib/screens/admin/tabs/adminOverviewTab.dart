import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/screens/admin/provider/adminProvider.dart';
import 'package:rescueeats/screens/admin/widgets/adminStatCard.dart';
import 'package:rescueeats/screens/admin/widgets/emptyState.dart';
import 'package:rescueeats/screens/admin/widgets/errorWidget.dart';
import 'package:shimmer/shimmer.dart';

class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(analyticsProvider);
        ref.invalidate(revenueStatsProvider);
        ref.invalidate(userStatsProvider);
        ref.invalidate(restaurantStatsProvider);
      },
      child: analyticsAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, stack) => ErrorStateWidget(
          error: error.toString(),
          onRetry: () {
            ref.invalidate(analyticsProvider);
          },
        ),
        data: (analytics) => _buildContent(context, analytics),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildShimmerGrid(4),
          const SizedBox(height: 32),
          _buildShimmerGrid(4),
          const SizedBox(height: 32),
          _buildShimmerGrid(3),
          const SizedBox(height: 32),
          _buildShimmerGrid(4),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid(int count) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemCount: count,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> analytics) {
    final revenue = analytics['revenue'] as Map<String, dynamic>?;
    final users = analytics['users'] as Map<String, dynamic>?;
    final restaurants = analytics['restaurants'] as Map<String, dynamic>?;
    final orders = analytics['orders'] as Map<String, dynamic>?;

    if (revenue == null &&
        users == null &&
        restaurants == null &&
        orders == null) {
      return EmptyStateWidget(
        icon: Icons.analytics_outlined,
        title: 'No Data Available',
        message: 'Analytics data will appear here once you have some activity.',
        actionLabel: 'Refresh',
        onAction: () {},
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(context.padding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Revenue Section
          _buildSectionHeader('Revenue', Icons.attach_money),
          const SizedBox(height: 12),
          if (revenue != null)
            GridView.count(
              crossAxisCount: context.isTablet ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                AdminStatCard(
                  icon: Icons.today,
                  title: 'Today',
                  value: currencyFormat.format(revenue['today'] ?? 0),
                  color: Colors.green,
                  subtitle: 'Daily revenue',
                ),
                AdminStatCard(
                  icon: Icons.calendar_view_week,
                  title: 'This Week',
                  value: currencyFormat.format(revenue['week'] ?? 0),
                  color: Colors.blue,
                  subtitle: 'Last 7 days',
                ),
                AdminStatCard(
                  icon: Icons.calendar_month,
                  title: 'This Month',
                  value: currencyFormat.format(revenue['month'] ?? 0),
                  color: Colors.orange,
                  subtitle: 'Current month',
                ),
                AdminStatCard(
                  icon: Icons.account_balance_wallet,
                  title: 'Total Revenue',
                  value: currencyFormat.format(revenue['total'] ?? 0),
                  color: Colors.purple,
                  subtitle: 'All time',
                ),
              ],
            ),

          const SizedBox(height: 32),

          // Users Section
          _buildSectionHeader('Users', Icons.people),
          const SizedBox(height: 12),
          if (users != null)
            GridView.count(
              crossAxisCount: context.isTablet ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                AdminStatCard(
                  icon: Icons.people,
                  title: 'Total Users',
                  value: '${users['total'] ?? 0}',
                  color: Colors.indigo,
                  subtitle: 'All users',
                ),
                AdminStatCard(
                  icon: Icons.person_add,
                  title: 'New Today',
                  value: '${users['newToday'] ?? 0}',
                  color: Colors.teal,
                  subtitle: 'Joined today',
                ),
                AdminStatCard(
                  icon: Icons.shopping_bag,
                  title: 'Customers',
                  value: '${users['customers'] ?? 0}',
                  color: Colors.cyan,
                  subtitle: 'Active customers',
                ),
                AdminStatCard(
                  icon: Icons.delivery_dining,
                  title: 'Delivery Partners',
                  value: '${users['delivery'] ?? 0}',
                  color: Colors.deepOrange,
                  subtitle: 'Active partners',
                ),
              ],
            ),

          const SizedBox(height: 32),

          // Restaurants Section
          _buildSectionHeader('Restaurants', Icons.store),
          const SizedBox(height: 12),
          if (restaurants != null)
            GridView.count(
              crossAxisCount: context.isTablet ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                AdminStatCard(
                  icon: Icons.store,
                  title: 'Total Restaurants',
                  value: '${restaurants['total'] ?? 0}',
                  color: Colors.deepPurple,
                  subtitle: 'All restaurants',
                ),
                AdminStatCard(
                  icon: Icons.check_circle,
                  title: 'Active',
                  value: '${restaurants['active'] ?? 0}',
                  color: Colors.green,
                  subtitle: 'Currently open',
                ),
                AdminStatCard(
                  icon: Icons.cancel,
                  title: 'Inactive',
                  value: '${restaurants['inactive'] ?? 0}',
                  color: Colors.red,
                  subtitle: 'Currently closed',
                ),
              ],
            ),

          const SizedBox(height: 32),

          // Orders Section
          _buildSectionHeader('Orders', Icons.receipt_long),
          const SizedBox(height: 12),
          if (orders != null)
            GridView.count(
              crossAxisCount: context.isTablet ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                AdminStatCard(
                  icon: Icons.receipt_long,
                  title: 'Total Orders',
                  value: '${orders['total'] ?? 0}',
                  color: Colors.blueGrey,
                  subtitle: 'All orders',
                ),
                AdminStatCard(
                  icon: Icons.pending,
                  title: 'Pending',
                  value: '${orders['pending'] ?? 0}',
                  color: Colors.orange,
                  subtitle: 'Awaiting acceptance',
                ),
                AdminStatCard(
                  icon: Icons.check_circle_outline,
                  title: 'Delivered',
                  value: '${orders['delivered'] ?? 0}',
                  color: Colors.green,
                  subtitle: 'Successfully completed',
                ),
                AdminStatCard(
                  icon: Icons.cancel_outlined,
                  title: 'Cancelled',
                  value: '${orders['cancelled'] ?? 0}',
                  color: Colors.red,
                  subtitle: 'Cancelled orders',
                ),
              ],
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
