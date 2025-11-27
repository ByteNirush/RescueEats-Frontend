import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/addressModel.dart';
import 'package:rescueeats/core/services/api_service.dart';

final addressProvider =
    StateNotifierProvider<AddressNotifier, AsyncValue<List<AddressModel>>>((
      ref,
    ) {
      return AddressNotifier(ApiService());
    });

class AddressNotifier extends StateNotifier<AsyncValue<List<AddressModel>>> {
  final ApiService _apiService;

  AddressNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    try {
      state = const AsyncValue.loading();
      final addresses = await _apiService.getAddresses();
      state = AsyncValue.data(addresses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAddress(AddressModel address) async {
    try {
      // Optimistic update or loading? Let's do loading for safety
      state = const AsyncValue.loading();
      final addresses = await _apiService.addAddress(address);
      state = AsyncValue.data(addresses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateAddress(AddressModel address) async {
    try {
      state = const AsyncValue.loading();
      final addresses = await _apiService.updateAddress(address);
      state = AsyncValue.data(addresses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      state = const AsyncValue.loading();
      final addresses = await _apiService.deleteAddress(addressId);
      state = AsyncValue.data(addresses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
