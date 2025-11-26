import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rescueeats/core/error/app_exception.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/core/model/restaurantModel.dart';
import 'package:rescueeats/core/model/userModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminApiService {
  // Production URL (Render)
  static const String baseUrl = 'https://rescueeats.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 30);

  // In-memory cache
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Helper method to get auth headers
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper to process response (consistent with api_service.dart)
  dynamic _processResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return jsonDecode(response.body);
      case 400:
        final errorMsg = _extractErrorMessage(response.body);
        throw BadRequestException(
          errorMsg ?? 'Invalid request. Please check your input.',
        );
      case 401:
      case 403:
        final errorMsg = _extractErrorMessage(response.body);
        throw UnauthorisedException(
          errorMsg ?? 'Session expired. Please login again.',
        );
      case 404:
        throw FetchDataException('Resource not found. Please try again.');
      case 500:
      case 502:
      case 503:
        throw FetchDataException('Server error. Please try again later.');
      default:
        throw FetchDataException(
          'Unable to connect (Error ${response.statusCode}). Check your internet connection.',
        );
    }
  }

  String? _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body);
      return json['message'] ?? json['error'];
    } catch (e) {
      return null;
    }
  }

  // Cache helpers
  T? _getFromCache<T>(String key) {
    if (_cache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        return _cache[key] as T?;
      } else {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
    return null;
  }

  void _setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // ============ User Management ============

  /// Get all users - fetched from real backend
  Future<List<UserModel>> getAllUsers() async {
    try {
      // Check cache first
      final cached = _getFromCache<List<UserModel>>('all_users');
      if (cached != null) return cached;

      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/users'), headers: headers)
          .timeout(_timeout);

      final data = _processResponse(response);
      final users = (data['users'] as List)
          .map((json) => UserModel.fromJson(json))
          .toList();

      _setCache('all_users', users);
      return users;
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw FetchDataException('Cannot connect to server. Check internet.');
      }
      throw FetchDataException('Failed to fetch users: ${e.toString()}');
    }
  }

  /// Get users by role
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final roleString = role.toString().split('.').last;
      final cacheKey = 'users_role_$roleString';

      // Check cache first
      final cached = _getFromCache<List<UserModel>>(cacheKey);
      if (cached != null) return cached;

      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/users?role=$roleString'), headers: headers)
          .timeout(_timeout);

      final data = _processResponse(response);
      final users = (data['users'] as List)
          .map((json) => UserModel.fromJson(json))
          .toList();

      _setCache(cacheKey, users);
      return users;
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw FetchDataException('Cannot connect to server. Check internet.');
      }
      throw FetchDataException(
        'Failed to fetch users by role: ${e.toString()}',
      );
    }
  }

  /// Get user by ID
  Future<UserModel> getUserById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/users/profile'), headers: headers)
          .timeout(_timeout);

      final data = _processResponse(response);
      return UserModel.fromJson(data['user'] ?? data);
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException('Failed to fetch user: ${e.toString()}');
    }
  }

  /// Update user role (mock - would need backend endpoint)
  Future<UserModel> updateUserRole(String id, UserRole role) async {
    try {
      // TODO: Implement when backend supports it
      await Future.delayed(const Duration(milliseconds: 500));
      clearCache(); // Invalidate cache

      // Return updated user (mock)
      final users = await getAllUsers();
      final user = users.firstWhere((u) => u.id == id);
      return user.copyWith(role: role);
    } catch (e) {
      throw FetchDataException('Failed to update user role: ${e.toString()}');
    }
  }

  /// Delete user (mock - would need backend endpoint)
  Future<void> deleteUser(String id) async {
    try {
      // TODO: Implement when backend supports it
      await Future.delayed(const Duration(milliseconds: 500));
      clearCache(); // Invalidate cache
    } catch (e) {
      throw FetchDataException('Failed to delete user: ${e.toString()}');
    }
  }

  // ============ Restaurant Management ============

  /// Get all restaurants (REAL DATA)
  Future<List<RestaurantModel>> getAllRestaurants() async {
    try {
      final cached = _getFromCache<List<RestaurantModel>>('all_restaurants');
      if (cached != null) return cached;

      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/restaurants'), headers: headers)
          .timeout(_timeout);

      final data = _processResponse(response);
      final restaurants = (data['restaurants'] as List)
          .map((json) => RestaurantModel.fromJson(json))
          .toList();

      _setCache('all_restaurants', restaurants);
      return restaurants;
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw FetchDataException('Cannot connect to server. Check internet.');
      }
      throw FetchDataException('Failed to fetch restaurants: ${e.toString()}');
    }
  }

  /// Update restaurant (mock - would need backend endpoint)
  Future<RestaurantModel> updateRestaurant(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      // TODO: Implement when backend supports it
      await Future.delayed(const Duration(milliseconds: 500));
      clearCache();

      final restaurants = await getAllRestaurants();
      return restaurants.firstWhere((r) => r.id == id);
    } catch (e) {
      throw FetchDataException('Failed to update restaurant: ${e.toString()}');
    }
  }

  /// Delete restaurant (mock - would need backend endpoint)
  Future<void> deleteRestaurant(String id) async {
    try {
      // TODO: Implement when backend supports it
      await Future.delayed(const Duration(milliseconds: 500));
      clearCache();
    } catch (e) {
      throw FetchDataException('Failed to delete restaurant: ${e.toString()}');
    }
  }

  /// Create a new restaurant
  Future<RestaurantModel> createRestaurant(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      // Backend automatically extracts ownerId from JWT token
      // No need to pass owner in request body

      final response = await http
          .post(
            Uri.parse('$baseUrl/restaurants'),
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      final responseData = _processResponse(response);
      // API returns { restaurant: {...} } or just the object
      final restaurantData = responseData['restaurant'] ?? responseData;

      clearCache(); // Invalidate cache
      return RestaurantModel.fromJson(restaurantData);
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException('Failed to create restaurant: ${e.toString()}');
    }
  }

  /// Toggle restaurant status (Open/Closed)
  Future<void> toggleRestaurantStatus(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(Uri.parse('$baseUrl/restaurants/$id/toggle'), headers: headers)
          .timeout(_timeout);

      _processResponse(response);
      clearCache(); // Invalidate cache
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException(
        'Failed to toggle restaurant status: ${e.toString()}',
      );
    }
  }

  /// Assign owner to restaurant
  Future<RestaurantModel> assignRestaurantOwner(
    String restaurantId,
    String ownerId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/restaurants/$restaurantId/assign-owner'),
            headers: headers,
            body: jsonEncode({'ownerId': ownerId}),
          )
          .timeout(_timeout);

      final responseData = _processResponse(response);
      final restaurantData = responseData['restaurant'] ?? responseData;

      clearCache(); // Invalidate cache
      return RestaurantModel.fromJson(restaurantData);
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException('Failed to assign owner: ${e.toString()}');
    }
  }

  // ============ Order Management ============

  /// Get all orders (REAL DATA)
  Future<List<OrderModel>> getAllOrders({String? status}) async {
    try {
      final cacheKey = 'all_orders_${status ?? "all"}';
      final cached = _getFromCache<List<OrderModel>>(cacheKey);
      if (cached != null) return cached;

      final headers = await _getHeaders();
      final queryParams = status != null ? '?status=$status' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/orders$queryParams'), headers: headers)
          .timeout(_timeout);

      final data = _processResponse(response);
      final orders = (data['orders'] as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();

      _setCache(cacheKey, orders);
      return orders;
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw FetchDataException('Cannot connect to server. Check internet.');
      }
      throw FetchDataException('Failed to fetch orders: ${e.toString()}');
    }
  }

  /// Get order by ID (REAL DATA)
  Future<OrderModel> getOrderById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/orders/$id'), headers: headers)
          .timeout(_timeout);

      final data = _processResponse(response);
      return OrderModel.fromJson(data['order'] ?? data);
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException('Failed to fetch order: ${e.toString()}');
    }
  }

  /// Cancel order (REAL DATA)
  Future<void> cancelOrder(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(Uri.parse('$baseUrl/orders/$id/cancel'), headers: headers)
          .timeout(_timeout);

      _processResponse(response);
      clearCache(); // Invalidate cache after mutation
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException('Failed to cancel order: ${e.toString()}');
    }
  }

  // ============ Analytics (Calculated from Real Data) ============

  /// Get analytics data - CALCULATED FROM REAL DATA
  Future<Map<String, dynamic>> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final cached = _getFromCache<Map<String, dynamic>>('analytics');
      if (cached != null) return cached;

      // Fetch real data
      final orders = await getAllOrders();
      final restaurants = await getAllRestaurants();
      final users = await getAllUsers();

      // Calculate analytics
      final analytics = {
        'revenue': _calculateRevenue(orders),
        'orders': _calculateOrderStats(orders),
        'users': _calculateUserStats(users),
        'restaurants': _calculateRestaurantStats(restaurants),
      };

      _setCache('analytics', analytics);
      return analytics;
    } catch (e) {
      throw FetchDataException('Failed to fetch analytics: ${e.toString()}');
    }
  }

  Map<String, dynamic> _calculateRevenue(List<OrderModel> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    double todayRevenue = 0;
    double weekRevenue = 0;
    double monthRevenue = 0;
    double totalRevenue = 0;

    for (final order in orders) {
      if (order.status == 'delivered' || order.status == 'completed') {
        final amount = order.totalAmount;
        totalRevenue += amount;

        if (order.createdAt.isAfter(today)) {
          todayRevenue += amount;
        }
        if (order.createdAt.isAfter(weekAgo)) {
          weekRevenue += amount;
        }
        if (order.createdAt.isAfter(monthStart)) {
          monthRevenue += amount;
        }
      }
    }

    return {
      'today': todayRevenue,
      'week': weekRevenue,
      'month': monthRevenue,
      'total': totalRevenue,
    };
  }

  Map<String, dynamic> _calculateOrderStats(List<OrderModel> orders) {
    final stats = <String, int>{
      'total': orders.length,
      'pending': 0,
      'cooking': 0,
      'preparing': 0,
      'ready': 0,
      'delivered': 0,
      'cancelled': 0,
    };

    for (final order in orders) {
      final status = order.status.toLowerCase();
      if (stats.containsKey(status)) {
        stats[status] = (stats[status] ?? 0) + 1;
      }
    }

    return stats;
  }

  Map<String, dynamic> _calculateUserStats(List<UserModel> users) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int total = users.length;
    int newToday = 0;
    int customers = 0;
    int restaurantOwners = 0;
    int deliveryPartners = 0;

    for (final user in users) {
      if (user.createdAt.isAfter(today)) {
        newToday++;
      }

      switch (user.role) {
        case UserRole.user:
          customers++;
          break;
        case UserRole.restaurant:
          restaurantOwners++;
          break;
        case UserRole.delivery:
          deliveryPartners++;
          break;
        case UserRole.admin:
          break;
      }
    }

    return {
      'total': total,
      'newToday': newToday,
      'customers': customers,
      'restaurants': restaurantOwners,
      'delivery': deliveryPartners,
    };
  }

  Map<String, dynamic> _calculateRestaurantStats(
    List<RestaurantModel> restaurants,
  ) {
    int total = restaurants.length;
    int active = 0;
    int inactive = 0;

    for (final restaurant in restaurants) {
      if (restaurant.isOpen) {
        active++;
      } else {
        inactive++;
      }
    }

    return {'total': total, 'active': active, 'inactive': inactive};
  }

  /// Get revenue statistics - CALCULATED FROM REAL DATA
  Future<Map<String, dynamic>> getRevenueStats() async {
    try {
      final analytics = await getAnalytics();
      return analytics['revenue'] as Map<String, dynamic>;
    } catch (e) {
      throw FetchDataException(
        'Failed to fetch revenue stats: ${e.toString()}',
      );
    }
  }

  /// Get user statistics - CALCULATED FROM REAL DATA
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final analytics = await getAnalytics();
      return analytics['users'] as Map<String, dynamic>;
    } catch (e) {
      throw FetchDataException('Failed to fetch user stats: ${e.toString()}');
    }
  }

  /// Get restaurant statistics - CALCULATED FROM REAL DATA
  Future<Map<String, dynamic>> getRestaurantStats() async {
    try {
      final analytics = await getAnalytics();
      return analytics['restaurants'] as Map<String, dynamic>;
    } catch (e) {
      throw FetchDataException(
        'Failed to fetch restaurant stats: ${e.toString()}',
      );
    }
  }
}
