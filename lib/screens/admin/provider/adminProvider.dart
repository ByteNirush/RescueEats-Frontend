import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/core/model/restaurantModel.dart';
import 'package:rescueeats/core/model/userModel.dart';
import 'package:rescueeats/core/services/adminApiService.dart';

// Admin API Service provider
final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  return AdminApiService();
});

// ============ User Management Providers ============

final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final apiService = ref.watch(adminApiServiceProvider);
  return await apiService.getAllUsers();
});

final userByIdProvider = FutureProvider.family<UserModel, String>((
  ref,
  id,
) async {
  final apiService = ref.watch(adminApiServiceProvider);
  return await apiService.getUserById(id);
});

// ============ Restaurant Management Providers ============

final allRestaurantsProvider = FutureProvider<List<RestaurantModel>>((
  ref,
) async {
  final apiService = ref.watch(adminApiServiceProvider);
  return await apiService.getAllRestaurants();
});

// ============ Order Management Providers ============

final allOrdersProvider = FutureProvider.family<List<OrderModel>, String?>((
  ref,
  status,
) async {
  final apiService = ref.watch(adminApiServiceProvider);
  return await apiService.getAllOrders(status: status);
});

final orderByIdProvider = FutureProvider.family<OrderModel, String>((
  ref,
  id,
) async {
  final apiService = ref.watch(adminApiServiceProvider);
  return await apiService.getOrderById(id);
});

// ============ Analytics Providers ============

final analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(adminApiServiceProvider);
  return await apiService.getAnalytics();
});

final revenueStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(adminApiServiceProvider);
  return await apiService.getRevenueStats();
});

final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(adminApiServiceProvider);
  return await apiService.getUserStats();
});

final restaurantOwnersProvider = FutureProvider<List<UserModel>>((ref) async {
  final apiService = ref.watch(adminApiServiceProvider);
  return await apiService.getUsersByRole(UserRole.restaurant);
});

final restaurantStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final apiService = ref.watch(adminApiServiceProvider);
  return await apiService.getRestaurantStats();
});

// ============ Admin Controller ============

class AdminController extends StateNotifier<AsyncValue<void>> {
  final AdminApiService _apiService;
  final Ref _ref;

  AdminController(this._apiService, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> updateUserRole(String userId, UserRole role) async {
    state = const AsyncValue.loading();
    try {
      await _apiService.updateUserRole(userId, role);
      state = const AsyncValue.data(null);
      // Refresh users list
      _ref.invalidate(allUsersProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _apiService.deleteUser(userId);
      state = const AsyncValue.data(null);
      // Refresh users list
      _ref.invalidate(allUsersProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    state = const AsyncValue.loading();
    try {
      await _apiService.deleteRestaurant(restaurantId);
      state = const AsyncValue.data(null);
      // Refresh restaurants list
      _ref.invalidate(allRestaurantsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createRestaurant(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _apiService.createRestaurant(data);
      state = const AsyncValue.data(null);
      // Refresh restaurants list
      _ref.invalidate(allRestaurantsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // Rethrow to let UI handle success/failure navigation/feedback
    }
  }

  Future<void> toggleRestaurantStatus(String restaurantId) async {
    state = const AsyncValue.loading();
    try {
      await _apiService.toggleRestaurantStatus(restaurantId);
      state = const AsyncValue.data(null);
      // Refresh restaurants list
      _ref.invalidate(allRestaurantsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    state = const AsyncValue.loading();
    try {
      await _apiService.cancelOrder(orderId);
      state = const AsyncValue.data(null);
      // Refresh orders list
      _ref.invalidate(allOrdersProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> assignOwner(String restaurantId, String ownerId) async {
    state = const AsyncValue.loading();
    try {
      await _apiService.assignRestaurantOwner(restaurantId, ownerId);
      state = const AsyncValue.data(null);
      // Refresh restaurants list
      _ref.invalidate(allRestaurantsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final adminControllerProvider =
    StateNotifierProvider<AdminController, AsyncValue<void>>((ref) {
      final apiService = ref.watch(adminApiServiceProvider);
      return AdminController(apiService, ref);
    });
