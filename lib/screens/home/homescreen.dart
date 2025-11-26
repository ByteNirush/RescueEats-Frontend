import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/core/model/userModel.dart';
import 'package:rescueeats/screens/admin/adminDashboard.dart';
import 'package:rescueeats/screens/auth/provider/authprovider.dart';
import 'package:rescueeats/screens/delivery/deliveryScreen.dart';
import 'package:rescueeats/screens/restaurant/restaurantScreen.dart';
import 'package:rescueeats/screens/user/customerScreen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // DISPATCHER LOGIC: Check Role -> Show Screen
    switch (user.role) {
      case UserRole.restaurant:
        return const RestaurantDashboard();
      case UserRole.delivery:
        return const DeliveryDashboard();
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.user:
        return const CustomerDashboard();
    }
  }
}
