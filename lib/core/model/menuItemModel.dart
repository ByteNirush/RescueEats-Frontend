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
  ];
}
