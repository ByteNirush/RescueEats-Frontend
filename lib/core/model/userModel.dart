import 'package:equatable/equatable.dart';
import 'package:rescueeats/core/model/addressModel.dart';

// 1. Define the Enum for Roles
enum UserRole { user, restaurant, delivery, admin }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImage;
  final UserRole role;
  final DateTime createdAt;
  final List<AddressModel> addresses; // Added addresses

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImage,
    this.role = UserRole.user,
    required this.createdAt,
    this.addresses = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phoneNumber: (json['phone'] ?? json['phoneNumber']) as String?,
      profileImage: json['profileImage'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == (json['role'] ?? 'user'),
        orElse: () => UserRole.user,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      addresses:
          (json['addresses'] as List<dynamic>?)
              ?.map((e) => AddressModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'addresses': addresses.map((e) => e.toJson()).toList(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImage,
    UserRole? role,
    DateTime? createdAt,
    List<AddressModel>? addresses,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      addresses: addresses ?? this.addresses,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phoneNumber,
    profileImage,
    role,
    createdAt,
    addresses,
  ];
}
