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

    // Optimistically update UI - preserve ALL fields
    state = state.whenData((orders) {
      return [
        for (final order in orders)
          if (order.id == orderId)
            OrderModel(
              id: order.id,
              customerId: order.customerId,
              customerName: order.customerName,
              restaurantId: order.restaurantId,
              restaurantName: order.restaurantName,
              restaurantImage: order.restaurantImage,
              deliveryAddress: order.deliveryAddress,
              contactPhone: order.contactPhone,
              totalAmount: order.totalAmount,
              deliveryCharge: order.deliveryCharge,
              items: order.items,
              status: newStatus, // New Status
              createdAt: order.createdAt,
              paymentMethod: order.paymentMethod,
              orderType: order.orderType,
              isCanceled: order.isCanceled,
              originalPrice: order.originalPrice,
              discountPercent: order.discountPercent,
              discountedPrice: order.discountedPrice,
              canceledAt: order.canceledAt,
              cancelReason: order.cancelReason,
              coinsUsed: order.coinsUsed,
              coinDiscount: order.coinDiscount,
              rating: order.rating,
              review: order.review,
              ratedAt: order.ratedAt,
            )
          else
            order,
      ];
    });

    try {
      // Call Backend
      await _repository.updateOrderStatus(orderId, newStatus);
      // Refresh from server to get the actual state
      await fetchOrders();
    } catch (e) {
      // If backend fails, rollback UI and show error
      state = previousState;
      rethrow; // Rethrow so UI can show error message
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

  // 4. Cancel Order (NO discount here - discount is applied in Marketplace)
  Future<void> cancelOrder(String orderId, {String? cancelReason}) async {
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
      await _repository.cancelOrder(orderId, cancelReason: cancelReason);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  // 5. Rate Order with item ratings
  Future<Map<String, dynamic>> rateOrder(
    String orderId,
    int rating,
    String review, {
    List<Map<String, dynamic>>? itemRatings,
  }) async {
    try {
      final result = await _repository.rateOrder(
        orderId,
        rating,
        review,
        itemRatings: itemRatings,
      );
      // Refresh to get updated order with rating
      await fetchOrders();
      return result;
    } catch (e) {
      rethrow;
    }
  }
}

// THE PROVIDER TO USE IN UI
// Using autoDispose to ensure orders are refetched when user changes
final orderControllerProvider =
    StateNotifierProvider.autoDispose<
      OrderController,
      AsyncValue<List<OrderModel>>
    >((ref) {
      final repository = ref.watch(orderRepositoryProvider);
      return OrderController(repository);
    });
