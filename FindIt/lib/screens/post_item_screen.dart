import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../services/firebase_auth_service.dart';
import '../services/firebase_item_service.dart';
import '../models/item.dart';
import '../utils/error_handler.dart';

class PostItemScreen extends StatefulWidget {
  const PostItemScreen({super.key});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactDetailsController = TextEditingController();
  final _extraInputController = TextEditingController();
  final _authService = FirebaseAuthService();
  final _itemService = FirebaseItemService();

  // Category removed
  // ignore: unused_field
  final String _category = '';
  String? _imageUrl;
  DateTime? _dateTime;
  // ignore: unused_field
  final String _contactMethod = 'In-app chat';
  String _itemType = 'lost'; // 'lost' or 'found'
  bool _isLoading = false;
  bool _isLocationLoading = false;
  double? _selectedLatitude;
  double? _selectedLongitude;

  // ignore: unused_field
  final List<String> _categories = const [];

  // ignore: unused_field
  final List<String> _contactMethods = const ['In-app chat'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactDetailsController.dispose();
    _extraInputController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _locationController.text =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });
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
        setState(() => _isLocationLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // For now, we'll just store the path
        // In a full implementation, you'd upload to Firebase Storage
        setState(() {
          _imageUrl = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageUrl = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _dateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to post an item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image to Cloudinary if selected
      String imageUrlToSave = '';
      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        final file = File(_imageUrl!);
        if (await file.exists()) {
          imageUrlToSave = await CloudinaryService().uploadImage(file);
        }
      }

      // Parse coordinates if they were set by GPS
      double latitude = _selectedLatitude ?? 0.0;
      double longitude = _selectedLongitude ?? 0.0;

      // Try to parse coordinates from location text if GPS wasn't used
      if (latitude == 0.0 && longitude == 0.0) {
        final locationText = _locationController.text.trim();
        final coordinateRegex = RegExp(r'(-?\d+\.?\d*),\s*(-?\d+\.?\d*)');
        final match = coordinateRegex.firstMatch(locationText);

        if (match != null) {
          latitude = double.tryParse(match.group(1) ?? '') ?? 0.0;
          longitude = double.tryParse(match.group(2) ?? '') ?? 0.0;
        }
      }

      final item = Item(
        id: '', // Will be generated by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: '',
        location: _locationController.text.trim(),
        dateTime: _dateTime ?? DateTime.now(),
        contactMethod: 'In-app chat',
        imageUrl: imageUrlToSave,
        userId: currentUser.uid,
        isFound: _itemType == 'found',
        latitude: latitude,
        longitude: longitude,
        status: 'active',
        type: _itemType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _itemService.createItem(item);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _itemType == 'lost'
                  ? 'Lost item posted successfully!'
                  : 'Found item posted successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _itemType == 'lost' ? 'Report Lost Item' : 'Report Found Item',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selection
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // Title Field
              _buildTitleField(),
              const SizedBox(height: 16),

              // Description Field
              _buildDescriptionField(),
              const SizedBox(height: 16),

              // Extra input field
              _buildExtraInputField(),
              const SizedBox(height: 16),

              // Location Field
              _buildLocationField(),
              const SizedBox(height: 16),

              // Date/Time Selection
              _buildDateTimeSelector(),
              const SizedBox(height: 16),

              // Image Selection
              _buildImageSelector(),
              const SizedBox(height: 16),

              // Contact Method (forced to in-app chat)
              _buildForcedInAppContact(),
              const SizedBox(height: 16),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Item Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Lost'),
                    subtitle: const Text('I lost this item'),
                    value: 'lost',
                    groupValue: _itemType,
                    onChanged: (value) {
                      setState(() {
                        _itemType = value!;
                      });
                    },
                    activeColor: Colors.red,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Found'),
                    subtitle: const Text('I found this item'),
                    value: 'found',
                    groupValue: _itemType,
                    onChanged: (value) {
                      setState(() {
                        _itemType = value!;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Item Title',
        hintText: _itemType == 'lost'
            ? 'What did you lose?'
            : 'What did you find?',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an item title';
        }
        if (value.trim().length < 3) {
          return 'Title must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: _itemType == 'lost'
            ? 'Describe the lost item in detail...'
            : 'Describe the found item in detail...',
        prefixIcon: const Icon(Icons.description),
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        if (value.trim().length < 10) {
          return 'Description must be at least 10 characters';
        }
        return null;
      },
    );
  }

  Widget _buildExtraInputField() {
    return TextFormField(
      controller: _extraInputController,
      decoration: InputDecoration(
        labelText: 'Additional details (optional)',
        hintText: 'Any extra info you want to add',
        prefixIcon: const Icon(Icons.info_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: 2,
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'Location',
        hintText: _itemType == 'lost'
            ? 'Where did you lose it?'
            : 'Where did you find it?',
        prefixIcon: const Icon(Icons.location_on),
        suffixIcon: IconButton(
          icon: _isLocationLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          onPressed: _isLocationLoading ? null : _getCurrentLocation,
          tooltip: 'Get current location',
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a location';
        }
        return null;
      },
    );
  }

  Widget _buildDateTimeSelector() {
    return InkWell(
      onTap: _selectDateTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date & Time',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateTime != null
                        ? '${_dateTime!.day}/${_dateTime!.month}/${_dateTime!.year} at ${_dateTime!.hour}:${_dateTime!.minute.toString().padLeft(2, '0')}'
                        : _itemType == 'lost'
                        ? 'When did you lose it?'
                        : 'When did you find it?',
                    style: TextStyle(
                      fontSize: 16,
                      color: _dateTime != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (_imageUrl != null) ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(File(_imageUrl!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ),
            ],
          ),
          if (_imageUrl != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _imageUrl = null;
                });
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Remove Image',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForcedInAppContact() {
    return TextFormField(
      enabled: false,
      initialValue: 'In-app chat',
      decoration: InputDecoration(
        labelText: 'Contact Method',
        prefixIcon: const Icon(Icons.chat_bubble_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Contact details field removed

  // Removed contact hint helper

  // Removed keyboard type helper

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: _itemType == 'lost' ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Posting...'),
                ],
              )
            : Text(
                _itemType == 'lost' ? 'Post Lost Item' : 'Post Found Item',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
