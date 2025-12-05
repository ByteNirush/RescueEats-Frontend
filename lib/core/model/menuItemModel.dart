import 'package:equatable/equatable.dart';

class MenuItemModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final bool isAvailable;
  final bool isVeg;
  final int? discount; // percentage

  // Rating statistics
  final double averageRating;
  final int totalRatings;
  final Map<String, int>? ratingBreakdown;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    required this.isAvailable,
    required this.isVeg,
    this.discount,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.ratingBreakdown,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: json['image'] ?? '',
      category: json['category'] ?? 'Other',
      isAvailable: json['isAvailable'] ?? true,
      isVeg: json['isVeg'] ?? false,
      discount: json['discount'],
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] ?? 0,
      ratingBreakdown: json['ratingBreakdown'] != null
          ? {
              'fiveStar': json['ratingBreakdown']['fiveStar'] ?? 0,
              'fourStar': json['ratingBreakdown']['fourStar'] ?? 0,
              'threeStar': json['ratingBreakdown']['threeStar'] ?? 0,
              'twoStar': json['ratingBreakdown']['twoStar'] ?? 0,
              'oneStar': json['ratingBreakdown']['oneStar'] ?? 0,
            }
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category': category,
      'isAvailable': isAvailable,
      'isVeg': isVeg,
      'discount': discount,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      if (ratingBreakdown != null) 'ratingBreakdown': ratingBreakdown,
    };
  }

  // Calculate discounted price
  double get discountedPrice {
    if (discount != null && discount! > 0) {
      return price * (1 - discount! / 100);
    }
    return price;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    image,
    category,
    isAvailable,
    isVeg,
    discount,
    averageRating,
    totalRatings,
    ratingBreakdown,
  ];
}
