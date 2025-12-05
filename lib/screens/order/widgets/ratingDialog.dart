import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/screens/order/orderLogic.dart';

class RatingDialog extends ConsumerStatefulWidget {
  final String orderId;
  final String restaurantName;
  final String restaurantId;
  final List<OrderItem> orderItems;

  const RatingDialog({
    super.key,
    required this.orderId,
    required this.restaurantName,
    required this.restaurantId,
    required this.orderItems,
  });

  @override
  ConsumerState<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<RatingDialog> {
  int _restaurantRating = 0;
  final TextEditingController _restaurantReviewController =
      TextEditingController();
  final Map<String, int> _itemRatings = {};
  final Map<String, TextEditingController> _itemReviewControllers = {};
  bool _isSubmitting = false;
  int _currentStep = 0; // 0 = restaurant rating, 1 = food ratings

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each food item
    for (var item in widget.orderItems) {
      _itemReviewControllers[item.menuId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _restaurantReviewController.dispose();
    for (var controller in _itemReviewControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_restaurantRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate the restaurant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare item ratings
      List<Map<String, dynamic>>? itemRatings;
      if (_itemRatings.isNotEmpty) {
        itemRatings = _itemRatings.entries.map((entry) {
          final productId = entry.key;
          final rating = entry.value;
          final review = _itemReviewControllers[productId]?.text.trim() ?? '';

          return {
            'itemId': productId,
            'menuItemId': productId,
            'rating': rating,
            'review': review,
          };
        }).toList();
      }

      final result = await ref
          .read(orderControllerProvider.notifier)
          .rateOrder(
            widget.orderId,
            _restaurantRating,
            _restaurantReviewController.text.trim(),
            itemRatings: itemRatings,
          );

      if (mounted) {
        Navigator.of(context).pop();

        // Show success message with rating statistics
        final restaurantStats = result['restaurantStats'];
        final avgRating = restaurantStats?['averageRating'] ?? 0;
        final totalRatings = restaurantStats?['totalRatings'] ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thank you for your feedback!'),
                const SizedBox(height: 4),
                Text(
                  '${widget.restaurantName}: ${avgRating.toStringAsFixed(1)}⭐ ($totalRatings ratings)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStarRating(int currentRating, Function(int) onRatingChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          onPressed: _isSubmitting ? null : () => onRatingChanged(index + 1),
          icon: Icon(
            index < currentRating ? Icons.star : Icons.star_border,
            size: 36,
            color: index < currentRating ? AppColors.primary : Colors.grey,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Order Delivered!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Restaurant Name
              Text(
                'from ${widget.restaurantName}',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Step Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(0, 'Restaurant'),
                  Container(
                    width: 40,
                    height: 2,
                    color: _currentStep > 0
                        ? AppColors.primary
                        : Colors.grey[300],
                  ),
                  _buildStepIndicator(1, 'Food Items'),
                ],
              ),
              const SizedBox(height: 24),

              // Content based on current step
              if (_currentStep == 0) _buildRestaurantRatingStep(),
              if (_currentStep == 1) _buildFoodRatingStep(),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  if (_currentStep == 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Skip'),
                      ),
                    ),
                  if (_currentStep == 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => setState(() => _currentStep = 0),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (_currentStep == 0) {
                                if (_restaurantRating == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please rate the restaurant',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _currentStep = 1);
                              } else {
                                _submitRating();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _currentStep == 0 ? 'Next' : 'Submit',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted
                ? AppColors.primary
                : Colors.grey[300],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primary : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantRatingStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'How was the restaurant?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _buildStarRating(_restaurantRating, (rating) {
          setState(() => _restaurantRating = rating);
        }),
        const SizedBox(height: 16),
        TextField(
          controller: _restaurantReviewController,
          enabled: !_isSubmitting,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Write your review (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodRatingStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Rate your food items',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Optional - Skip if you prefer',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...widget.orderItems.map((item) {
          final productId = item.menuId;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.menuItemImage.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.menuItemImage,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: const Icon(Icons.fastfood),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.menuItemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Qty: ${item.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStarRating(_itemRatings[productId] ?? 0, (rating) {
                    setState(() => _itemRatings[productId] = rating);
                  }),
                  if (_itemRatings[productId] != null &&
                      _itemRatings[productId]! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: _itemReviewControllers[productId],
                        enabled: !_isSubmitting,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Comment (optional)',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
