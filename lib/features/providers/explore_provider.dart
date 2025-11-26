import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/restaurantModel.dart';
import 'package:rescueeats/core/services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final exploreRestaurantsProvider =
    StateNotifierProvider<
      ExploreRestaurantsNotifier,
      AsyncValue<List<RestaurantModel>>
    >((ref) {
      final apiService = ref.watch(apiServiceProvider);
      return ExploreRestaurantsNotifier(apiService);
    });

class ExploreRestaurantsNotifier
    extends StateNotifier<AsyncValue<List<RestaurantModel>>> {
  final ApiService _apiService;

  ExploreRestaurantsNotifier(this._apiService)
    : super(const AsyncValue.loading()) {
    fetchRestaurants();
  }

  Future<void> fetchRestaurants({String? category, String? search}) async {
    try {
      state = const AsyncValue.loading();
      final restaurants = await _apiService.getRestaurants(
        category: category,
        search: search,
      );
      state = AsyncValue.data(restaurants);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
