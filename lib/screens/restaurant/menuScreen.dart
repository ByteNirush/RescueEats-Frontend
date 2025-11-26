import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/features/routes/routeconstants.dart';
import 'package:rescueeats/screens/restaurant/provider/menuProvider.dart';
import 'package:rescueeats/screens/restaurant/provider/restaurant_provider.dart';

class RestaurantMenuScreen extends ConsumerStatefulWidget {
  final String? restaurantId; // Pass restaurant ID from parent

  const RestaurantMenuScreen({super.key, this.restaurantId});

  @override
  ConsumerState<RestaurantMenuScreen> createState() =>
      _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends ConsumerState<RestaurantMenuScreen> {
  String? _restaurantId;

  @override
  void initState() {
    super.initState();
    // Use provided restaurantId or get from provider
    _restaurantId = widget.restaurantId;

    // Fetch menu on init if we have restaurant ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If no restaurant ID provided, try to get from provider
      if (_restaurantId == null) {
        final restaurantState = ref.read(restaurantOwnerProvider);
        _restaurantId = restaurantState.restaurant?.id;
      }

      if (_restaurantId != null) {
        ref.read(menuProvider.notifier).fetchMenu(_restaurantId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);

    // If no restaurant ID provided, try to get from user or show error
    if (_restaurantId == null) {
      // For now, show a message to set restaurant ID
      // In production, you'd get this from the user's restaurant profile
      return Scaffold(
        appBar: AppBar(
          title: const Text("Manage Menu"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Restaurant not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please create your restaurant first',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to create restaurant screen
                  context.push(RouteConstants.createMyRestaurant);
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Create Restaurant',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Try to fetch restaurant again
                  ref
                      .read(restaurantOwnerProvider.notifier)
                      .fetchMyRestaurant();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Menu"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(menuProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: menuState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : menuState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${menuState.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(menuProvider.notifier).clearError();
                      ref.read(menuProvider.notifier).refresh();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : menuState.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No menu items yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first item',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(menuProvider.notifier).refresh(),
              child: ListView.builder(
                padding: EdgeInsets.all(context.padding.medium),
                itemCount: menuState.items.length,
                itemBuilder: (context, index) {
                  final item = menuState.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: Container(
                        width: context.isMobile ? 60 : 70,
                        height: context.isMobile ? 60 : 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                          image: item.image.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(item.image),
                                  fit: BoxFit.cover,
                                  onError: (e, s) {},
                                )
                              : null,
                        ),
                        child: item.image.isEmpty
                            ? const Icon(Icons.restaurant, color: Colors.grey)
                            : null,
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rs. ${item.price.toStringAsFixed(0)} • ${item.isAvailable ? 'Available' : 'Sold Out'}",
                          ),
                          if (item.category.isNotEmpty)
                            Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          if (item.discount != null && item.discount! > 0)
                            Text(
                              '${item.discount}% OFF',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.isVeg)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.green,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.green,
                              ),
                            ),
                          Icon(
                            item.isAvailable
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: item.isAvailable ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFoodDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text("Add Item"),
      ),
    );
  }

  void _showAddFoodDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _AddFoodItemScreen(restaurantId: _restaurantId!),
      ),
    );
  }
}

class _AddFoodItemScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const _AddFoodItemScreen({required this.restaurantId});

  @override
  ConsumerState<_AddFoodItemScreen> createState() => _AddFoodItemScreenState();
}

class _AddFoodItemScreenState extends ConsumerState<_AddFoodItemScreen> {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final imageUrlCtrl = TextEditingController();
  bool _isSubmitting = false;

  void _addFoodItem() async {
    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await ref
        .read(menuProvider.notifier)
        .addMenuItem(
          restaurantId: widget.restaurantId,
          name: nameCtrl.text,
          price: double.tryParse(priceCtrl.text) ?? 0.0,
          description: descCtrl.text,
          image: imageUrlCtrl.text.isEmpty
              ? 'https://via.placeholder.com/200x200/FF6B35/FFFFFF?text=${Uri.encodeComponent(nameCtrl.text)}'
              : imageUrlCtrl.text,
        );

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu item added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        final error = ref.read(menuProvider).error ?? 'Failed to add item';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    descCtrl.dispose();
    imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Food Item"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item Name
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Item Name *",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.restaurant_menu),
              ),
            ),
            const SizedBox(height: 16),

            // Price
            TextField(
              controller: priceCtrl,
              decoration: InputDecoration(
                labelText: "Price (Rs.) *",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Image URL
            TextField(
              controller: imageUrlCtrl,
              decoration: InputDecoration(
                labelText: "Image URL (optional)",
                hintText: "https://example.com/image.jpg",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Leave empty to use a placeholder image',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Add Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _addFoodItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      "Add to Menu",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
