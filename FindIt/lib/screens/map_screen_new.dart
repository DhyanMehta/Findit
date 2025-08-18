import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firebase_item_service.dart';
import '../models/item.dart';
import 'item_details_screen.dart';
import 'post_item_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  final _itemService = FirebaseItemService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. Enable it in settings.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          16,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Set<Marker> _buildMarkers(List<Item> items) {
    return items
        .where((item) {
          // Only show items that have valid coordinates
          return item.latitude != 0.0 && item.longitude != 0.0;
        })
        .map((item) {
          return Marker(
            markerId: MarkerId(item.id),
            position: LatLng(item.latitude, item.longitude),
            infoWindow: InfoWindow(
              title: item.title,
              snippet:
                  '${item.type == 'found' ? 'Found' : 'Lost'} • ${item.location}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailsScreen(item: item),
                  ),
                );
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              item.type == 'found'
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
          );
        })
        .toSet();
  }

  void _goToCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16,
        ),
      );
    } else {
      _getCurrentLocation();
    }
  }

  void _addNewItem() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostItemScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultLocation = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(
            37.4275,
            -122.1697,
          ); // Default to a location (Mountain View, CA)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.my_location),
            onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
            tooltip: 'My Location',
          ),
        ],
      ),
      body: StreamBuilder<List<Item>>(
        stream: _itemService.getAllItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading items',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your internet connection and try again',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Rebuild to retry
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];
          final itemsWithLocation = items
              .where((item) => item.latitude != 0.0 && item.longitude != 0.0)
              .toList();

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: defaultLocation,
                  zoom: 12,
                ),
                markers: _buildMarkers(items),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_currentPosition != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        16,
                      ),
                    );
                  }
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
                compassEnabled: true,
              ),

              // Items counter
              if (snapshot.connectionState != ConnectionState.waiting)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${itemsWithLocation.length} items on map',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Loading indicator
              if (snapshot.connectionState == ConnectionState.waiting)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading items...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

              // Filter buttons
              if (snapshot.connectionState != ConnectionState.waiting)
                Positioned(
                  bottom: 80,
                  left: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'lost',
                        onPressed: () {
                          final lostItems = items
                              .where(
                                (item) =>
                                    item.type == 'lost' &&
                                    item.latitude != 0.0 &&
                                    item.longitude != 0.0,
                              )
                              .toList();

                          if (lostItems.isNotEmpty) {
                            // Fit all lost items in view
                            final bounds = _calculateBounds(lostItems);
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngBounds(bounds, 50),
                            );
                          }
                        },
                        backgroundColor: Colors.red,
                        tooltip: 'Show Lost Items',
                        child: const Icon(
                          Icons.help_outline,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'found',
                        onPressed: () {
                          final foundItems = items
                              .where(
                                (item) =>
                                    item.type == 'found' &&
                                    item.latitude != 0.0 &&
                                    item.longitude != 0.0,
                              )
                              .toList();

                          if (foundItems.isNotEmpty) {
                            // Fit all found items in view
                            final bounds = _calculateBounds(foundItems);
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngBounds(bounds, 50),
                            );
                          }
                        },
                        backgroundColor: Colors.green,
                        tooltip: 'Show Found Items',
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewItem,
        backgroundColor: Colors.blue,
        tooltip: 'Add Item',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  LatLngBounds _calculateBounds(List<Item> items) {
    if (items.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(37.4275, -122.1697),
        northeast: const LatLng(37.4275, -122.1697),
      );
    }

    double minLat = items.first.latitude;
    double maxLat = items.first.latitude;
    double minLng = items.first.longitude;
    double maxLng = items.first.longitude;

    for (final item in items) {
      minLat = minLat < item.latitude ? minLat : item.latitude;
      maxLat = maxLat > item.latitude ? maxLat : item.latitude;
      minLng = minLng < item.longitude ? minLng : item.longitude;
      maxLng = maxLng > item.longitude ? maxLng : item.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
