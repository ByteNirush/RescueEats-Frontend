import 'package:equatable/equatable.dart';

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
    this.ownerId,
    this.ownerName,
    this.ownerEmail,
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
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      deliveryTime: json['deliveryTime'] ?? 30,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      minimumOrder: (json['minimumOrder'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['isOpen'] ?? false,
      openingHours: json['openingHours'] != null
          ? OpeningHoursModel.fromJson(json['openingHours'])
          : const OpeningHoursModel(open: '09:00', close: '23:00'),
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
      'deliveryTime': deliveryTime,
      'deliveryFee': deliveryFee,
      'minimumOrder': minimumOrder,
      'isOpen': isOpen,
      'openingHours': openingHours.toJson(),
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
    deliveryTime,
    deliveryFee,
    minimumOrder,
    isOpen,
    openingHours,
    ownerId,
    ownerName,
    ownerEmail,
  ];
}
