import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/core/services/api_service.dart';
import 'package:rescueeats/core/model/game/daily_task.dart';

// 1. Define the Interface (Contract)
// 1. Define the Interface (Contract)
abstract class IOrderRepository {
  Future<List<OrderModel>> fetchOrders();
  Future<OrderModel> getOrderById(String id);
  Future<void> updateOrderStatus(String orderId, String status);
  Future<OrderModel> placeOrder(OrderModel order);
  Future<void> cancelOrder(String orderId);
}

// 2. Implement the Real Repository
class OrderRepository implements IOrderRepository {
  final ApiService _apiService;

  OrderRepository(this._apiService);

  @override
  Future<List<OrderModel>> fetchOrders() async {
    return await _apiService.getOrders();
  }

  @override
  Future<OrderModel> getOrderById(String id) async {
    return await _apiService.getOrderById(id);
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _apiService.updateOrderStatus(orderId, status);
  }

  @override
  Future<OrderModel> placeOrder(OrderModel order) async {
    final createdOrder = await _apiService.createOrder(order);
    // Complete the "Rescue a Meal" daily task
    await DailyTaskManager.completeTask(TaskType.rescueMeal);
    return createdOrder;
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    await _apiService.cancelOrder(orderId);
  }
}

// 3. Providers
final apiServiceProvider = Provider((ref) => ApiService());

final orderRepositoryProvider = Provider<IOrderRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return OrderRepository(api);
});
