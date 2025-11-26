import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String menuId;
  final String menuItemName; // Added for display
  final String menuItemImage; // Added for display
  final int quantity;
  final double price; // Added price per item

  const OrderItem({
    required this.menuId,
    this.menuItemName = '',
    this.menuItemImage = '',
    required this.quantity,
    this.price = 0.0,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Handle menuItem as Object or String
    String mId = '';
    String mName = '';
    String mImage = '';

    if (json['menuItem'] is Map) {
      mId = json['menuItem']['_id'] ?? '';
      mName = json['menuItem']['name'] ?? '';
      mImage = json['menuItem']['image'] ?? '';
    } else if (json['menuItem'] is String) {
      mId = json['menuItem'];
    }

    return OrderItem(
      menuId: mId,
      menuItemName: mName,
      menuItemImage: mImage,
      quantity: json['quantity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'menuItem': menuId, 'quantity': quantity, 'price': price};
  }

  @override
  List<Object?> get props => [
    menuId,
    menuItemName,
    menuItemImage,
    quantity,
    price,
  ];
}

class OrderModel extends Equatable {
  final String id;
  final String restaurantId;
  final String restaurantName; // Added for display
  final String restaurantImage; // Added for display
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String deliveryAddress;
  final String paymentMethod;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.restaurantId,
    this.restaurantName = '',
    this.restaurantImage = '',
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Handle restaurant as Object or String
    String rId = '';
    String rName = '';
    String rImage = '';

    if (json['restaurant'] is Map) {
      rId = json['restaurant']['_id'] ?? '';
      rName = json['restaurant']['name'] ?? '';
      rImage = json['restaurant']['image'] ?? '';
    } else if (json['restaurant'] is String) {
      rId = json['restaurant'];
    } else if (json['restaurantId'] != null) {
      // Fallback for older mock data or different API structure
      rId = json['restaurantId'];
    }

    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      restaurantId: rId,
      restaurantName: rName,
      restaurantImage: rImage,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      deliveryAddress: json['deliveryAddress'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'cod',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'restaurant': restaurantId, // API expects 'restaurant'
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    restaurantId,
    restaurantName,
    restaurantImage,
    items,
    totalAmount,
    status,
    deliveryAddress,
    paymentMethod,
    createdAt,
  ];
}
