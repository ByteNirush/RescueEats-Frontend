import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/menuItemModel.dart';
import 'package:rescueeats/core/services/api_service.dart';
import 'package:rescueeats/core/error/app_exception.dart';

// Menu state
class MenuState {
  final List<MenuItemModel> items;
  final bool isLoading;
  final String? error;

  const MenuState({this.items = const [], this.isLoading = false, this.error});

  MenuState copyWith({
    List<MenuItemModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return MenuState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Menu notifier
class MenuNotifier extends StateNotifier<MenuState> {
  final ApiService _apiService;
  String? _currentRestaurantId;

  MenuNotifier(this._apiService) : super(const MenuState());

  /// Fetch menu items for a restaurant
  Future<void> fetchMenu(String restaurantId) async {
    _currentRestaurantId = restaurantId;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final items = await _apiService.getRestaurantMenu(restaurantId);
      state = state.copyWith(items: items, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load menu: ${e.toString()}',
      );
    }
  }

  /// Add a new menu item
  Future<bool> addMenuItem({
    required String restaurantId,
    required String name,
    required double price,
    required String description,
    required String image,
  }) async {
    try {
      final newItem = await _apiService.addMenuItem(
        restaurantId: restaurantId,
        name: name,
        price: price,
        description: description,
        image: image,
      );

      // Add to local state
      state = state.copyWith(items: [...state.items, newItem]);

      return true;
    } on AppException catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to add item: ${e.toString()}');
      return false;
    }
  }

  /// Refresh menu (re-fetch from API)
  Future<void> refresh() async {
    if (_currentRestaurantId != null) {
      await fetchMenu(_currentRestaurantId!);
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  return MenuNotifier(ApiService());
});
