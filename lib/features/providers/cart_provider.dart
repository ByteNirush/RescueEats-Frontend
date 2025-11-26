import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/menuItemModel.dart';

class CartItem {
  final MenuItemModel menuItem;
  final int quantity;

  CartItem({required this.menuItem, required this.quantity});

  double get totalPrice => menuItem.price * quantity;
}

class CartState {
  final String? restaurantId;
  final String? restaurantName;
  final List<CartItem> items;

  CartState({this.restaurantId, this.restaurantName, this.items = const []});

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    String? restaurantId,
    String? restaurantName,
    List<CartItem>? items,
  }) {
    return CartState(
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addItem(MenuItemModel item, String restaurantId, String restaurantName) {
    // If adding from a different restaurant, clear cart first (or ask user, but for now auto-clear/strict)
    if (state.restaurantId != null && state.restaurantId != restaurantId) {
      // For simplicity, we'll just reset for the new restaurant.
      // In a real app, you'd show a dialog "Start new basket?"
      state = CartState(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        items: [CartItem(menuItem: item, quantity: 1)],
      );
      return;
    }

    // Same restaurant, check if item exists
    final existingIndex = state.items.indexWhere(
      (i) => i.menuItem.id == item.id,
    );
    if (existingIndex >= 0) {
      final newItems = List<CartItem>.from(state.items);
      final existingItem = newItems[existingIndex];
      newItems[existingIndex] = CartItem(
        menuItem: existingItem.menuItem,
        quantity: existingItem.quantity + 1,
      );
      state = state.copyWith(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        items: newItems,
      );
    } else {
      state = state.copyWith(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        items: [
          ...state.items,
          CartItem(menuItem: item, quantity: 1),
        ],
      );
    }
  }

  void removeItem(String itemId) {
    final existingIndex = state.items.indexWhere(
      (i) => i.menuItem.id == itemId,
    );
    if (existingIndex == -1) return;

    final newItems = List<CartItem>.from(state.items);
    final existingItem = newItems[existingIndex];

    if (existingItem.quantity > 1) {
      newItems[existingIndex] = CartItem(
        menuItem: existingItem.menuItem,
        quantity: existingItem.quantity - 1,
      );
    } else {
      newItems.removeAt(existingIndex);
    }

    if (newItems.isEmpty) {
      clearCart();
    } else {
      state = state.copyWith(items: newItems);
    }
  }

  void clearCart() {
    state = CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
