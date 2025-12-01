import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/orderModel.dart';
import 'package:rescueeats/core/services/api_service.dart';
import 'package:rescueeats/screens/order/orderDetailScreen.dart';

// --- PROVIDER ---

final canceledOrdersProvider =
    StateNotifierProvider<CanceledOrdersNotifier, AsyncValue<List<OrderModel>>>(
      (ref) {
        return CanceledOrdersNotifier(ApiService());
      },
    );

class CanceledOrdersNotifier
    extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final ApiService _apiService;

  CanceledOrdersNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchOrders();
  }

  Future<void> fetchOrders({
    String? cuisine,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      state = const AsyncValue.loading();
      final orders = await _apiService.getCanceledOrders(
        cuisine: cuisine,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// --- UI ---

class CanceledOrdersScreen extends ConsumerStatefulWidget {
  const CanceledOrdersScreen({super.key});

  @override
  ConsumerState<CanceledOrdersScreen> createState() =>
      _CanceledOrdersScreenState();
}

class _CanceledOrdersScreenState extends ConsumerState<CanceledOrdersScreen> {
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(canceledOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescue Food Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: ordersState.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text('No canceled orders available to rescue right now.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order);
            },
          );
        },
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err'),
              ElevatedButton(
                onPressed: () =>
                    ref.read(canceledOrdersProvider.notifier).fetchOrders(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.restaurantName.isNotEmpty
                          ? order.restaurantName
                          : 'Restaurant',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${order.discountPercent.toStringAsFixed(0)}% OFF',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${order.items.length} items • ${order.cancelReason}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rs. ${order.originalPrice?.toStringAsFixed(2)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Rs. ${order.discountedPrice?.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailScreen(order: order),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Rescue Now'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Orders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _minPriceController,
              decoration: const InputDecoration(labelText: 'Min Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _maxPriceController,
              decoration: const InputDecoration(labelText: 'Max Price'),
              keyboardType: TextInputType.number,
            ),
            // Add Cuisine Dropdown if needed
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _minPriceController.clear();
              _maxPriceController.clear();
              ref.read(canceledOrdersProvider.notifier).fetchOrders();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(canceledOrdersProvider.notifier)
                  .fetchOrders(
                    minPrice: double.tryParse(_minPriceController.text),
                    maxPrice: double.tryParse(_maxPriceController.text),
                  );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
