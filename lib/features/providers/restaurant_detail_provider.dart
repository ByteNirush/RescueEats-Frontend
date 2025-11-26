import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/menuItemModel.dart';
import 'package:rescueeats/core/model/restaurantModel.dart';

import 'package:rescueeats/features/providers/explore_provider.dart';

final restaurantDetailsProvider =
    FutureProvider.family<RestaurantModel, String>((ref, restaurantId) async {
      final apiService = ref.watch(apiServiceProvider);
      return apiService.getRestaurantById(restaurantId);
    });

final restaurantMenuProvider =
    FutureProvider.family<List<MenuItemModel>, String>((
      ref,
      restaurantId,
    ) async {
      final apiService = ref.watch(apiServiceProvider);
      return apiService.getRestaurantMenu(restaurantId);
    });
