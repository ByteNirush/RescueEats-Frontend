import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rescueeats/core/appTheme/appColors.dart';
import 'package:rescueeats/core/model/menuItemModel.dart';
import 'package:rescueeats/screens/restaurant/provider/menuProvider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditMenuItemScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final MenuItemModel? menuItem;

  const EditMenuItemScreen({
    super.key,
    required this.restaurantId,
    this.menuItem,
  });

  @override
  ConsumerState<EditMenuItemScreen> createState() => _EditMenuItemScreenState();
}

class _EditMenuItemScreenState extends ConsumerState<EditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageController;
  bool _isAvailable = true;
  bool _isVeg = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menuItem?.name ?? '');
    _priceController = TextEditingController(
      text: widget.menuItem?.price.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.menuItem?.description ?? '',
    );
    _imageController = TextEditingController(
      text: widget.menuItem?.image ?? '',
    );
    _isAvailable = widget.menuItem?.isAvailable ?? true;
    _isVeg = widget.menuItem?.isVeg ?? false;

    // Add listener to rebuild when image URL changes
    _imageController.addListener(() {
      setState(() {}); // Trigger rebuild to show image preview
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'image': _imageController.text,
        'isAvailable': _isAvailable,
        'isVeg': _isVeg,
      };

      if (widget.menuItem != null) {
        // Update
        await ref
            .read(menuProvider.notifier)
            .updateMenuItem(widget.restaurantId, widget.menuItem!.id, data);
      } else {
        // Add
        await ref
            .read(menuProvider.notifier)
            .addMenuItem(widget.restaurantId, data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.menuItem != null
                  ? 'Item updated successfully'
                  : 'Item added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.menuItem != null ? "Edit Item" : "Add Item",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _nameController,
                label: "Item Name",
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: "Price (Rs.)",
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.isEmpty) return "Required";
                  if (double.tryParse(v) == null) return "Invalid number";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: "Description",
                maxLines: 3,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _imageController,
                label: "Image URL",
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              if (_imageController.text.trim().isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? _buildWebImagePreview()
                        : CachedNetworkImage(
                            imageUrl: _imageController.text.trim(),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[100],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text("Available"),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
                activeThumbColor: AppColors.primary,
              ),
              SwitchListTile(
                title: const Text("Vegetarian"),
                value: _isVeg,
                onChanged: (v) => setState(() => _isVeg = v),
                activeThumbColor: Colors.green,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.menuItem != null ? "Update Item" : "Add Item",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebImagePreview() {
    // For web, show a helpful message instead of trying to load the image
    // This avoids CORS issues with external image sources
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Image Preview',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Preview not available on web due to CORS',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Image will display correctly in mobile app',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
