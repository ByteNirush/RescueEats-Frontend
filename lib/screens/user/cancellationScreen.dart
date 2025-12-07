import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/services/api_service.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/core/widgets/location_picker_widget.dart';

class CancellationScreen extends ConsumerStatefulWidget {
  const CancellationScreen({super.key});

  @override
  ConsumerState<CancellationScreen> createState() => _CancellationScreenState();
}

class _CancellationScreenState extends ConsumerState<CancellationScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _marketplaceItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMarketplaceItems();
  }

  Future<void> _fetchMarketplaceItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAvailableMarketplaceItems();
      if (response['success'] == true) {
        setState(() {
          _marketplaceItems = List<Map<String, dynamic>>.from(
            response['items'] ?? [],
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load marketplace items';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date.toLocal());
    } catch (e) {
      return dateString;
    }
  }

  String _formatExpiry(String? dateString) {
    if (dateString == null) return 'No expiry';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = date.difference(now);
      if (diff.isNegative) return 'Expired';
      if (diff.inHours < 1) return '${diff.inMinutes} min left';
      if (diff.inHours < 24) return '${diff.inHours} hours left';
      return '${diff.inDays} days left';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _showPurchaseDialog(Map<String, dynamic> item) async {
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    String orderType = 'pickup';
    String paymentMethod = 'cod';
    LatLng? selectedDeliveryLocation;
    int userCoins = 0;
    bool useCoins = false;
    bool isLoadingCoins = true;
    bool isPlacingOrder = false;

    // Pre-fill with restaurant address for pickup
    final restaurantAddress = item['restaurant']?['address'] as String? ?? '';
    if (restaurantAddress.isNotEmpty) {
      addressController.text = restaurantAddress;
    }

    final items = item['items'] as List<dynamic>? ?? [];
    final originalPrice = (item['originalPrice'] as num?)?.toDouble() ?? 0;
    final discountPercent = (item['discountPercent'] as num?)?.toDouble() ?? 0;
    final discountedPrice = (item['discountedPrice'] as num?)?.toDouble() ?? 0;
    final restaurantName = item['restaurant']?['name'] ?? 'Restaurant';

    // Load user coins
    Future<void> loadUserCoins(StateSetter setDialogState) async {
      try {
        final response = await _apiService.getUserStats();
        if (response['success'] == true) {
          setDialogState(() {
            userCoins = response['data']?['coins'] ?? 0;
            isLoadingCoins = false;
          });
        }
      } catch (e) {
        setDialogState(() {
          isLoadingCoins = false;
        });
      }
    }

    const double deliveryCharge = 50.0;

    double getDeliveryCharge() {
      return orderType == 'pickup' ? 0.0 : deliveryCharge;
    }

    double calculateCoinDiscount() {
      if (userCoins < 100) return 0.0;
      return 10.0; // 100 coins = Rs. 10 off
    }

    double calculateTotal() {
      double total = discountedPrice + getDeliveryCharge();
      if (useCoins) {
        total = total - calculateCoinDiscount();
      }
      return total;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Load coins on first build
          if (isLoadingCoins) {
            loadUserCoins(setDialogState);
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header - same style as My Cart
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Rescue Food Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Content - Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item card - same style as cart
                        Card(
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
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        items.isNotEmpty
                                            ? items
                                                  .map(
                                                    (i) =>
                                                        '${i['name']} x${i['qty']}',
                                                  )
                                                  .join(', ')
                                            : 'Food Item',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        restaurantName,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Discount badge and price
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${discountPercent.toStringAsFixed(0)}% OFF',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rs. ${discountedPrice.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Delivery Address or Pickup Location
                        Text(
                          orderType == 'pickup'
                              ? "Pickup Location (Restaurant Address)"
                              : "Delivery Address",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // For pickup: simple text field (read-only)
                        if (orderType == 'pickup')
                          TextField(
                            controller: addressController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: "Restaurant address (auto-filled)",
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.location_on,
                                color: Colors.grey,
                              ),
                              suffixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.grey,
                                size: 18,
                              ),
                            ),
                          ),

                        // For delivery: text field with map picker button
                        if (orderType == 'delivery')
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: addressController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText:
                                        "Enter delivery address or select on map",
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.location_on,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const Divider(height: 1),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LocationPickerWidget(
                                          initialLocation:
                                              selectedDeliveryLocation,
                                          onLocationSelected: (location) {
                                            setDialogState(() {
                                              selectedDeliveryLocation =
                                                  location;
                                              addressController.text =
                                                  'Lat: ${location.latitude.toStringAsFixed(6)}, '
                                                  'Lng: ${location.longitude.toStringAsFixed(6)}';
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.map,
                                          color:
                                              selectedDeliveryLocation != null
                                              ? Colors.green
                                              : AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            selectedDeliveryLocation != null
                                                ? 'Location Selected on Map'
                                                : 'Select Location on Map',
                                            style: TextStyle(
                                              color:
                                                  selectedDeliveryLocation !=
                                                      null
                                                  ? Colors.green
                                                  : AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          selectedDeliveryLocation != null
                                              ? Icons.check_circle
                                              : Icons.arrow_forward_ios,
                                          color:
                                              selectedDeliveryLocation != null
                                              ? Colors.green
                                              : Colors.grey[400],
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
                          controller: phoneController,
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

                        // Order Type Selection (Delivery or Pickup)
                        const Text(
                          "Order Type",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    orderType = 'delivery';
                                    addressController.text = '';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: orderType == 'delivery'
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: orderType == 'delivery'
                                          ? AppColors.primary
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delivery_dining,
                                        color: orderType == 'delivery'
                                            ? Colors.white
                                            : AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Delivery",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: orderType == 'delivery'
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    orderType = 'pickup';
                                    addressController.text = restaurantAddress;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: orderType == 'pickup'
                                        ? Colors.green
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: orderType == 'pickup'
                                          ? Colors.green
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_bag,
                                        color: orderType == 'pickup'
                                            ? Colors.white
                                            : Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Pickup",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: orderType == 'pickup'
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                          value: paymentMethod,
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
                              setDialogState(() => paymentMethod = value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Coin Redemption
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: userCoins >= 100
                                ? Colors.amber.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: userCoins >= 100
                                  ? Colors.amber.shade200
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: userCoins >= 100
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          "Redeem Coins",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (isLoadingCoins)
                                          const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: userCoins >= 100
                                                  ? Colors.green.shade100
                                                  : Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '🪙 $userCoins',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: userCoins >= 100
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userCoins >= 100
                                          ? "Use 100 coins for Rs. 10 off"
                                          : "Minimum 100 coins required (You have $userCoins)",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: userCoins >= 100
                                            ? Colors.grey[600]
                                            : Colors.red.shade600,
                                        fontWeight: userCoins >= 100
                                            ? FontWeight.normal
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: useCoins,
                                onChanged: userCoins >= 100
                                    ? (value) =>
                                          setDialogState(() => useCoins = value)
                                    : null,
                                activeColor: Colors.amber,
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
                                    "Original Price",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    "Rs. ${originalPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Rescue Discount",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    "- Rs. ${(originalPrice - discountedPrice).toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Subtotal",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    "Rs. ${discountedPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Delivery Charge",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      if (orderType == 'pickup') ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            "FREE",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    getDeliveryCharge() == 0
                                        ? "Rs. 0"
                                        : "Rs. ${getDeliveryCharge().toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: getDeliveryCharge() == 0
                                          ? Colors.green
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              if (useCoins) ...[
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
                                      "- Rs. ${calculateCoinDiscount().toStringAsFixed(0)}",
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
                                    "Rs. ${calculateTotal().toStringAsFixed(0)}",
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

                        // Place Order button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isPlacingOrder
                                ? null
                                : () {
                                    if (addressController.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            orderType == 'pickup'
                                                ? "Restaurant address not available. Please try again."
                                                : "Please enter a delivery address",
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    if (phoneController.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Please enter a contact phone number",
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.pop(context);
                                    _purchaseItem(
                                      item['_id'] as String,
                                      addressController.text,
                                      phoneController.text,
                                      orderType,
                                      paymentMethod,
                                      useCoins,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                            ),
                            child: isPlacingOrder
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _purchaseItem(
    String itemId,
    String address,
    String phone,
    String orderType,
    String paymentMethod,
    bool useCoins,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await _apiService.purchaseMarketplaceItem(
        itemId: itemId,
        deliveryAddress: address,
        contactPhone: phone,
        orderType: orderType,
        paymentMethod: paymentMethod,
        useCoins: useCoins,
      );

      // Hide loading
      if (mounted) Navigator.pop(context);

      if (response['success'] == true) {
        if (mounted) {
          // Show success dialog with option to view order
          final orderId = response['order']?['_id'] as String?;

          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 28),
                  const SizedBox(width: 8),
                  const Text('Order Placed!'),
                ],
              ),
              content: const Text(
                'Your rescue food order has been placed successfully. '
                'You can track it in your Orders.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _fetchMarketplaceItems(); // Refresh list
                  },
                  child: const Text('Continue Shopping'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to orders screen - same as normal order flow
                    context.go('/orders');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('View My Orders'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to place order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Rescue Food Deals",
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
            onPressed: _fetchMarketplaceItems,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: context.sizes.iconExtraLarge,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMarketplaceItems,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_marketplaceItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: context.sizes.iconExtraLarge,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              "No rescue deals available",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Check back later for discounted food!",
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMarketplaceItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _marketplaceItems.length,
        itemBuilder: (context, index) {
          final item = _marketplaceItems[index];
          return _buildMarketplaceCard(item);
        },
      ),
    );
  }

  Widget _buildMarketplaceCard(Map<String, dynamic> item) {
    final items = item['items'] as List<dynamic>? ?? [];
    final originalPrice = (item['originalPrice'] as num?)?.toDouble() ?? 0;
    final discountPercent = (item['discountPercent'] as num?)?.toDouble() ?? 0;
    final discountedPrice = (item['discountedPrice'] as num?)?.toDouble() ?? 0;
    final restaurant = item['restaurant'] as Map<String, dynamic>?;
    final expiresAt = item['expiresAt'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with discount badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant?['name'] ?? 'Unknown Restaurant',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (restaurant?['address'] != null)
                        Text(
                          restaurant!['address'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${discountPercent.toStringAsFixed(0)}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items and details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items list
                const Text(
                  'Items:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                ...items.map(
                  (foodItem) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.restaurant,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${foodItem['name']} x${foodItem['qty']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          'Rs. ${(foodItem['price'] as num? ?? 0) * (foodItem['qty'] as num? ?? 1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Price information
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Price',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Rs. ${originalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'You Pay',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Rs. ${discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Expiry info
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      _formatExpiry(expiresAt),
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'You save Rs. ${(originalPrice - discountedPrice).toStringAsFixed(0)}!',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Order button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPurchaseDialog(item),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Order Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
