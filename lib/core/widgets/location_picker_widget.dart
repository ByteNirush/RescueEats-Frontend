import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rescueeats/core/appTheme/appColors.dart';

class LocationPickerWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoading = true;
  String? _errorMessage;

  // Default location (Kathmandu, Nepal)
  static const LatLng _defaultLocation = LatLng(27.7172, 85.3240);

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _selectedLocation = _selectedLocation ?? _defaultLocation;
          _isLoading = false;
          _errorMessage =
              'Location services are disabled. Using default location.';
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _selectedLocation = _selectedLocation ?? _defaultLocation;
            _isLoading = false;
            _errorMessage =
                'Location permission denied. Using default location.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _selectedLocation = _selectedLocation ?? _defaultLocation;
          _isLoading = false;
          _errorMessage =
              'Location permission denied permanently. Please enable in settings.';
        });
        return;
      }

      // Get current position
      if (_selectedLocation == null) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedLocation = _selectedLocation ?? _defaultLocation;
        _isLoading = false;
        _errorMessage = 'Error getting location: ${e.toString()}';
      });
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _onMyLocationPressed() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLocation;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLocation, 15),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Location',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _selectedLocation != null
                ? () {
                    widget.onLocationSelected(_selectedLocation!);
                    Navigator.pop(context);
                  }
                : null,
            child: Text(
              'DONE',
              style: TextStyle(
                color: _selectedLocation != null
                    ? AppColors.primary
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? _defaultLocation,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _onMapTapped,
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: _selectedLocation!,
                            draggable: true,
                            onDragEnd: (newPosition) {
                              setState(() {
                                _selectedLocation = newPosition;
                              });
                            },
                          ),
                        }
                      : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                // Info card at top
                if (_errorMessage != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Colors.orange[100],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Instructions card at bottom
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tap on the map or drag the marker to select your restaurant location',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedLocation != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                              'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // My location button
                Positioned(
                  bottom: 120,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _onMyLocationPressed,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
