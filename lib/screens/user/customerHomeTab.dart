import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/features/providers/explore_provider.dart';
import 'package:rescueeats/screens/restaurant/restaurantDetailScreen.dart';

class CustomerHomeTab extends ConsumerWidget {
  const CustomerHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    String greeting = "Good Morning";
    if (hour > 12) greeting = "Good Afternoon";
    if (hour > 17) greeting = "Good Evening";

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            floating: true,
            pinned: true,
            elevation: 0,
            expandedHeight: 110,
            toolbarHeight: 60,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: context.text.bodySmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.primary,
                    ), // Orange
                    const SizedBox(width: 4),
                    Text(
                      "Lazimpat, Kathmandu",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: context.text.bodyMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: Colors.black,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
                onPressed: () {
                  // Notifications feature to be implemented
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.padding.horizontal,
                  0,
                  context.padding.horizontal,
                  context.spacing.small,
                ),
                child: Container(
                  height: context.isMobile ? 48 : 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search 'Momo', 'Pizza'...",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: context.text.bodyMedium,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.spacing.medium),
                // Categories
                SizedBox(
                  height: context.isMobile ? 110 : 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.padding.horizontal,
                    ),
                    children: [
                      _buildSquareCategory(
                        context,
                        "Offers",
                        "50% Off",
                        Icons.local_offer,
                        Colors.red,
                      ),
                      _buildSquareCategory(
                        context,
                        "Momo",
                        "Hot",
                        Icons.rice_bowl,
                        AppColors.primary,
                      ), // Orange
                      _buildSquareCategory(
                        context,
                        "Burger",
                        "Juicy",
                        Icons.lunch_dining,
                        Colors.brown,
                      ),
                      _buildSquareCategory(
                        context,
                        "Pizza",
                        "Cheesy",
                        Icons.local_pizza,
                        Colors.blue,
                      ),
                      _buildSquareCategory(
                        context,
                        "Healthy",
                        "Fresh",
                        Icons.eco,
                        Colors.green,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.spacing.section),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.padding.horizontal,
                  ),
                  child: Text(
                    "Special Offers",
                    style: TextStyle(
                      fontSize: context.text.h3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: context.spacing.medium),
                SizedBox(
                  height: context.isMobile ? 180 : 200,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.padding.horizontal,
                    ),
                    children: [
                      _buildMagazinePromo(
                        context: context,
                        title: "Momo\nMadness",
                        subtitle: "Flat Rs. 100 Off",
                        color: AppColors.primary, // Orange
                        image:
                            "https://via.placeholder.com/400x180/FF6B35/FFFFFF?text=Momo+Special",
                      ),
                      const SizedBox(width: 16),
                      _buildMagazinePromo(
                        context: context,
                        title: "Free\nDelivery",
                        subtitle: "All Weekend",
                        color: const Color(0xFF1E3A5F),
                        image:
                            "https://via.placeholder.com/400x180/1E3A5F/FFFFFF?text=Free+Delivery",
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.spacing.section),
                _buildSectionHeader(context, "Curated For You", "View All"),
                SizedBox(height: context.spacing.medium),
                SizedBox(
                  height: context.isMobile ? 200 : 220,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.padding.horizontal,
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildPortraitCollection(
                        context,
                        "Budget Eats",
                        "Under Rs. 300",
                        "https://via.placeholder.com/150x200/4CAF50/FFFFFF?text=Budget",
                      ),
                      const SizedBox(width: 16),
                      _buildPortraitCollection(
                        context,
                        "Top Rated",
                        "4.5+ Stars",
                        "https://via.placeholder.com/150x200/FFC107/FFFFFF?text=Top+Rated",
                      ),
                      const SizedBox(width: 16),
                      _buildPortraitCollection(
                        context,
                        "New & Hot",
                        "Try now",
                        "https://via.placeholder.com/150x200/F44336/FFFFFF?text=New",
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.spacing.section),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.padding.horizontal,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "All Restaurants",
                        style: TextStyle(
                          fontSize: context.text.h3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "142 near you",
                          style: TextStyle(
                            color: AppColors.primary, // Orange Text
                            fontSize: context.text.bodySmall,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.spacing.medium),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: context.padding.horizontal,
            ),
            sliver: Consumer(
              builder: (context, ref, child) {
                final asyncRestaurants = ref.watch(exploreRestaurantsProvider);

                return asyncRestaurants.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  error: (error, stack) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Error: $error'),
                      ),
                    ),
                  ),
                  data: (restaurants) {
                    if (restaurants.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('No restaurants found'),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final restaurant = restaurants[index];
                        return _buildDistinctRestaurantCard(
                          context,
                          id: restaurant.id,
                          name: restaurant.name,
                          tags: restaurant.cuisineType.join(" • "),
                          rating: restaurant.averageRating > 0 
                              ? restaurant.averageRating.toStringAsFixed(1)
                              : restaurant.rating.toStringAsFixed(1),
                          totalRatings: restaurant.totalRatings,
                          time: "${restaurant.deliveryTime} min",
                          deliveryFee: "Rs. ${restaurant.deliveryFee}",
                          imageUrl: restaurant.image,
                          isOpen: restaurant.isOpen,
                        );
                      }, childCount: restaurants.length),
                    );
                  },
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String action,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.padding.horizontal),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.text.h3,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            action,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ), // Orange Action
        ],
      ),
    );
  }

  Widget _buildSquareCategory(
    BuildContext context,
    String name,
    String sub,
    IconData icon,
    Color color,
  ) {
    final size = context.sizes.categoryCardSize;
    return Padding(
      padding: EdgeInsets.only(right: context.spacing.medium),
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: context.isMobile ? 28 : 32),
          ),
          SizedBox(height: context.spacing.small),
          Text(
            name,
            style: TextStyle(
              fontSize: context.text.bodySmall,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagazinePromo({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Color color,
    required String image,
  }) {
    return Container(
      width: context.sizes.promoCardWidth,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: color),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [color.withOpacity(0.9), color.withOpacity(0.2)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "PROMO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitCollection(
    BuildContext context,
    String title,
    String subtitle,
    String imageUrl,
  ) {
    return Container(
      width: context.sizes.collectionCardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          onError: (e, s) {},
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistinctRestaurantCard(
    BuildContext context, {
    required String id,
    required String name,
    required String tags,
    required String rating,
    required int totalRatings,
    required String time,
    required String deliveryFee,
    required String imageUrl,
    required bool isOpen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailScreen(
              restaurantId: id,
              restaurantName: name,
              imageUrl: imageUrl,
              heroTag: "res_$id",
              isOpen: isOpen,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: "res_$id",
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ColorFiltered(
                      colorFilter: isOpen
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            )
                          : ColorFilter.mode(
                              Colors.grey.withOpacity(0.8),
                              BlendMode.saturation,
                            ),
                      child: Image.network(
                        imageUrl,
                        height: context.sizes.cardImageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          height: context.sizes.cardImageHeight,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      isOpen ? "OPEN" : "CLOSED",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.text.h3,
                      fontWeight: FontWeight.w800,
                      color: isOpen ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text(
                        rating,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.star, size: 10, color: Colors.white),
                      if (totalRatings > 0) ...[
                        const SizedBox(width: 2),
                        Text(
                          '($totalRatings)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacing.small),
            Text(
              tags,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: context.text.bodyMedium,
              ),
            ),
            SizedBox(height: context.spacing.small),
            Row(
              children: [
                _buildTagChip(deliveryFee, Icons.delivery_dining, Colors.blue),
                const SizedBox(width: 8),
                _buildTagChip(
                  "Min Rs. 100 off",
                  Icons.local_offer,
                  AppColors.primary,
                ), // Orange Tag
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
