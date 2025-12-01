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
    } else if (json['productId'] != null) {
      // Handle backend structure where ID is in productId
      mId = json['productId'];
    }

    return OrderItem(
      menuId: mId,
      menuItemName: mName.isNotEmpty ? mName : (json['name'] ?? ''),
      menuItemImage: mImage.isNotEmpty ? mImage : (json['image'] ?? ''),
      quantity: json['quantity'] ?? json['qty'] ?? 0,
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
  final String customerId;
  final String customerName;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImage;
  final List<OrderItem> items;
  final double totalAmount;
  final double deliveryCharge;
  final String status;
  final String deliveryAddress;
  final String? contactPhone;
  final String paymentMethod;
  final String orderType; // 'delivery' or 'pickup'
  final DateTime createdAt;

  // Canceled Order Fields
  final bool isCanceled;
  final double? originalPrice;
  final double discountPercent;
  final double? discountedPrice;
  final DateTime? canceledAt;
  final String cancelReason;

  // Coin Redemption Fields
  final int coinsUsed;
  final double coinDiscount;

  // Rating & Review
  final int? rating;
  final String review;
  final DateTime? ratedAt;

  const OrderModel({
    required this.id,
    this.customerId = '',
    this.customerName = '',
    required this.restaurantId,
    this.restaurantName = '',
    this.restaurantImage = '',
    required this.items,
    required this.totalAmount,
    this.deliveryCharge = 0.0,
    required this.status,
    required this.deliveryAddress,
    this.contactPhone,
    required this.paymentMethod,
    this.orderType = 'delivery',
    required this.createdAt,
    this.isCanceled = false,
    this.originalPrice,
    this.discountPercent = 0.0,
    this.discountedPrice,
    this.canceledAt,
    this.cancelReason = '',
    this.coinsUsed = 0,
    this.coinDiscount = 0.0,
    this.rating,
    this.review = '',
    this.ratedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    String cId = '';
    String cName = '';
    String rId = '';
    String rName = '';
    String rImage = '';

    // Parse customer information
    if (json['customer'] is Map) {
      cId = json['customer']['_id'] ?? '';
      cName = json['customer']['username'] ?? json['customer']['name'] ?? '';
    } else if (json['customer'] is String) {
      cId = json['customer'];
    } else if (json['customerId'] != null) {
      cId = json['customerId'];
    }

    if (json['restaurant'] is Map) {
      rId = json['restaurant']['_id'] ?? '';
      rName = json['restaurant']['name'] ?? '';
      rImage = json['restaurant']['image'] ?? '';
    } else if (json['restaurant'] is String) {
      rId = json['restaurant'];
    } else if (json['restaurantId'] != null) {
      rId = json['restaurantId'];
    }

    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      customerId: cId,
      customerName: cName,
      restaurantId: rId,
      restaurantName: rName,
      restaurantImage: rImage,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
      totalAmount:
          (json['subtotal'] ?? json['totalAmount'] ?? json['total'] ?? 0)
              .toDouble(),
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      deliveryAddress: json['deliveryAddress'] ?? '',
      contactPhone: json['contactPhone'],
      paymentMethod: json['paymentMethod'] ?? 'cod',
      orderType: json['orderType'] ?? 'delivery',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isCanceled: json['isCanceled'] ?? false,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      canceledAt: json['canceledAt'] != null
          ? DateTime.parse(json['canceledAt'])
          : null,
      cancelReason: json['cancelReason'] ?? '',
      coinsUsed: json['coinsUsed'] ?? 0,
      coinDiscount: (json['coinDiscount'] as num?)?.toDouble() ?? 0.0,
      rating: json['rating'],
      review: json['review'] ?? '',
      ratedAt: json['ratedAt'] != null ? DateTime.parse(json['ratedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'customer': customerId,
      'restaurant': restaurantId,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'deliveryCharge': deliveryCharge,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'contactPhone': contactPhone,
      'paymentMethod': paymentMethod,
      'orderType': orderType,
      'createdAt': createdAt.toIso8601String(),
      'isCanceled': isCanceled,
      'originalPrice': originalPrice,
      'discountPercent': discountPercent,
      'discountedPrice': discountedPrice,
      'canceledAt': canceledAt?.toIso8601String(),
      'cancelReason': cancelReason,
      'coinsUsed': coinsUsed,
      'coinDiscount': coinDiscount,
      'rating': rating,
      'review': review,
      'ratedAt': ratedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    customerName,
    restaurantId,
    restaurantName,
    restaurantImage,
    items,
    totalAmount,
    deliveryCharge,
    status,
    deliveryAddress,
    contactPhone,
    paymentMethod,
    orderType,
    createdAt,
    isCanceled,
    originalPrice,
    discountPercent,
    discountedPrice,
    canceledAt,
    cancelReason,
    coinsUsed,
    coinDiscount,
    rating,
    review,
    ratedAt,
  ];
}
