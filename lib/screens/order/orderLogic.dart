import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/screens/order/repository/orderRepository.dart';

// We use AsyncNotifier for production-grade async state management
class OrderController extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final IOrderRepository _repository;

  OrderController(this._repository) : super(const AsyncValue.loading()) {
    fetchOrders();
  }

  // 1. Fetch Orders (Initial Load)
  Future<void> fetchOrders() async {
    try {
      state = const AsyncValue.loading();
      final orders = await _repository.fetchOrders();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 2. Update Order Status (Optimistic Update)
  // "Optimistic" means we update the UI immediately for a snappy feel,
  // then rollback if the server fails.
  Future<void> updateStatus(String orderId, String newStatus) async {
    final previousState = state; // Save copy for rollback

    // Optimistically update UI
    state = state.whenData((orders) {
      return [
        for (final order in orders)
          if (order.id == orderId)
            OrderModel(
              id: order.id,
              restaurantId: order.restaurantId,
              restaurantName: order.restaurantName,
              restaurantImage: order.restaurantImage,
              deliveryAddress: order.deliveryAddress,
              contactPhone: order.contactPhone,
              totalAmount: order.totalAmount,
              items: order.items,
              status: newStatus, // New Status
              createdAt: order.createdAt,
              paymentMethod: order.paymentMethod,
            )
          else
            order,
      ];
    });

    try {
      // Call Backend
      await _repository.updateOrderStatus(orderId, newStatus);
    } catch (e) {
      // If backend fails, rollback UI and show error
      state = previousState;
      // In a real app, you might expose a separate error stream for snackbars
    }
  }

  // 3. Place Order
  Future<void> placeOrder(OrderModel order) async {
    try {
      await _repository.placeOrder(order);
      // Refresh list from server to get the true state/ID
      await fetchOrders();
    } catch (e) {
      // Handle error - maybe rethrow to let UI know
      rethrow;
    }
  }

  // 4. Cancel Order
  Future<void> cancelOrder(String orderId) async {
    final previousState = state;
    // Optimistic update
    state = state.whenData((orders) {
      return [
        for (final order in orders)
          if (order.id == orderId)
            OrderModel(
              id: order.id,
              restaurantId: order.restaurantId,
              restaurantName: order.restaurantName,
              restaurantImage: order.restaurantImage,
              deliveryAddress: order.deliveryAddress,
              contactPhone: order.contactPhone,
              totalAmount: order.totalAmount,
              items: order.items,
              status: 'cancelled',
              createdAt: order.createdAt,
              paymentMethod: order.paymentMethod,
            )
          else
            order,
      ];
    });

    try {
      await _repository.cancelOrder(orderId);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}

// THE PROVIDER TO USE IN UI
final orderControllerProvider =
    StateNotifierProvider<OrderController, AsyncValue<List<OrderModel>>>((ref) {
      final repository = ref.watch(orderRepositoryProvider);
      return OrderController(repository);
    });
