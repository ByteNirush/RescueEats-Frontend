import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rescueeats/core/error/app_exception.dart';
import 'package:rescueeats/core/model/userModel.dart';
import 'package:rescueeats/core/model/restaurantModel.dart';
import 'package:rescueeats/core/model/menuItemModel.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/core/model/addressModel.dart';

class ApiService {
  // Production URL (Render)
  // Production URL (Render)
  static String get baseUrl {
    if (kIsWeb) {
      // Use CORS proxy for web to avoid CORS issues
      return 'https://corsproxy.io/?https://rescueeats.onrender.com/api';
    }
    return 'https://rescueeats.onrender.com/api';
  }

  // static const String baseUrl = 'http://localhost:5001/api';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Helper to get headers with token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper to handle response
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
        throw FetchDataException(
          'Service not found. The backend server may be starting up or unavailable. Please try again in a moment.',
        );
      case 429:
        throw FetchDataException(
          'Server is busy (rate limit reached). Please wait 1-2 minutes and try again. This happens when the server is waking up from sleep.',
        );
      case 500:
      case 502:
      case 503:
        throw FetchDataException(
          'Server error. Our team has been notified. Please try again later.',
        );
      default:
        throw FetchDataException(
          'Unable to connect to server (Error ${response.statusCode}). Please check your internet connection and try again.',
        );
    }
  }

  // Helper to extract error message from response body
  String? _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body);
      return json['message'] ?? json['error'];
    } catch (e) {
      return null;
    }
  }

  // --- AUTHENTICATION ---

  Future<UserModel> login(String email, String password) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/login'),
            headers: headers,
            body: jsonEncode({'emailOrPhone': email, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () {
              throw AppException(
                'Server is waking up. This may take up to a minute. Please try again shortly.',
              );
            },
          );

      final data = _processResponse(response);

      // Save Tokens
      final prefs = await SharedPreferences.getInstance();
      // API returns 'token' (legacy) or 'accessToken'
      if (data['token'] != null) {
        await prefs.setString(_accessTokenKey, data['token']);
      } else if (data['accessToken'] != null) {
        await prefs.setString(_accessTokenKey, data['accessToken']);
      }

      if (data['refreshToken'] != null) {
        await prefs.setString(_refreshTokenKey, data['refreshToken']);
      }

      if (data['user'] != null) {
        return UserModel.fromJson(data['user']);
      }
      return UserModel.fromJson(data);
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw AppException(
          'Cannot connect to server. Please check your internet connection.',
        );
      }
      throw AppException('Login failed: ${e.toString()}');
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/signup'),
            headers: headers,
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone': phoneNumber,
              'password': password,
              'role': role
                  .toString()
                  .split('.')
                  .last, // Use the actual role parameter
            }),
          )
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () {
              throw AppException(
                'Server is waking up. This may take up to a minute. Please try again shortly.',
              );
            },
          );

      final data = _processResponse(response);

      // Save Tokens
      final prefs = await SharedPreferences.getInstance();
      if (data['token'] != null) {
        await prefs.setString(_accessTokenKey, data['token']);
      } else if (data['accessToken'] != null) {
        await prefs.setString(_accessTokenKey, data['accessToken']);
      }

      if (data['refreshToken'] != null) {
        await prefs.setString(_refreshTokenKey, data['refreshToken']);
      }

      if (data['user'] != null) {
        return UserModel.fromJson(data['user']);
      }
      return UserModel.fromJson(data);
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw AppException(
          'Cannot connect to server. Please check your internet connection.',
        );
      }
      throw AppException('Registration failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      final headers = await _getHeaders();
      // Try calling logout, but don't fail if it doesn't exist
      await http.post(Uri.parse('$baseUrl/users/logout'), headers: headers);
    } catch (e) {
      // Ignore network errors on logout
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
    }
  }

  Future<String?> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken == null) return null;

      final response = await http
          .post(
            Uri.parse('$baseUrl/users/refresh-token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 30));

      final data = _processResponse(response);

      if (data['token'] != null) {
        await prefs.setString(_accessTokenKey, data['token']);
        return data['token'];
      } else if (data['accessToken'] != null) {
        await prefs.setString(_accessTokenKey, data['accessToken']);
        return data['accessToken'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- RESTAURANTS ---

  /// Get all restaurants with optional filters
  ///
  /// Query Parameters:
  /// - [category]: Filter by cuisine type (e.g., "indian", "chinese", "italian")
  /// - [search]: Search in restaurant name/description
  /// - [isOpen]: Filter by open status (true/false)
  /// - [page]: Page number for pagination (default: 1)
  /// - [limit]: Number of items per page (default: 20)
  Future<List<RestaurantModel>> getRestaurants({
    String? category,
    String? search,
    bool? isOpen,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isOpen != null) {
        queryParams['isOpen'] = isOpen.toString();
      }

      final uri = Uri.parse(
        '$baseUrl/restaurants',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      // API returns { restaurants: [...] }
      final List<dynamic> list = data['restaurants'] ?? data;
      return list.map((e) => RestaurantModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Get a specific restaurant by ID
  ///
  /// Returns detailed information about a single restaurant
  Future<RestaurantModel> getRestaurantById(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/$restaurantId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      // API returns { restaurant: {...} }
      final restaurantData = data['restaurant'] ?? data;
      return RestaurantModel.fromJson(restaurantData);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Get restaurants owned by current user (Restaurant Owner only)
  ///
  /// Returns list of restaurants where owner = current user ID
  /// Requires authentication with restaurant or admin role
  Future<List<RestaurantModel>> getMyRestaurants() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/my-restaurants'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      // API returns { restaurants: [...], count: n }
      final List<dynamic> list = data['restaurants'] ?? [];
      return list.map((e) => RestaurantModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Get menu items for a specific restaurant
  ///
  /// Returns list of menu items with details like price, category, availability, etc.
  Future<List<MenuItemModel>> getRestaurantMenu(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/$restaurantId/menu'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      // API returns { menu: [...] }
      final List<dynamic> list = data['menu'] ?? data;
      return list.map((e) => MenuItemModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Add a new menu item to a restaurant
  ///
  /// Requires authentication (Owner/Admin only)
  /// Returns the created menu item
  Future<MenuItemModel> addMenuItem({
    required String restaurantId,
    required String name,
    required double price,
    required String description,
    required String image,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'name': name,
        'price': price,
        'description': description,
        'image': image,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/restaurants/$restaurantId/menu'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      // API returns the created menu item
      return MenuItemModel.fromJson(data);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  // --- ORDERS ---

  Future<List<OrderModel>> getOrders({int page = 1, int limit = 20}) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/orders?page=$page&limit=$limit'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      // Assuming data is { orders: [], ... } or just []
      final List<dynamic> list = data['orders'] ?? data;
      return list.map((e) => OrderModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final headers = await _getHeaders();
      if (order.restaurantId.isEmpty) {
        throw AppException('Restaurant ID is missing');
      }

      final body = {
        'restaurantId': order.restaurantId,
        'items': order.items
            .map(
              (e) => {
                'menuId': e.menuId,
                'quantity': e.quantity,
                'price': e.price,
              },
            )
            .toList(),
        'totalAmount': order.totalAmount,
        'deliveryAddress': order.deliveryAddress,
        'contactPhone': order.contactPhone,
        'paymentMethod': order.paymentMethod,
        'coinsUsed': order.coinsUsed, // Added coinsUsed
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/orders'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      final orderData = data['order'] ?? data;
      return OrderModel.fromJson(orderData);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/orders/$orderId'), headers: headers)
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      final orderData = data['order'] ?? data;
      return OrderModel.fromJson(orderData);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(Uri.parse('$baseUrl/orders/$orderId/cancel'), headers: headers)
          .timeout(const Duration(seconds: 60));
      _processResponse(response);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> updateOrderStatus(String id, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/orders/$id/status'),
            headers: headers,
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 60));
      _processResponse(response);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> assignDeliveryPerson(
    String orderId,
    String deliveryPersonId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/orders/$orderId/assign'),
            headers: headers,
            body: jsonEncode({'deliveryPersonId': deliveryPersonId}),
          )
          .timeout(const Duration(seconds: 60));
      _processResponse(response);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/orders/$orderId'), headers: headers)
          .timeout(const Duration(seconds: 60));
      _processResponse(response);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  // --- GAME ---

  /// Initialize or get game state from backend
  Future<Map<String, dynamic>?> initGame() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/game/init'),
            headers: headers,
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 60));
      final data = _processResponse(response);
      return data['game'];
    } catch (e) {
      // Return null if game init fails
      return null;
    }
  }

  /// Update game score (coins and XP) to backend
  Future<bool> updateGameScore(int coins, int xp) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/game/update-score'),
            headers: headers,
            body: jsonEncode({'coins': coins, 'xp': xp}),
          )
          .timeout(const Duration(seconds: 60));
      _processResponse(response);
      return true;
    } catch (e) {
      // Silently fail for game updates to not interrupt gameplay
      return false;
    }
  }

  /// Save complete game session to backend
  Future<bool> saveGameSession({
    required int finalScore,
    required int coinsEarned,
    required int xpEarned,
    required int itemsCaught,
    required int maxCombo,
    required int playTimeSeconds,
    required String difficulty,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/game/update-score'),
            headers: headers,
            body: jsonEncode({
              'coins': coinsEarned,
              'xp': xpEarned,
              'finalScore': finalScore,
              'itemsCaught': itemsCaught,
              'maxCombo': maxCombo,
              'playTime': playTimeSeconds,
              'difficulty': difficulty,
            }),
          )
          .timeout(const Duration(seconds: 60));
      _processResponse(response);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get daily reward status (optional - check if backend supports it)
  Future<Map<String, dynamic>?> getDailyRewardStatus() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/game/daily-reward/status'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        // Endpoint not implemented in backend
        return null;
      }

      final data = _processResponse(response);
      return data;
    } catch (e) {
      print('[API] Daily reward status check failed (not critical): $e');
      return null;
    }
  }

  /// Claim daily reward
  Future<Map<String, dynamic>> claimDailyReward() async {
    try {
      print('[API] Claiming daily reward...');
      final headers = await _getHeaders();
      print('[API] Headers: ${headers.keys.toList()}');
      print('[API] URL: $baseUrl/game/daily-reward');

      final response = await http
          .post(
            Uri.parse('$baseUrl/game/daily-reward'),
            headers: headers,
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 30));

      print('[API] Daily reward response status: ${response.statusCode}');
      print('[API] Daily reward response body: ${response.body}');

      final result = _processResponse(response);
      print('[API] Daily reward parsed result: $result');

      return result;
    } catch (e, stackTrace) {
      print('[API] Daily reward error: $e');
      print('[API] Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Unable to connect to server: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Get daily reward history (last 7 days)
  Future<List<dynamic>?> getDailyRewardHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/game/daily-reward/history'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        return null;
      }

      final data = _processResponse(response);
      return data['history'] as List<dynamic>?;
    } catch (e) {
      print('[API] Daily reward history fetch failed: $e');
      return null;
    }
  }

  /// Get current energy status
  Future<Map<String, dynamic>?> getEnergy() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/game/energy'), headers: headers)
          .timeout(const Duration(seconds: 60));
      final data = _processResponse(response);
      return data['energy'];
    } catch (e) {
      return null;
    }
  }

  /// Use 1 energy (call before starting game)
  Future<bool> useEnergy() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/game/energy/use'),
            headers: headers,
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 60));
      final data = _processResponse(response);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get game leaderboard
  Future<List<dynamic>?> getGameLeaderboard() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/game/leaderboard'), headers: headers)
          .timeout(const Duration(seconds: 60));
      final data = _processResponse(response);
      return List.from(data['leaderboard'] ?? []);
    } catch (e) {
      return null;
    }
  }

  // --- CANCELED ORDERS MARKETPLACE ---

  Future<List<OrderModel>> getCanceledOrders({
    String? cuisine,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (cuisine != null && cuisine.isNotEmpty) {
        queryParams['cuisine'] = cuisine;
      }
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice.toString();
      }

      final uri = Uri.parse(
        '$baseUrl/orders/canceled',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      final List<dynamic> list = data['orders'] ?? [];
      return list.map((e) => OrderModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<Map<String, dynamic>> applyCoins(
    String orderId,
    int coinsToUse,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/orders/$orderId/apply-coins'),
            headers: headers,
            body: jsonEncode({'coinsToUse': coinsToUse}),
          )
          .timeout(const Duration(seconds: 60));

      return _processResponse(response);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<OrderModel> removeCoins(String orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/orders/$orderId/remove-coins'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      return OrderModel.fromJson(data['order']);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  // --- ADDRESS MANAGEMENT ---

  Future<List<AddressModel>> getAddresses() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/users/me/addresses'), headers: headers)
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      final List<dynamic> list = data['addresses'] ?? [];
      return list.map((e) => AddressModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<AddressModel>> addAddress(AddressModel address) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/me/addresses'),
            headers: headers,
            body: jsonEncode(address.toJson()),
          )
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      final List<dynamic> list = data['addresses'] ?? [];
      return list.map((e) => AddressModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<AddressModel>> updateAddress(AddressModel address) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/users/me/addresses/${address.id}'),
            headers: headers,
            body: jsonEncode(address.toJson()),
          )
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      final List<dynamic> list = data['addresses'] ?? [];
      return list.map((e) => AddressModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<AddressModel>> deleteAddress(String addressId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/users/me/addresses/$addressId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      final List<dynamic> list = data['addresses'] ?? [];
      return list.map((e) => AddressModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  // --- NOTIFICATIONS ---

  Future<void> registerFcmToken(String token) async {
    try {
      final headers = await _getHeaders();
      await http
          .post(
            Uri.parse('$baseUrl/users/fcm-token'),
            headers: headers,
            body: jsonEncode({'fcmToken': token}),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      // Ignore errors for token registration
    }
  }

  // --- ACHIEVEMENTS ---

  Future<Map<String, dynamic>> unlockAchievement(
    String achievementId, {
    int reward = 0,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/game/achievements/unlock'),
            headers: headers,
            body: jsonEncode({
              'achievementId': achievementId,
              'reward': reward,
            }),
          )
          .timeout(const Duration(seconds: 60));

      return _processResponse(response);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<List<dynamic>> getAchievements() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/game/achievements'), headers: headers)
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      return data['achievements'] ?? [];
    } catch (e) {
      throw AppException(e.toString());
    }
  }
}
