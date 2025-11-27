import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/menuItemModel.dart';
import 'package:rescueeats/core/services/restaurantApiService.dart';

final menuProvider =
    StateNotifierProvider<MenuNotifier, AsyncValue<List<MenuItemModel>>>((ref) {
      return MenuNotifier(ref);
    });

class MenuNotifier extends StateNotifier<AsyncValue<List<MenuItemModel>>> {
  final Ref ref;
  final RestaurantApiService _apiService = RestaurantApiService();

  MenuNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> fetchMenu(String restaurantId) async {
    try {
      state = const AsyncValue.loading();
      final restaurant = await _apiService.getRestaurantDetails(restaurantId);
      // Assuming restaurant model has a menu field which is a list of MenuItemModel
      // We might need to fetch menu separately if it's not in details, but based on routes it seems separate or included.
      // Checking backend controller: getRestaurantMenu returns { menu: ... }
      // But getRestaurantById also returns restaurant object.
      // Let's use getRestaurantMenu for specific menu fetching if needed, or just use the restaurant details.
      // For now, let's assume we can get it from restaurant details or a specific menu endpoint.
      // Actually, let's use the getRestaurantMenu endpoint if available or just parse from details.
      // The backend route `GET /:id/menu` calls `getRestaurantMenu`.
      // But `RestaurantApiService` doesn't have `getMenu` yet, only `getRestaurantDetails`.
      // Let's use `getRestaurantDetails` as it returns the full object including menu.

      // Wait, RestaurantModel needs to have `menu` field.
      // Let's check RestaurantModel again.
      // It has `cuisineType`, but I don't see `menu` list in `RestaurantModel` definition I viewed earlier.
      // I need to update RestaurantModel to include `menu`.

      // For now, let's just fetch details and see.
      // Actually, I should update RestaurantModel first.

      state = AsyncValue.data(restaurant.menu);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMenuItem(
    String restaurantId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _apiService.addMenuItem(restaurantId, data);
      // Refresh menu
      await fetchMenu(restaurantId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMenuItem(
    String restaurantId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _apiService.updateMenuItem(restaurantId, itemId, data);
      // Refresh menu
      await fetchMenu(restaurantId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String restaurantId, String itemId) async {
    try {
      await _apiService.deleteMenuItem(restaurantId, itemId);
      // Refresh menu
      await fetchMenu(restaurantId);
    } catch (e) {
      rethrow;
    }
  }
}
