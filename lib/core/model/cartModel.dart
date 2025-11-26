// --- CART ITEM MODEL ---
import 'package:equatable/equatable.dart';
import 'package:rescueeats/core/model/menuModel.dart';

class CartItem extends Equatable {
  final MenuItem menuItem;
  final int quantity;

  const CartItem({required this.menuItem, required this.quantity});

  double get totalPrice => menuItem.price * quantity;

  CartItem copyWith({MenuItem? menuItem, int? quantity}) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [menuItem, quantity];
}
