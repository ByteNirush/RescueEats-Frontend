import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/cartModel.dart';
import 'package:rescueeats/core/model/menuModel.dart';

// --- 1. CART PROVIDER ---
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(MenuItem item) {
    final index = state.indexWhere((element) => element.menuItem.id == item.id);

    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      state = [...state, CartItem(menuItem: item, quantity: 1)];
    }
  }

  void removeFromCart(String itemId) {
    state = state.where((item) => item.menuItem.id != itemId).toList();
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount => state.fold(0, (sum, item) => sum + item.totalPrice);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// --- 2. RESTAURANT MENU PROVIDER (NPR Pricing) ---
class MenuNotifier extends StateNotifier<List<MenuItem>> {
  MenuNotifier()
    : super([
        const MenuItem(
          id: '1',
          name: 'Chicken Momo (Steam)',
          description: 'Authentic Nepali spices served with jhol achar.',
          price: 250.00,
          imageUrl:
              'https://via.placeholder.com/200x200/FF6B35/FFFFFF?text=Momo',
        ),
        const MenuItem(
          id: '2',
          name: 'Double Whopper',
          description: 'Flame-grilled beef with cheese and bacon.',
          price: 650.00,
          imageUrl:
              'https://via.placeholder.com/200x200/FF6B35/FFFFFF?text=Burger',
        ),
        const MenuItem(
          id: '3',
          name: 'Chicken Burger',
          description: 'Crispy chicken breast with lettuce and mayo.',
          price: 450.00,
          imageUrl:
              'https://via.placeholder.com/200x200/FF6B35/FFFFFF?text=Chicken',
        ),
      ]);

  void addMenuItem(MenuItem item) {
    state = [...state, item];
  }

  void toggleAvailability(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          MenuItem(
            id: item.id,
            name: item.name,
            description: item.description,
            price: item.price,
            imageUrl: item.imageUrl,
            isAvailable: !item.isAvailable,
          )
        else
          item,
    ];
  }
}

final menuProvider = StateNotifierProvider<MenuNotifier, List<MenuItem>>((ref) {
  return MenuNotifier();
});
