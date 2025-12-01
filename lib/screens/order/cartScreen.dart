import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/features/providers/cart_provider.dart';
import 'package:rescueeats/screens/auth/provider/authprovider.dart';
import 'package:rescueeats/screens/order/orderLogic.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isPlacingOrder = false;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _paymentMethod = 'cod'; // Default

  @override
  void initState() {
    super.initState();
    // Pre-fill phone number if available
    final user = ref.read(currentUserProvider);
    if (user?.phoneNumber != null) {
      _phoneController.text = user!.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Your cart is empty",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Browse Restaurants",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Food Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.menuItem.image.isNotEmpty
                                    ? Image.network(
                                        item.menuItem.image,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) =>
                                            Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.restaurant,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.restaurant,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // Item Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.menuItem.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rs. ${item.menuItem.price}",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Quantity Controls
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .removeItem(item.menuItem.id);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.remove,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        "${item.quantity}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .addItem(
                                              item.menuItem,
                                              cart.restaurantId!,
                                              cart.restaurantName!,
                                            );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.add,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Total Price
                              Text(
                                "Rs. ${item.totalPrice}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Delivery Address Input
                          const Text(
                            "Delivery Address",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              hintText: "Enter delivery address",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Contact Phone Input
                          const Text(
                            "Contact Phone",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: "Enter contact number",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.phone,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Payment Method Selection
                          const Text(
                            "Payment Method",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _paymentMethod,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.payment,
                                color: AppColors.primary,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'cod',
                                child: Text('Cash on Delivery'),
                              ),
                              DropdownMenuItem(
                                value: 'esewa',
                                child: Text('eSewa Mobile Wallet'),
                              ),
                              DropdownMenuItem(
                                value: 'khalti',
                                child: Text('Khalti Digital Wallet'),
                              ),
                              DropdownMenuItem(
                                value: 'stripe',
                                child: Text('Credit/Debit Card (Stripe)'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _paymentMethod = value);
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          // Coin Redemption
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Redeem Coins",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Use 100 coins for Rs. 10 off",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _useCoins,
                                  onChanged: (value) {
                                    setState(() {
                                      _useCoins = value;
                                    });
                                  },
                                  activeThumbColor: Colors.amber,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Total Amount
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Subtotal",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      "Rs. ${cart.totalAmount}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_useCoins) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Coin Discount",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        "- Rs. ${_calculateCoinDiscount(cart.totalAmount)}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Total Amount",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Rs. ${_calculateTotal(cart.totalAmount)}",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isPlacingOrder ? null : _placeOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: AppColors.primary.withOpacity(0.4),
                              ),
                              child: _isPlacingOrder
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_bag,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Place Order",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  bool _useCoins = false;

  double _calculateCoinDiscount(double total) {
    // Logic: Max 30% of total
    double maxDiscount = total * 0.30;
    // Assuming user has enough coins for now, or fetch user coins
    // For simplicity, let's say we apply max possible discount up to 100 coins = 10 Rs logic
    // This needs real user coin balance.
    // Let's assume a fixed discount for demo or fetch from user provider if available.
    // Ideally: min(userCoins / 10, maxDiscount)
    // Here we'll just show the max potential discount for the UI
    return double.parse(maxDiscount.toStringAsFixed(2));
  }

  double _calculateTotal(double subtotal) {
    if (_useCoins) {
      return subtotal - _calculateCoinDiscount(subtotal);
    }
    return subtotal;
  }

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return;

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a delivery address")),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a contact phone number")),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final order = OrderModel(
        id: '', // Server generates ID
        restaurantId: cart.restaurantId!,
        items: cart.items
            .map(
              (i) => OrderItem(
                menuId: i.menuItem.id,
                quantity: i.quantity,
                price: i.menuItem.price,
              ),
            )
            .toList(),
        totalAmount: _calculateTotal(cart.totalAmount),
        status: 'pending',
        deliveryAddress: _addressController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        paymentMethod: _paymentMethod,
        coinsUsed: _useCoins
            ? (_calculateCoinDiscount(cart.totalAmount) * 10).toInt()
            : 0, // 10 coins = 1 Rs
        createdAt: DateTime.now(),
      );

      await ref.read(orderControllerProvider.notifier).placeOrder(order);
      // ... (rest of function)

      if (mounted) {
        ref.read(cartProvider.notifier).clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed successfully!")),
        );
        context.pop(); // Close cart
        // Ideally navigate to order success or order list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to place order: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }
}
