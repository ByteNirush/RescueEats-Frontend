import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/screens/order/orderLogic.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final OrderModel? order;

  const OrderDetailScreen({super.key, this.orderId, this.order})
    : assert(
        orderId != null || order != null,
        'Either orderId or order must be provided',
      );

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    // If order is passed directly, use it
    if (widget.order != null) {
      return _buildContent(widget.order!);
    }

    // Otherwise fetch from provider
    final ordersAsync = ref.watch(orderControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Order Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (orders) {
          final order = orders.firstWhere(
            (o) => o.id == widget.orderId,
            orElse: () => OrderModel(
              id: '',
              restaurantId: '',
              items: [],
              totalAmount: 0,
              status: 'unknown',
              deliveryAddress: '',
              paymentMethod: '',
              createdAt: DateTime.now(),
            ),
          );

          if (order.id.isEmpty) {
            return const Center(child: Text("Order not found"));
          }

          return _buildBody(order);
        },
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Order Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _buildBody(order),
    );
  }

  Widget _buildBody(OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(order.status).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _getStatusIcon(order.status),
                  size: 48,
                  color: _getStatusColor(order.status),
                ),
                const SizedBox(height: 8),
                Text(
                  order.status.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(order.status),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Order ID: ${order.id}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Restaurant Info
          Text(
            order.restaurantName.isNotEmpty
                ? order.restaurantName
                : "Restaurant",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            DateFormat('MMMM d, y • h:mm a').format(order.createdAt),
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Items
          const Text(
            "Items",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${item.quantity}x",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.menuItemName.isNotEmpty
                          ? item.menuItemName
                          : item.menuId,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    "Rs. ${item.price * item.quantity}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Bill Details
          const Text(
            "Bill Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildBillRow("Subtotal", "Rs. ${order.totalAmount}"),
          if (order.coinDiscount > 0)
            _buildBillRow(
              "Coin Discount",
              "- Rs. ${order.coinDiscount}",
              color: Colors.green,
            ),
          if (order.discountedPrice != null)
            _buildBillRow(
              "Marketplace Discount",
              "- Rs. ${(order.originalPrice! - order.discountedPrice!).toStringAsFixed(2)}",
              color: Colors.green,
            ),
          _buildBillRow("Delivery Fee", "Rs. 0"),
          const Divider(height: 24),
          _buildBillRow(
            "Total",
            "Rs. ${order.discountedPrice ?? (order.totalAmount - order.coinDiscount)}",
            isBold: true,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),

          // Delivery Details
          const Text(
            "Delivery Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          if (order.contactPhone != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.grey),
                const SizedBox(width: 8),
                Text(order.contactPhone!, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
          const SizedBox(height: 32),

          // Actions
          if (order.status == 'pending')
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isCancelling
                    ? null
                    : () => _cancelOrder(context, order.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCancelling
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Text("Cancel Order"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBillRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: Colors.grey[800],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: color ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'preparing':
        return Colors.blue;
      case 'ready':
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.shopping_bag_outlined;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _cancelOrder(BuildContext context, String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isCancelling = true);
      try {
        await ref.read(orderControllerProvider.notifier).cancelOrder(orderId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order cancelled successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to cancel order: $e")));
        }
      } finally {
        if (mounted) {
          setState(() => _isCancelling = false);
        }
      }
    }
  }
}
