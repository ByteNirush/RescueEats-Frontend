import 'dart:async';
// In production, you would import 'package:dio/dio.dart' or 'package:http/http.dart';

class ApiClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ApiClient({
    this.baseUrl = 'https://rescueeats.onrender.com/api',
    this.defaultHeaders = const {'Content-Type': 'application/json'},
  });

  Future<dynamic> get(String endpoint) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      return _mockResponses(endpoint);
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  Future<dynamic> post(
    String endpoint, {
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return data;
  }

  Future<dynamic> patch(
    String endpoint, {
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return data;
  }

  // --- MOCK DATA (Updated for Nepal) ---
  dynamic _mockResponses(String endpoint) {
    if (endpoint.contains('/orders')) {
      return [
        {
          'id': '#ORD-8852',
          'customerName': 'Ram Bahadur',
          'restaurantName': 'Burger King Nepal',
          'deliveryAddress': 'Lazimpat, Kathmandu',
          'totalAmount': 1450.00, // Adjusted for NPR
          'items': ['Double Whopper Meal', 'Onion Rings'],
          'status': 'cooking',
          'createdAt': DateTime.now()
              .subtract(const Duration(minutes: 15))
              .toIso8601String(),
        },
        {
          'id': '#ORD-9941',
          'customerName': 'Sita Sharma',
          'restaurantName': 'Pizza Hut Durbar Marg',
          'deliveryAddress': 'Baneshwor, Kathmandu',
          'totalAmount': 2100.00, // Adjusted for NPR
          'items': ['Large Pepperoni', 'Garlic Bread'],
          'status': 'pending',
          'createdAt': DateTime.now()
              .subtract(const Duration(minutes: 2))
              .toIso8601String(),
        },
      ];
    }
    return [];
  }
}
