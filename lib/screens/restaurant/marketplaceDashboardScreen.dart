import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/marketplaceItemModel.dart';
import 'package:rescueeats/core/services/api_service.dart';
import 'package:intl/intl.dart';

// --- PROVIDERS ---

// Provider for PENDING DISCOUNT items (Marketplace screen)
final pendingDiscountProvider =
    StateNotifierProvider<
      PendingDiscountNotifier,
      AsyncValue<List<MarketplaceItemModel>>
    >((ref) {
      return PendingDiscountNotifier(ApiService());
    });

// Provider for DISCOUNTED items (Canceled Dashboard)
final discountedItemsProvider =
    StateNotifierProvider<
      DiscountedItemsNotifier,
      AsyncValue<List<MarketplaceItemModel>>
    >((ref) {
      return DiscountedItemsNotifier(ApiService());
    });

class PendingDiscountNotifier
    extends StateNotifier<AsyncValue<List<MarketplaceItemModel>>> {
  final ApiService _apiService;

  PendingDiscountNotifier(this._apiService)
    : super(const AsyncValue.loading()) {
    fetchPendingItems();
  }

  Future<void> fetchPendingItems() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.getPendingDiscountItems();

      final List<dynamic> itemsList = response['items'] ?? [];
      final items = itemsList
          .map((json) => MarketplaceItemModel.fromJson(json))
          .toList();

      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> applyDiscount({
    required String itemId,
    required double discountPercent,
  }) async {
    try {
      await _apiService.applyDiscountToMarketplaceItem(
        itemId: itemId,
        discountPercent: discountPercent,
      );
      await fetchPendingItems();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _apiService.deleteMarketplaceItem(itemId);
      await fetchPendingItems();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class DiscountedItemsNotifier
    extends StateNotifier<AsyncValue<List<MarketplaceItemModel>>> {
  final ApiService _apiService;

  DiscountedItemsNotifier(this._apiService)
    : super(const AsyncValue.loading()) {
    fetchDiscountedItems();
  }

  Future<void> fetchDiscountedItems({String? availability}) async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.getDiscountedItems(
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
      await fetchDiscountedItems();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _apiService.deleteMarketplaceItem(itemId);
      await fetchDiscountedItems();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Legacy provider for backward compatibility
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

// --- MAIN SCREEN WITH TABS ---

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canceled Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Add Discount'),
            Tab(icon: Icon(Icons.check_circle), text: 'Canceled Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(pendingDiscountProvider.notifier).fetchPendingItems();
              ref.read(discountedItemsProvider.notifier).fetchDiscountedItems();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_PendingDiscountTab(), _CanceledDashboardTab()],
      ),
    );
  }
}

// --- PENDING DISCOUNT TAB (Add Discount) ---

class _PendingDiscountTab extends ConsumerWidget {
  const _PendingDiscountTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(pendingDiscountProvider);

    return itemsState.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending orders',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Canceled orders will appear here for discount',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(pendingDiscountProvider.notifier)
                .fetchPendingItems();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _PendingItemCard(item: item);
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
                  .read(pendingDiscountProvider.notifier)
                  .fetchPendingItems(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _PendingItemCard extends ConsumerWidget {
  final MarketplaceItemModel item;

  const _PendingItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with pending badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pending_actions,
                        color: Colors.orange[700],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PENDING DISCOUNT',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(item.canceledAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),

            // Customer info
            if (item.customerName != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.customerName!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (item.customerPhone != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      item.customerPhone!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Items
            const Text(
              'Items:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                    const Spacer(),
                    Text(
                      'Rs. ${(orderItem.price * orderItem.quantity).toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Original Price
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Original Price:', style: TextStyle(fontSize: 16)),
                  Text(
                    'Rs. ${item.originalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (item.cancelReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Reason: ${item.cancelReason}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Apply Discount Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _showApplyDiscountDialog(context, ref, item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.local_offer, color: Colors.white),
                label: const Text(
                  'Add Discount & Move to Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _deleteItem(context, ref, item),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplyDiscountDialog(
    BuildContext context,
    WidgetRef ref,
    MarketplaceItemModel item,
  ) {
    final controller = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_offer, color: Colors.green),
            SizedBox(width: 12),
            Text('Apply Discount'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original Price: Rs. ${item.originalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.items.length} item(s)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Discount Percent',
                suffixText: '%',
                helperText: 'Enter value between 1-100',
                prefixIcon: const Icon(Icons.percent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setState) {
                final discount = double.tryParse(controller.text) ?? 0;
                final discountedPrice =
                    item.originalPrice - (item.originalPrice * discount / 100);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Final Price:'),
                      Text(
                        'Rs. ${discountedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value == null || value < 1 || value > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid discount (1-100)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final success = await ref
                  .read(pendingDiscountProvider.notifier)
                  .applyDiscount(itemId: item.id, discountPercent: value);

              // Also refresh the discounted items
              ref.read(discountedItemsProvider.notifier).fetchDiscountedItems();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            success
                                ? 'Discount applied! Moved to Canceled Dashboard.'
                                : 'Failed to apply discount',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Apply Discount',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteItem(
    BuildContext context,
    WidgetRef ref,
    MarketplaceItemModel item,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text(
          'This will permanently remove the canceled order. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await ref
          .read(pendingDiscountProvider.notifier)
          .deleteItem(item.id);

      if (context.mounted) {
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

// --- CANCELED DASHBOARD TAB (Final List) ---

class _CanceledDashboardTab extends ConsumerStatefulWidget {
  const _CanceledDashboardTab();

  @override
  ConsumerState<_CanceledDashboardTab> createState() =>
      _CanceledDashboardTabState();
}

class _CanceledDashboardTabState extends ConsumerState<_CanceledDashboardTab> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(discountedItemsProvider);

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Available', 'available'),
              const SizedBox(width: 8),
              _buildFilterChip('Sold', 'sold'),
              const SizedBox(width: 8),
              _buildFilterChip('Expired', 'expired'),
            ],
          ),
        ),
        Expanded(
          child: itemsState.when(
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
                        'No discounted items yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Apply discounts in "Add Discount" tab',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(discountedItemsProvider.notifier)
                      .fetchDiscountedItems(
                        availability: _selectedFilter == 'all'
                            ? null
                            : _selectedFilter,
                      );
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _DiscountedItemCard(item: item);
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
                        .read(discountedItemsProvider.notifier)
                        .fetchDiscountedItems(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        ref
            .read(discountedItemsProvider.notifier)
            .fetchDiscountedItems(availability: value == 'all' ? null : value);
      },
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green[800],
    );
  }
}

class _DiscountedItemCard extends ConsumerWidget {
  final MarketplaceItemModel item;

  const _DiscountedItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        item.availability.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${item.discountPercent.toStringAsFixed(0)}% OFF',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
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
            const Text(
              'Items:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                        'Original',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        'Rs. ${item.originalPrice.toStringAsFixed(0)}',
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
                        '${item.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.orange,
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
                        'Final Price',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        'Rs. ${item.discountedPrice.toStringAsFixed(0)}',
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
            const SizedBox(height: 12),

            // Dates
            if (item.discountAppliedAt != null)
              Text(
                'Discount applied: ${dateFormat.format(item.discountAppliedAt!)}',
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
                      onPressed: () => _editDiscount(context, ref, item),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Discount'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _markAsStatus(context, ref, item, 'sold'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      icon: const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Mark Sold',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (item.availability != 'available') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteItem(context, ref, item),
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

  void _editDiscount(
    BuildContext context,
    WidgetRef ref,
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
                  .read(discountedItemsProvider.notifier)
                  .updateItem(itemId: item.id, discountPercent: value);

              if (context.mounted) {
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
    WidgetRef ref,
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

    if (confirm == true && context.mounted) {
      final success = await ref
          .read(discountedItemsProvider.notifier)
          .updateItem(itemId: item.id, availability: status);

      if (context.mounted) {
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

  void _deleteItem(
    BuildContext context,
    WidgetRef ref,
    MarketplaceItemModel item,
  ) async {
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
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await ref
          .read(discountedItemsProvider.notifier)
          .deleteItem(item.id);

      if (context.mounted) {
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
