import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rescueeats/core/error/app_exception.dart';
import 'package:rescueeats/core/model/userModel.dart';
import 'package:rescueeats/core/model/restaurantModel.dart';
import 'package:rescueeats/core/model/menuItemModel.dart';
import 'package:rescueeats/core/model/orderModel.dart';

class ApiService {
  // Production URL (Render)
  static const String baseUrl = 'https://rescueeats.onrender.com/api';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Helper to get headers with token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    return {
      'Content-Type': 'application/json',
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
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/login'),
            headers: {'Content-Type': 'application/json'},
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
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/signup'),
            headers: {'Content-Type': 'application/json'},
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

  /// Google Authentication
  ///
  /// ⚠️ IMPORTANT LIMITATION:
  /// The backend uses OAuth 2.0 web flow (GET /api/auth/google) which redirects
  /// users to Google's consent screen in a browser. This is incompatible with
  /// native mobile Google Sign-In which provides an ID token directly.
  ///
  /// Current Implementation:
  /// - This method attempts to POST an ID token to /api/users/google-auth
  /// - This endpoint does NOT exist in the current backend
  ///
  /// To Fix:
  /// Option 1: Add a new backend endpoint POST /api/auth/google-mobile that accepts ID tokens
  /// Option 2: Use WebView to implement the OAuth flow (GET /api/auth/google)
  /// Option 3: Disable Google Sign-In in mobile app until backend support is added
  ///
  /// For now, this method will fail with 404 error.
  Future<UserModel> googleAuth(String idToken, UserRole role) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/google-auth'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken, 'role': role.name}),
          )
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);

      // Save Token
      final prefs = await SharedPreferences.getInstance();
      if (data['token'] != null) {
        await prefs.setString(_accessTokenKey, data['token']);
      } else if (data['accessToken'] != null) {
        await prefs.setString(_accessTokenKey, data['accessToken']);
      }

      if (data['user'] != null) {
        return UserModel.fromJson(data['user']);
      }
      return UserModel.fromJson(data);
    } catch (e) {
      throw AppException(e.toString());
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
    } catch (e) {
      // If refresh fails, user might need to login again
      return null;
    }
    return null;
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

      // Backend expects: { restaurantId, items: [{menuId, quantity, price}], totalAmount, deliveryAddress, paymentMethod }
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
        'paymentMethod': order.paymentMethod,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/orders'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      final data = _processResponse(response);
      // API returns { order: {...} }
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

  /// Claim daily reward
  Future<Map<String, dynamic>> claimDailyReward() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/game/daily-reward'),
            headers: headers,
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 60));
      return _processResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
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
}
