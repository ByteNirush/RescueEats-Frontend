import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/restaurantModel.dart';
import 'package:rescueeats/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing restaurant owner's restaurant data
final restaurantOwnerProvider =
    StateNotifierProvider<RestaurantOwnerNotifier, RestaurantOwnerState>((ref) {
      return RestaurantOwnerNotifier();
    });

/// State for restaurant owner
class RestaurantOwnerState {
  final RestaurantModel? restaurant;
  final List<RestaurantModel> allRestaurants;
  final bool isLoading;
  final String? error;

  RestaurantOwnerState({
    this.restaurant,
    this.allRestaurants = const [],
    this.isLoading = false,
    this.error,
  });

  RestaurantOwnerState copyWith({
    RestaurantModel? restaurant,
    List<RestaurantModel>? allRestaurants,
    bool? isLoading,
    String? error,
  }) {
    return RestaurantOwnerState(
      restaurant: restaurant ?? this.restaurant,
      allRestaurants: allRestaurants ?? this.allRestaurants,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing restaurant owner's restaurant
class RestaurantOwnerNotifier extends StateNotifier<RestaurantOwnerState> {
  RestaurantOwnerNotifier() : super(RestaurantOwnerState()) {
    _loadFromCache();
  }

  final _apiService = ApiService();

  /// Load restaurant ID from cache on init
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final restaurantId = prefs.getString('my_restaurant_id');
      if (restaurantId != null && restaurantId.isNotEmpty) {
        // Fetch restaurant details
        final restaurant = await _apiService.getRestaurantById(restaurantId);
        state = state.copyWith(restaurant: restaurant);
      }
    } catch (e) {
      // Silently fail - will fetch from API on demand
    }
  }

  /// Fetch restaurants owned by current user
  Future<void> fetchMyRestaurant() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final restaurants = await _apiService.getMyRestaurants();

      if (restaurants.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'No restaurant found. Please contact admin to create one.',
        );
        return;
      }

      // If user has multiple restaurants, use first one (can be enhanced later)
      final restaurant = restaurants.first;

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('my_restaurant_id', restaurant.id);

      state = state.copyWith(
        restaurant: restaurant,
        allRestaurants: restaurants,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch restaurant: ${e.toString()}',
      );
    }
  }

  /// Select a specific restaurant (for users with multiple restaurants)
  Future<void> selectRestaurant(String restaurantId) async {
    final restaurant = state.allRestaurants.firstWhere(
      (r) => r.id == restaurantId,
      orElse: () => state.allRestaurants.first,
    );

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_restaurant_id', restaurant.id);

    state = state.copyWith(restaurant: restaurant);
  }

  /// Clear restaurant data (on logout)
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('my_restaurant_id');
    state = RestaurantOwnerState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
