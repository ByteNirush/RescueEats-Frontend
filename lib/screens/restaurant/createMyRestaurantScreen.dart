import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/services/restaurantApiService.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/core/widgets/location_picker_widget.dart';
import 'package:rescueeats/screens/auth/provider/authprovider.dart';
import 'package:rescueeats/screens/restaurant/provider/restaurant_provider.dart';
import 'package:rescueeats/screens/restaurant/provider/restaurant_provider.dart';

class CreateMyRestaurantScreen extends ConsumerStatefulWidget {
  const CreateMyRestaurantScreen({super.key});

  @override
  ConsumerState<CreateMyRestaurantScreen> createState() =>
      _CreateMyRestaurantScreenState();
}

class _CreateMyRestaurantScreenState
    extends ConsumerState<CreateMyRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imageController = TextEditingController();
  final _openingTimeController = TextEditingController(text: "10:00 AM");
  final _closingTimeController = TextEditingController(text: "10:00 PM");

  // Cuisines handling
  final _cuisineController = TextEditingController();
  final List<String> _selectedCuisines = [];

  // Location handling
  LatLng? _selectedLocation;

  bool _isLoading = false;
  final _apiService = RestaurantApiService();

  @override
  void initState() {
    super.initState();
    // Pre-fill phone number from user signup data
    final user = ref.read(currentUserProvider);
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      _phoneController.text = user.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _imageController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    _cuisineController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCuisines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one cuisine')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        // Backend automatically uses ownerId from JWT token
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'cuisines': _selectedCuisines,
        'image': _imageController.text.trim(),
        'openingTime': _openingTimeController.text.trim(),
        'closingTime': _closingTimeController.text.trim(),
        if (_selectedLocation != null) 'latitude': _selectedLocation!.latitude,
        if (_selectedLocation != null)
          'longitude': _selectedLocation!.longitude,
      };

      await _apiService.createMyRestaurant(data);

      // Update the restaurant provider with the new restaurant
      await ref.read(restaurantOwnerProvider.notifier).fetchMyRestaurant();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addCuisine() {
    final cuisine = _cuisineController.text.trim();
    if (cuisine.isNotEmpty && !_selectedCuisines.contains(cuisine)) {
      setState(() {
        _selectedCuisines.add(cuisine);
        _cuisineController.clear();
      });
    }
  }

  void _removeCuisine(String cuisine) {
    setState(() {
      _selectedCuisines.remove(cuisine);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Create Your Restaurant',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.padding.medium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can create one restaurant. Fill in the details below to get started!',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Restaurant Name',
                icon: Icons.store,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Contact & Location'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              // Map Location Picker
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.map,
                    color: _selectedLocation != null
                        ? AppColors.primary
                        : Colors.grey[600],
                  ),
                  title: Text(
                    _selectedLocation != null
                        ? 'Location Selected'
                        : 'Select Location on Map',
                    style: TextStyle(
                      color: _selectedLocation != null
                          ? Colors.black87
                          : Colors.grey[700],
                      fontWeight: _selectedLocation != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: _selectedLocation != null
                      ? Text(
                          'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                          'Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        )
                      : const Text(
                          'Tap to pick your restaurant location',
                          style: TextStyle(fontSize: 12),
                        ),
                  trailing: Icon(
                    _selectedLocation != null
                        ? Icons.check_circle
                        : Icons.arrow_forward_ios,
                    color: _selectedLocation != null
                        ? Colors.green
                        : Colors.grey[400],
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPickerWidget(
                          initialLocation: _selectedLocation,
                          onLocationSelected: (location) {
                            setState(() {
                              _selectedLocation = location;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Details'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _openingTimeController,
                      label: 'Opening Time',
                      icon: Icons.access_time,
                      hint: "10:00 AM",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _closingTimeController,
                      label: 'Closing Time',
                      icon: Icons.access_time_filled,
                      hint: "10:00 PM",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _imageController,
                label: 'Image URL (Optional)',
                icon: Icons.image,
                hint: "https://example.com/image.jpg",
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Cuisines'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cuisineController,
                      label: 'Add Cuisine',
                      icon: Icons.restaurant_menu,
                      onSubmitted: (_) => _addCuisine(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _addCuisine,
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedCuisines.map((cuisine) {
                  return Chip(
                    label: Text(cuisine),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeCuisine(cuisine),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: const TextStyle(color: AppColors.primary),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Restaurant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
