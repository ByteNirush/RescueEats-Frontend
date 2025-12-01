import 'package:rescueeats/core/model/restaurantModel.dart';
import 'package:rescueeats/core/model/orderModel.dart';

class MarketplaceItemModel {
  final String id;
  final String orderId;
  final RestaurantModel? restaurant;
  final String restaurantId;
  final List<OrderItem> items;
  final double originalPrice;
  final double discountPercent;
  final double discountedPrice;
  final String availability; // available, sold, expired
  final DateTime canceledAt;
  final String cancelReason;
  final DateTime? statusUpdatedAt;
  final String? purchasedBy;
  final DateTime? purchasedAt;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketplaceItemModel({
    required this.id,
    required this.orderId,
    this.restaurant,
    required this.restaurantId,
    required this.items,
    required this.originalPrice,
    required this.discountPercent,
    required this.discountedPrice,
    required this.availability,
    required this.canceledAt,
    required this.cancelReason,
    this.statusUpdatedAt,
    this.purchasedBy,
    this.purchasedAt,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketplaceItemModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceItemModel(
      id: json['_id'] ?? '',
      orderId: json['order'] is String
          ? json['order']
          : (json['order']?['_id'] ?? ''),
      restaurant: json['restaurant'] != null && json['restaurant'] is Map
          ? RestaurantModel.fromJson(json['restaurant'])
          : null,
      restaurantId: json['restaurant'] is String
          ? json['restaurant']
          : (json['restaurant']?['_id'] ?? ''),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      discountPercent: (json['discountPercent'] ?? 0).toDouble(),
      discountedPrice: (json['discountedPrice'] ?? 0).toDouble(),
      availability: json['availability'] ?? 'available',
      canceledAt: DateTime.parse(
        json['canceledAt'] ?? DateTime.now().toIso8601String(),
      ),
      cancelReason: json['cancelReason'] ?? '',
      statusUpdatedAt: json['statusUpdatedAt'] != null
          ? DateTime.parse(json['statusUpdatedAt'])
          : null,
      purchasedBy: json['purchasedBy'],
      purchasedAt: json['purchasedAt'] != null
          ? DateTime.parse(json['purchasedAt'])
          : null,
      expiresAt: DateTime.parse(
        json['expiresAt'] ?? DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'order': orderId,
      'restaurant': restaurantId,
      'items': items.map((item) => item.toJson()).toList(),
      'originalPrice': originalPrice,
      'discountPercent': discountPercent,
      'discountedPrice': discountedPrice,
      'availability': availability,
      'canceledAt': canceledAt.toIso8601String(),
      'cancelReason': cancelReason,
      'statusUpdatedAt': statusUpdatedAt?.toIso8601String(),
      'purchasedBy': purchasedBy,
      'purchasedAt': purchasedAt?.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isAvailable => availability == 'available' && !isExpired;
  bool get isSold => availability == 'sold';

  double get savingsAmount => originalPrice - discountedPrice;
}
