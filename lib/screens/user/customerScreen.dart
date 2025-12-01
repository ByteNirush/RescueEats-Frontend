import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/screens/order/orderLogic.dart';
import 'package:rescueeats/screens/order/widgets/ratingDialog.dart';
import 'package:rescueeats/screens/user/customerHomeTab.dart';
import 'package:rescueeats/screens/user/profileScreen.dart';
import 'package:rescueeats/screens/user/cancellationScreen.dart';
import 'package:rescueeats/screens/user/gameScreen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CustomerHomeTab(),
    const CancellationScreen(),
    const GameScreen(),
    const CustomerOrdersTab(),
    const CustomerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.1), // Orange tint
          elevation: 0,
          height: 65,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(
                Icons.explore,
                color: AppColors.primary,
              ), // Orange
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.cancel_presentation_outlined),
              selectedIcon: Icon(
                Icons.cancel_presentation,
                color: AppColors.primary,
              ),
              label: 'Cancel',
            ),
            NavigationDestination(
              icon: Icon(Icons.games_outlined),
              selectedIcon: Icon(Icons.games, color: AppColors.primary),
              label: 'Game',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(
                Icons.receipt_long,
                color: AppColors.primary,
              ), // Orange
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(
                Icons.person,
                color: AppColors.primary,
              ), // Orange
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// --- TAB 2: ORDERS SCREEN ---
class CustomerOrdersTab extends ConsumerStatefulWidget {
  const CustomerOrdersTab({super.key});

  @override
  ConsumerState<CustomerOrdersTab> createState() => _CustomerOrdersTabState();
}

class _CustomerOrdersTabState extends ConsumerState<CustomerOrdersTab>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start auto-refresh for real-time order tracking
    _startAutoRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Stop refresh when app is paused/inactive, resume when active
    if (state == AppLifecycleState.resumed) {
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopAutoRefresh();
    }
  }

  void _startAutoRefresh() {
    // Cancel existing timer to prevent multiple timers
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        ref.read(orderControllerProvider.notifier).fetchOrders();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(orderControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Orders",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () => ref.refresh(orderControllerProvider),
          ),
        ],
      ),
      body: asyncOrders.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ), // Orange Loader
        error: (error, stack) => Center(child: Text("Error loading orders")),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No past orders",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final sortedOrders = List<OrderModel>.from(orders)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.separated(
            padding: EdgeInsets.all(context.padding.medium),
            itemCount: sortedOrders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final order = sortedOrders[index];
              return _buildMinimalOrderRow(context, ref, order);
            },
          );
        },
      ),
    );
  }

  Widget _buildMinimalOrderRow(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    final isCancelable = order.status.toLowerCase() == 'pending';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Restaurant Image, Name & Price
            Row(
              children: [
                // Restaurant Image
                if (order.restaurantImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order.restaurantImage,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.restaurant, color: Colors.grey[400]),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.restaurant, color: Colors.grey[400]),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurantName.isNotEmpty
                            ? order.restaurantName
                            : "Restaurant",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Rs. ${(order.totalAmount + order.deliveryCharge - order.coinDiscount).toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status Badge
            _buildEnhancedStatus(order.status),

            // Rating prompt for delivered orders
            if (order.status == 'delivered' && order.rating == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'How was your order?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => RatingDialog(
                            orderId: order.id,
                            restaurantName: order.restaurantName,
                          ),
                        );
                      },
                      child: const Text(
                        'Rate Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Show rating if already rated
            if (order.rating != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < order.rating! ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      'You rated ${order.rating}/5',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Items
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.items
                          .map(
                            (e) =>
                                "${e.quantity}x ${e.menuItemName.isNotEmpty ? e.menuItemName : 'Item'}",
                          )
                          .join(" • "),
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                if (isCancelable) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await ref
                              .read(orderControllerProvider.notifier)
                              .cancelOrder(order.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Order cancelled")),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to cancel: $e")),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text("Cancel"),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text("Track"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatus(String status) {
    Color color;
    Color bgColor;
    IconData icon;
    String text = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange.shade700;
        bgColor = Colors.orange.shade50;
        icon = Icons.schedule;
        break;
      case 'preparing':
        color = Colors.blue.shade700;
        bgColor = Colors.blue.shade50;
        icon = Icons.restaurant_menu;
        break;
      case 'ready':
        color = Colors.purple.shade700;
        bgColor = Colors.purple.shade50;
        icon = Icons.check_circle_outline;
        break;
      case 'out_for_delivery':
        color = Colors.indigo.shade700;
        bgColor = Colors.indigo.shade50;
        icon = Icons.delivery_dining;
        text = 'OUT FOR DELIVERY';
        break;
      case 'delivered':
        color = Colors.green.shade700;
        bgColor = Colors.green.shade50;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey.shade700;
        bgColor = Colors.grey.shade50;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
