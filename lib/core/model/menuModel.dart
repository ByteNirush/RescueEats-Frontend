import 'package:equatable/equatable.dart';

// --- MENU ITEM MODEL ---
class MenuItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isAvailable = true,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    imageUrl,
    isAvailable,
  ];
}
