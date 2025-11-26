import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rescueeats/core/error/app_exception.dart';
import 'package:rescueeats/core/model/restaurantModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API Service for Restaurant Owner operations
/// Handles restaurant creation and management for restaurant role users
class RestaurantApiService {
  // Production URL (Render)
  static const String baseUrl = 'https://rescueeats.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 30);

  // Helper method to get auth headers
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper to process response
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

  /// Create restaurant (Owner creates their own restaurant)
  /// Backend automatically uses ownerId from JWT token
  /// Owner can only create ONE restaurant
  Future<RestaurantModel> createMyRestaurant(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .post(
            Uri.parse('$baseUrl/restaurants'),
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      final responseData = _processResponse(response);
      final restaurantData = responseData['restaurant'] ?? responseData;

      return RestaurantModel.fromJson(restaurantData);
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw FetchDataException('Cannot connect to server. Check internet.');
      }
      throw FetchDataException('Failed to create restaurant: ${e.toString()}');
    }
  }

  /// Update restaurant details
  Future<RestaurantModel> updateMyRestaurant(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .put(
            Uri.parse('$baseUrl/restaurants/$id'),
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      final responseData = _processResponse(response);
      final restaurantData = responseData['restaurant'] ?? responseData;

      return RestaurantModel.fromJson(restaurantData);
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException('Failed to update restaurant: ${e.toString()}');
    }
  }

  /// Toggle restaurant open/close status
  Future<RestaurantModel> toggleMyRestaurantStatus(String id) async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .patch(Uri.parse('$baseUrl/restaurants/$id/toggle'), headers: headers)
          .timeout(_timeout);

      final responseData = _processResponse(response);
      final restaurantData = responseData['restaurant'] ?? responseData;

      return RestaurantModel.fromJson(restaurantData);
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException(
        'Failed to toggle restaurant status: ${e.toString()}',
      );
    }
  }

  /// Get my restaurants (for restaurant owner)
  Future<List<RestaurantModel>> getMyRestaurants() async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/my-restaurants'),
            headers: headers,
          )
          .timeout(_timeout);

      final data = _processResponse(response);
      final List<dynamic> list = data['restaurants'] ?? [];
      return list.map((e) => RestaurantModel.fromJson(e)).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw FetchDataException('Cannot connect to server. Check internet.');
      }
      throw FetchDataException('Failed to fetch restaurants: ${e.toString()}');
    }
  }
}
