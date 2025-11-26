import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/screens/order/orderLogic.dart';
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
class CustomerOrdersTab extends ConsumerWidget {
  const CustomerOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Restaurant & Price
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                order.restaurantName.isNotEmpty
                    ? order.restaurantName
                    : "Restaurant", // Fallback
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              "Rs. ${order.totalAmount.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ), // Orange Price
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Date & Status
        Row(
          children: [
            Text(
              _formatDate(order.createdAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            _buildSimpleStatus(order.status),
          ],
        ),

        const SizedBox(height: 12),

        // Items
        Text(
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

        const SizedBox(height: 16),

        // Action Buttons
        Row(
          children: [
            if (isCancelable) ...[
              Expanded(
                child: OutlinedButton(
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
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Orange Background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Track",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: Colors.grey[100]),
      ],
    );
  }

  Widget _buildSimpleStatus(String status) {
    Color color;
    String text = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'preparing':
        color = Colors.blue;
        break;
      case 'ready':
        color = Colors.purple;
        break;
      case 'out_for_delivery':
        color = Colors.indigo;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
