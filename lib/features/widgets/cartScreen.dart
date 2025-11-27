import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/features/providers/cartNotifier.dart';
import 'package:rescueeats/screens/order/orderLogic.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(context.padding.medium),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Dismissible(
                        key: ValueKey(item.menuItem.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) =>
                            notifier.removeFromCart(item.menuItem.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.menuItem.imageUrl,
                                width: context.isMobile ? 50 : 60,
                                height: context.isMobile ? 50 : 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(item.menuItem.name),
                            // FORMATTED WITH Rs.
                            subtitle: Text(
                              "Rs. ${item.menuItem.price.toStringAsFixed(0)} x ${item.quantity}",
                            ),
                            trailing: Text(
                              "Rs. ${item.totalPrice.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(context.padding.medium),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // FORMATTED TOTAL
                          Text(
                            "Rs. ${notifier.totalAmount.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.spacing.medium),
                      SizedBox(
                        width: double.infinity,
                        height: context.sizes.buttonHeight,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement proper restaurant ID tracking in cart
                            // TODO: Add user input for delivery address
                            // TODO: Add user selection for payment method

                            final order = OrderModel(
                              id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
                              restaurantId: "", // Needs proper implementation
                              deliveryAddress: "Address needed",
                              totalAmount: notifier.totalAmount,
                              items: cartItems
                                  .map(
                                    (e) => OrderItem(
                                      menuId: e.menuItem.id,
                                      quantity: e.quantity,
                                    ),
                                  )
                                  .toList(),
                              status: 'pending',
                              paymentMethod: 'cod',
                              createdAt: DateTime.now(),
                              contactPhone: "", // Needs user input
                            );

                            ref
                                .read(orderControllerProvider.notifier)
                                .placeOrder(order);
                            notifier.clearCart();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Order Placed Successfully!"),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Place Order",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
}
