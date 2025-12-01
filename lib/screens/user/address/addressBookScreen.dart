import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescueeats/screens/user/address/addEditAddressScreen.dart';
import 'package:rescueeats/screens/user/address/addressNotifier.dart';

class AddressBookScreen extends ConsumerWidget {
  final bool selectMode;

  const AddressBookScreen({super.key, this.selectMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressState = ref.watch(addressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      body: addressState.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return const Center(child: Text('No addresses found. Add one!'));
          }
          return ListView.builder(
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    address.label.toLowerCase() == 'work'
                        ? Icons.work
                        : Icons.home,
                    color: Colors.green,
                  ),
                  title: Text(
                    address.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${address.street}, ${address.city}\n${address.landmark}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (address.isDefault)
                        const Chip(
                          label: Text(
                            'Default',
                            style: TextStyle(fontSize: 10),
                          ),
                          backgroundColor: Colors.greenAccent,
                        ),
                      if (!selectMode)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditAddressScreen(address: address),
                              ),
                            );
                          },
                        ),
                      if (!selectMode)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _confirmDelete(context, ref, address.id!);
                          },
                        ),
                    ],
                  ),
                  onTap: selectMode
                      ? () {
                          Navigator.pop(context, address);
                        }
                      : null,
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditAddressScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String addressId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(addressProvider.notifier).deleteAddress(addressId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
