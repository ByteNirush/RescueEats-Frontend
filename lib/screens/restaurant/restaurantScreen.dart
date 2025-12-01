import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/features/routes/routeconstants.dart';
import 'package:rescueeats/screens/auth/provider/authprovider.dart';
import 'package:rescueeats/screens/order/orderLogic.dart';
import 'package:rescueeats/screens/restaurant/menuScreen.dart';
import 'package:rescueeats/screens/restaurant/provider/restaurant_provider.dart';

class RestaurantDashboard extends ConsumerStatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  ConsumerState<RestaurantDashboard> createState() =>
      _RestaurantDashboardState();
}

class _RestaurantDashboardState extends ConsumerState<RestaurantDashboard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  Timer? _refreshTimer;
  final Set<String> _updatingOrders = {}; // Track orders being updated

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);

    // Fetch restaurant on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(restaurantOwnerProvider.notifier).fetchMyRestaurant();
      // Start auto-refresh for real-time order updates
      _startAutoRefresh();
    });
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
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(orderControllerProvider);
    final restaurantState = ref.watch(restaurantOwnerProvider);

    // If no restaurant, show create restaurant screen
    if (restaurantState.restaurant == null && !restaurantState.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Restaurant Dashboard',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 100, color: Colors.grey[300]),
                const SizedBox(height: 24),
                const Text(
                  'No Restaurant Found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create your restaurant to start receiving orders',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push(RouteConstants.createMyRestaurant);
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Create Your Restaurant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (restaurantState.error != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            restaurantState.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F7FA,
      ), // Light grey background for contrast
      drawer: _buildModernDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Kitchen Display',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () => ref.refresh(orderControllerProvider),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: "New"),
            Tab(text: "Preparing"),
            Tab(text: "Ready"),
          ],
        ),
      ),
      body: asyncOrders.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (orders) => TabBarView(
          controller: _tabController,
          children: [
            _buildOrderList(orders, 'pending'),
            _buildOrderList(orders, 'preparing'),
            _buildOrderList(orders, 'ready'),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDrawer(BuildContext context) {
    final restaurantState = ref.watch(restaurantOwnerProvider);

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  restaurantState.restaurant?.name ?? "My Restaurant",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Restaurant Partner",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDrawerItem(
            Icons.dashboard_outlined,
            "Orders (KDS)",
            () => Navigator.pop(context),
          ),
          _buildDrawerItem(Icons.restaurant_menu, "Manage Menu", () {
            Navigator.pop(context);
            final restaurantId = restaurantState.restaurant?.id;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) =>
                    RestaurantMenuScreen(restaurantId: restaurantId),
              ),
            );
          }),
          _buildDrawerItem(
            Icons.bar_chart,
            "Sales Report",
            () {},
          ), // Placeholder
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

  Widget _buildOrderList(List<OrderModel> allOrders, String status) {
    final orders = allOrders.where((o) => o.status == status).toList();

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No orders in $status",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(context.padding.medium),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildModernKitchenTicket(orders[index]),
    );
  }

  Widget _buildModernKitchenTicket(OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ticket Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 18,
                      color: _getStatusColor(order.status),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "#${order.id.substring(order.id.length - 6).toUpperCase()}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(order.status),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Order Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: order.orderType == 'pickup'
                            ? Colors.purple.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: order.orderType == 'pickup'
                              ? Colors.purple
                              : Colors.blue,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.orderType == 'pickup'
                                ? Icons.shopping_bag
                                : Icons.delivery_dining,
                            size: 12,
                            color: order.orderType == 'pickup'
                                ? Colors.purple
                                : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.orderType == 'pickup' ? 'PICKUP' : 'DELIVERY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: order.orderType == 'pickup'
                                  ? Colors.purple
                                  : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  "${DateTime.now().difference(order.createdAt).inMinutes}m ago",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // Ticket Body
          Padding(
            padding: EdgeInsets.all(context.padding.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Customer Name
                if (order.customerName.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // 2. Order Type & Location
                if (order.orderType == 'pickup') ...[
                  // Pickup Location
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.store, size: 16, color: Colors.purple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '🏬 Pickup Location: Counter #1',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Delivery Address
                  Row(
                    children: [
                      const Icon(
                        Icons.delivery_dining,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),

                // 3. Payment Method
                Row(
                  children: [
                    const Icon(Icons.payment, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _getPaymentMethodLabel(order.paymentMethod),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                // 4. Discount (only if present)
                if (order.coinDiscount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.discount, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Coin Discount: Rs. ${order.coinDiscount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],

                // Contact Phone
                if (order.contactPhone != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.contactPhone!,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                // Items List
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            "${item.quantity}x",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.menuItemName.isNotEmpty
                                    ? item.menuItemName
                                    : "Item",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              // Notes/Customizations could go here
                            ],
                          ),
                        ),
                        Text(
                          "Rs. ${item.price * item.quantity}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Rs. ${(order.totalAmount + order.deliveryCharge - order.coinDiscount).toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        order.status == 'delivered' ||
                            order.status == 'cancelled' ||
                            order.status == 'out_for_delivery' ||
                            _updatingOrders.contains(order.id)
                        ? null
                        : () => _handleOrderStatusUpdate(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getStatusColor(order.status),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _updatingOrders.contains(order.id) ? 0 : 2,
                      shadowColor: _getStatusColor(
                        order.status,
                      ).withOpacity(0.5),
                    ),
                    child: _updatingOrders.contains(order.id)
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getActionIcon(order.status, order.orderType),
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getActionText(order.status, order.orderType),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing': // Changed from cooking
        return Colors.blue;
      case 'ready':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Handle order status update with proper confirmation and feedback
  Future<void> _handleOrderStatusUpdate(OrderModel order) async {
    String nextStatus = 'pending';
    String confirmTitle = '';
    String confirmMessage = '';
    bool needsConfirmation = false;

    // Determine next status and confirmation requirements
    if (order.status == 'pending') {
      nextStatus = 'preparing';
      confirmTitle = 'Start Cooking?';
      confirmMessage = 'Begin preparing this order now?';
    } else if (order.status == 'preparing') {
      nextStatus = 'ready';
      confirmTitle = 'Mark as Ready?';
      confirmMessage =
          'Is the order ready for ${order.orderType == 'pickup' ? 'customer pickup' : 'delivery'}?';
    } else if (order.status == 'ready') {
      needsConfirmation = true; // Always confirm final handover
      if (order.orderType == 'pickup') {
        nextStatus = 'delivered';
        confirmTitle = 'Complete Pickup?';
        confirmMessage = 'Confirm that the customer has picked up this order?';
      } else {
        nextStatus = 'out_for_delivery';
        confirmTitle = 'Handover to Driver?';
        confirmMessage =
            'Confirm that the order has been handed over to the delivery driver?';
      }
    }

    // Show confirmation dialog for critical actions
    if (needsConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: _getStatusColor('ready')),
              const SizedBox(width: 12),
              Text(confirmTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(confirmMessage),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(order.id.length - 6).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.customerName.isNotEmpty
                          ? order.customerName
                          : 'Customer',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor('ready'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return; // User cancelled
    }

    // Mark as updating
    setState(() {
      _updatingOrders.add(order.id);
    });

    try {
      await ref
          .read(orderControllerProvider.notifier)
          .updateStatus(order.id, nextStatus);

      if (mounted) {
        setState(() {
          _updatingOrders.remove(order.id);
        });

        // Success message with icon
        String message = '';
        IconData icon = Icons.check_circle;

        if (nextStatus == 'delivered') {
          message = '✅ Order completed - Customer picked up!';
          icon = Icons.emoji_events;
        } else if (nextStatus == 'out_for_delivery') {
          message = '🚚 Order handed over to delivery driver!';
          icon = Icons.delivery_dining;
        } else if (nextStatus == 'ready') {
          message =
              '🔔 Order is ready for ${order.orderType == 'pickup' ? 'pickup' : 'delivery'}!';
          icon = Icons.notifications_active;
        } else {
          message = '👨‍🍳 Order moved to ${_getStatusDisplayName(nextStatus)}';
          icon = Icons.restaurant;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _updatingOrders.remove(order.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to update order: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleOrderStatusUpdate(order),
            ),
          ),
        );
      }
    }
  }

  IconData _getActionIcon(String status, String orderType) {
    switch (status) {
      case 'pending':
        return Icons.play_arrow;
      case 'preparing':
        return Icons.check;
      case 'ready':
        return orderType == 'pickup'
            ? Icons.shopping_bag
            : Icons.local_shipping;
      default:
        return Icons.done;
    }
  }

  String _getActionText(String status, String orderType) {
    switch (status) {
      case 'pending':
        return "Start Cooking";
      case 'preparing':
        return "Mark Ready";
      case 'ready':
        // Different button text based on order type
        return orderType == 'pickup' ? "Complete Pickup" : "Handover to Driver";
      default:
        return "Close";
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cod':
        return 'Cash on Delivery';
      case 'khalti':
        return 'Khalti';
      case 'esewa':
        return 'eSewa';
      case 'stripe':
        return 'Stripe';
      default:
        return method.toUpperCase();
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'handed_over':
        return 'Handed Over';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'New Order - Ready to Cook';
      case 'preparing':
        return 'Currently Cooking';
      case 'ready':
        return 'Ready for Delivery';
      default:
        return status.toUpperCase();
    }
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
