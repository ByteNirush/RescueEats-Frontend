import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/restaurantModel.dart';
import 'package:rescueeats/core/services/restaurantApiService.dart';

class RestaurantState {
  final RestaurantModel? restaurant;
  final bool isLoading;
  final String? error;

  RestaurantState({this.restaurant, this.isLoading = false, this.error});

  RestaurantState copyWith({
    RestaurantModel? restaurant,
    bool? isLoading,
    String? error,
  }) {
    return RestaurantState(
      restaurant: restaurant ?? this.restaurant,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final restaurantOwnerProvider =
    StateNotifierProvider<RestaurantOwnerNotifier, RestaurantState>((ref) {
      return RestaurantOwnerNotifier();
    });

class RestaurantOwnerNotifier extends StateNotifier<RestaurantState> {
  final RestaurantApiService _apiService = RestaurantApiService();

  RestaurantOwnerNotifier() : super(RestaurantState());

  Future<void> fetchMyRestaurant() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final restaurants = await _apiService.getMyRestaurants();
      if (restaurants.isNotEmpty) {
        state = state.copyWith(restaurant: restaurants.first, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, restaurant: null);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createRestaurant(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final restaurant = await _apiService.createMyRestaurant(data);
      state = state.copyWith(restaurant: restaurant, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void clear() {
    state = RestaurantState();
  }
}
