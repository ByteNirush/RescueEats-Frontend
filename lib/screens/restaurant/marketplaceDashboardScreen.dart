import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/marketplaceItemModel.dart';
import 'package:rescueeats/core/services/api_service.dart';
import 'package:intl/intl.dart';

// --- PROVIDER ---

final restaurantMarketplaceProvider =
    StateNotifierProvider<
      RestaurantMarketplaceNotifier,
      AsyncValue<List<MarketplaceItemModel>>
    >((ref) {
      return RestaurantMarketplaceNotifier(ApiService());
    });

class RestaurantMarketplaceNotifier
    extends StateNotifier<AsyncValue<List<MarketplaceItemModel>>> {
  final ApiService _apiService;

  RestaurantMarketplaceNotifier(this._apiService)
    : super(const AsyncValue.loading()) {
    fetchMyItems();
  }

  Future<void> fetchMyItems({String? availability}) async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.getMyMarketplaceItems(
        availability: availability,
      );

      final List<dynamic> itemsList = response['items'] ?? [];
      final items = itemsList
          .map((json) => MarketplaceItemModel.fromJson(json))
          .toList();

      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updateItem({
    required String itemId,
    double? discountPercent,
    String? availability,
  }) async {
    try {
      await _apiService.updateMarketplaceItem(
        itemId: itemId,
        discountPercent: discountPercent,
        availability: availability,
      );
      await fetchMyItems();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _apiService.deleteMarketplaceItem(itemId);
      await fetchMyItems();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// --- UI ---

class RestaurantMarketplaceDashboardScreen extends ConsumerStatefulWidget {
  const RestaurantMarketplaceDashboardScreen({super.key});

  @override
  ConsumerState<RestaurantMarketplaceDashboardScreen> createState() =>
      _RestaurantMarketplaceDashboardScreenState();
}

class _RestaurantMarketplaceDashboardScreenState
    extends ConsumerState<RestaurantMarketplaceDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _onTabChanged();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final index = _tabController.index;
    String? availability;
    switch (index) {
      case 0:
        availability = null; // all
        break;
      case 1:
        availability = 'available';
        break;
      case 2:
        availability = 'sold';
        break;
    }
    ref
        .read(restaurantMarketplaceProvider.notifier)
        .fetchMyItems(availability: availability);
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(restaurantMarketplaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Marketplace Items'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Available'),
            Tab(text: 'Sold'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(restaurantMarketplaceProvider.notifier).fetchMyItems();
            },
          ),
        ],
      ),
      body: itemsState.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No marketplace items yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cancel orders to add them to marketplace',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(restaurantMarketplaceProvider.notifier)
                  .fetchMyItems();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildMarketplaceItemCard(context, item);
              },
            ),
          );
        },
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(restaurantMarketplaceProvider.notifier)
                    .fetchMyItems(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildMarketplaceItemCard(
    BuildContext context,
    MarketplaceItemModel item,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    // Status badge color
    Color statusColor;
    IconData statusIcon;
    switch (item.availability) {
      case 'available':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'sold':
        statusColor = Colors.blue;
        statusIcon = Icons.shopping_bag;
        break;
      case 'expired':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  item.availability.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (item.isExpired && item.availability == 'available')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'EXPIRED',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),

            // Items
            Text(
              'Items:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...item.items.map(
              (orderItem) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('• ${orderItem.menuItemName}'),
                    const SizedBox(width: 8),
                    Text(
                      'x${orderItem.quantity}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pricing
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Original Price',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        'Rs. ${item.originalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discount',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '${item.discountPercent.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discounted Price',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        'Rs. ${item.discountedPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dates
            Text(
              'Canceled: ${dateFormat.format(item.canceledAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              'Expires: ${dateFormat.format(item.expiresAt)}',
              style: TextStyle(
                color: item.isExpired ? Colors.red : Colors.grey[600],
                fontSize: 12,
              ),
            ),

            if (item.cancelReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: ${item.cancelReason}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Actions
            if (item.availability == 'available') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditDiscountDialog(context, item),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Discount'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markAsStatus(context, item, 'sold'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Mark Sold'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markAsStatus(context, item, 'expired'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red[900],
                  ),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Mark Expired'),
                ),
              ),
            ],

            if (item.availability != 'available') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteItem(context, item),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDiscountDialog(
    BuildContext context,
    MarketplaceItemModel item,
  ) {
    final controller = TextEditingController(
      text: item.discountPercent.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Discount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Discount Percent',
            suffixText: '%',
            helperText: 'Enter value between 0-100',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value == null || value < 0 || value > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid discount (0-100)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final success = await ref
                  .read(restaurantMarketplaceProvider.notifier)
                  .updateItem(itemId: item.id, discountPercent: value);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Discount updated successfully'
                          : 'Failed to update discount',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _markAsStatus(
    BuildContext context,
    MarketplaceItemModel item,
    String status,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as ${status.toUpperCase()}?'),
        content: Text('Are you sure you want to mark this item as $status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref
          .read(restaurantMarketplaceProvider.notifier)
          .updateItem(itemId: item.id, availability: status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Item marked as $status' : 'Failed to update item',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _deleteItem(BuildContext context, MarketplaceItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text(
          'Are you sure you want to delete this marketplace item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref
          .read(restaurantMarketplaceProvider.notifier)
          .deleteItem(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Item deleted successfully' : 'Failed to delete item',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
