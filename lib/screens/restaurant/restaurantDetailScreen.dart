import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/model/menuItemModel.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/features/providers/cart_provider.dart';
import 'package:rescueeats/features/providers/restaurant_detail_provider.dart';
import 'package:rescueeats/screens/order/cartScreen.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final String? restaurantName;
  final String? imageUrl;
  final String? heroTag;
  final bool isOpen;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
    this.restaurantName,
    this.imageUrl,
    this.heroTag,
    this.isOpen = true,
  });

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncMenu = ref.watch(restaurantMenuProvider(widget.restaurantId));
    final cart = ref.watch(cartProvider);
    // We can also fetch full restaurant details if needed, but we have basic info
    // final asyncRestaurant = ref.watch(restaurantDetailsProvider(widget.restaurantId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Header Image (Standard Hero)
          SliverAppBar(
            expandedHeight: context.isMobile ? 200.0 : 250.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.heroTag ?? widget.restaurantId,
                child: Image.network(
                  widget.imageUrl ??
                      "https://via.placeholder.com/800x400/FF6B35/FFFFFF?text=Restaurant",
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: Colors.grey[300]),
                ),
              ),
            ),
          ),

          // 2. Restaurant Info (Distinct Card Style)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(context.padding.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.restaurantName ?? "Restaurant",
                    style: TextStyle(
                      fontSize: context.text.h1,
                      fontWeight:
                          FontWeight.w900, // Heavier font for distinct look
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!widget.isOpen)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Restaurant is currently closed",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Text(
                        "Fast Food", // Placeholder or fetch from details
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.circle,
                          size: 4,
                          color: Colors.grey[300],
                        ),
                      ),
                      Text(
                        "Burger", // Placeholder
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      const Text(
                        "4.5", // Placeholder
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        " (500+)",
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Distinct Info Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB), // Very subtle grey
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn(Icons.access_time, "20-30", "min"),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        _buildInfoColumn(
                          Icons.delivery_dining,
                          "Rs. 50",
                          "Delivery",
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        _buildInfoColumn(
                          Icons.local_offer,
                          "Rs. 100",
                          "Min Off",
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.spacing.section),
                  Text(
                    "Menu",
                    style: TextStyle(
                      fontSize: context.text.h3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Menu Items (Text Only, No Images)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: context.padding.medium),
            sliver: asyncMenu.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(child: Text("Error loading menu: $err")),
              ),
              data: (menuItems) {
                if (menuItems.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text("No menu items available"),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildTextOnlyMenuItem(menuItems[index]);
                  }, childCount: menuItems.length),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // 4. Floating Cart Button
      floatingActionButton: cart.items.isEmpty
          ? null
          : Container(
              width: context.widthPercent(90),
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
                backgroundColor: AppColors.primary,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${cart.totalItems} Items",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "View Cart",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Rs. ${cart.totalAmount}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoColumn(IconData icon, String top, String bottom) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          top,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          bottom,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextOnlyMenuItem(MenuItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text Content Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Rs. ${item.price}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Minimal Add Button
          Center(
            child: InkWell(
              onTap: widget.isOpen
                  ? () {
                      ref
                          .read(cartProvider.notifier)
                          .addItem(
                            item,
                            widget.restaurantId,
                            widget.restaurantName ?? "Restaurant",
                          );
                    }
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.isOpen
                        ? Colors.grey[300]!
                        : Colors.grey[200]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: widget.isOpen ? null : Colors.grey[100],
                ),
                child: Text(
                  widget.isOpen ? "ADD" : "CLOSED",
                  style: TextStyle(
                    color: widget.isOpen ? AppColors.primary : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
