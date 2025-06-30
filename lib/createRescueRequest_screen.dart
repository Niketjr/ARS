import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

class CreateRescueRequestScreen extends StatefulWidget {
  final String userId;
  final String userType;

  const CreateRescueRequestScreen({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  _CreateRescueRequestScreenState createState() => _CreateRescueRequestScreenState();
}

class _CreateRescueRequestScreenState extends State<CreateRescueRequestScreen> {
  File? _image;
  loc.LocationData? _locationData;
  String? _address;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    loc.Location location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    final locData = await location.getLocation();

    if (mounted) {
      setState(() {
        _locationData = locData;
      });
      _getAddressFromLatLng(locData.latitude!, locData.longitude!);
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        setState(() {
          _address = "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance
        .ref()
        .child('rescue_images')
        .child(fileName);
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> _submitRequest() async {
    if (_locationData == null || _detailsController.text.isEmpty || _address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for location and provide details.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;

      if (_image != null) {
        imageUrl = await _uploadImage(_image!);
      }

      final Map<String, dynamic> locationMap = {
        'latitude': (_locationData!.latitude as num).toDouble(),
        'longitude': (_locationData!.longitude as num).toDouble(),
        'address': _address,
      };

      final DocumentReference requestRef =
      await FirebaseFirestore.instance.collection('rescue_requests').add({
        'user_id': widget.userId,
        'user_type': widget.userType,
        'notes': _detailsController.text,
        'image_url': imageUrl,
        'location': locationMap,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'rescue_request',
        'user_id': widget.userId,
        'request_id': requestRef.id,
        'message': 'A new rescue request has been created.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rescue request submitted!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildLocationDisplay() {
    return Row(
      children: [
        const Icon(Icons.location_on),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _address ?? 'Fetching location address...',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Rescue Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              Image.file(_image!, height: 200)
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: Text('No image selected')),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLocationDisplay(),
            const SizedBox(height: 20),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Details / Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(
                _isSubmitting ? 'Submitting...' : 'Submit Rescue Request',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
