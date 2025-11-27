import 'package:equatable/equatable.dart';

class AddressModel extends Equatable {
  final String? id;
  final String label;
  final String street;
  final String city;
  final String landmark;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const AddressModel({
    this.id,
    required this.label,
    required this.street,
    required this.city,
    this.landmark = '',
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'],
      label: json['label'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      landmark: json['landmark'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'label': label,
      'street': street,
      'city': city,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
    };
  }

  @override
  List<Object?> get props => [
    id,
    label,
    street,
    city,
    landmark,
    latitude,
    longitude,
    isDefault,
  ];
}
