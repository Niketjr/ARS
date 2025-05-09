import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';

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
  LocationData? _locationData;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final locData = await location.getLocation();
    setState(() {
      _locationData = locData;
    });
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
    final ref = FirebaseStorage.instance.ref().child('rescue_images').child(fileName);
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> _submitRequest() async {
    if (_locationData == null || _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide location and details.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;

      // Upload image if selected
      if (_image != null) {
        imageUrl = await _uploadImage(_image!);
      }

      // Save rescue request and get the reference
      final DocumentReference requestRef = await FirebaseFirestore.instance.collection('rescue_requests').add({
        'user_id': widget.userId,
        'user_type': widget.userType,
        'notes': _detailsController.text,
        'image_url': imageUrl, // This will be null if no image is uploaded
        'location': {
          'latitude': _locationData!.latitude,
          'longitude': _locationData!.longitude,
        },
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Save a related notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'rescue_request',
        'user_id': widget.userId,
        'request_id': requestRef.id,
        'message': 'A new rescue request has been created.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rescue request submitted!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Rescue Request')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              Image.file(_image!, height: 200)
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(child: Text('No image selected')),
              ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera),
                  label: Text('Camera'),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo),
                  label: Text('Gallery'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.location_on),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationData != null
                        ? 'Lat: ${_locationData!.latitude}, Lng: ${_locationData!.longitude}'
                        : 'Fetching location...',
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Details / Notes',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(50),
              ),
              child: Text(_isSubmitting ? 'Submitting...' : 'Submit Rescue Request'),
            ),
          ],
        ),
      ),
    );
  }
}
