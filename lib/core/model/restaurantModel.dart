import 'package:equatable/equatable.dart';
import 'package:rescueeats/core/model/menuItemModel.dart';

class LocationModel extends Equatable {
  final String type;
  final List<double> coordinates; // [longitude, latitude]

  const LocationModel({required this.type, required this.coordinates});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      type: json['type'] ?? 'Point',
      coordinates: List<double>.from(
        (json['coordinates'] as List?)?.map((e) => (e as num).toDouble()) ??
            [0.0, 0.0],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'coordinates': coordinates};
  }

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0.0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;

  @override
  List<Object?> get props => [type, coordinates];
}

class OpeningHoursModel extends Equatable {
  final String open;
  final String close;

  const OpeningHoursModel({required this.open, required this.close});

  factory OpeningHoursModel.fromJson(Map<String, dynamic> json) {
    return OpeningHoursModel(
      open: json['open'] ?? '09:00',
      close: json['close'] ?? '23:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {'open': open, 'close': close};
  }

  @override
  List<Object?> get props => [open, close];
}

class RestaurantModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String address;
  final LocationModel location;
  final String phone;
  final String image;
  final List<String> cuisineType;
  final double rating;
  final int deliveryTime; // minutes
  final double deliveryFee; // rupees
  final double minimumOrder; // rupees
  final bool isOpen;
  final OpeningHoursModel openingHours;
  final List<MenuItemModel> menu;

  // Rating statistics
  final double averageRating;
  final int totalRatings;
  final Map<String, int>? ratingBreakdown;

  // Delivery and Pickup Support
  final bool supportsDelivery;
  final bool supportsPickup;

  // Owner relationship fields
  final String? ownerId;
  final String? ownerName;
  final String? ownerEmail;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.location,
    required this.phone,
    required this.image,
    required this.cuisineType,
    required this.rating,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.minimumOrder,
    required this.isOpen,
    required this.openingHours,
    this.menu = const [],
    this.supportsDelivery = true,
    this.supportsPickup = true,
    this.ownerId,
    this.ownerName,
    this.ownerEmail,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.ratingBreakdown,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    // Parse owner relationship if present
    String? ownerId;
    String? ownerName;
    String? ownerEmail;

    if (json['owner'] != null) {
      if (json['owner'] is String) {
        // Owner is just an ID
        ownerId = json['owner'];
      } else if (json['owner'] is Map) {
        // Owner is populated object
        final ownerData = json['owner'] as Map<String, dynamic>;
        ownerId = ownerData['_id'] ?? ownerData['id'];
        ownerName = ownerData['name'];
        ownerEmail = ownerData['email'];
      }
    }

    return RestaurantModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : const LocationModel(type: 'Point', coordinates: [0.0, 0.0]),
      phone: json['phone'] ?? '',
      image: json['image'] ?? '',
      cuisineType: List<String>.from(
        json['cuisineType'] ?? json['cuisines'] ?? [],
      ),
      rating:
          (json['rating'] ?? json['averageRating'] as num?)?.toDouble() ?? 0.0,
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
      deliveryTime: json['deliveryTime'] ?? 30,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      minimumOrder: (json['minimumOrder'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['isOpen'] ?? false,
      openingHours: json['openingHours'] != null
          ? OpeningHoursModel.fromJson(json['openingHours'])
          : const OpeningHoursModel(open: '09:00', close: '23:00'),
      menu:
          (json['menu'] as List?)
              ?.map((e) => MenuItemModel.fromJson(e))
              .toList() ??
          [],
      supportsDelivery: json['supportsDelivery'] ?? true,
      supportsPickup: json['supportsPickup'] ?? true,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'address': address,
      'location': location.toJson(),
      'phone': phone,
      'image': image,
      'cuisineType': cuisineType,
      'rating': rating,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      if (ratingBreakdown != null) 'ratingBreakdown': ratingBreakdown,
      'deliveryTime': deliveryTime,
      'deliveryFee': deliveryFee,
      'minimumOrder': minimumOrder,
      'isOpen': isOpen,
      'openingHours': openingHours.toJson(),
      'menu': menu.map((e) => e.toJson()).toList(),
      'supportsDelivery': supportsDelivery,
      'supportsPickup': supportsPickup,
      if (ownerId != null) 'owner': ownerId,
    };
  }

  // Backward compatibility getters
  List<String> get cuisines => cuisineType;
  String get openingTime => openingHours.open;
  String get closingTime => openingHours.close;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    address,
    location,
    phone,
    image,
    cuisineType,
    rating,
    averageRating,
    totalRatings,
    ratingBreakdown,
    deliveryTime,
    deliveryFee,
    minimumOrder,
    isOpen,
    openingHours,
    menu,
    supportsDelivery,
    supportsPickup,
    ownerId,
    ownerName,
    ownerEmail,
  ];
}
