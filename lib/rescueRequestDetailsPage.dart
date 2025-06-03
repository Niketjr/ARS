import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'geocoder.dart';

class RescueRequestDetailsPage extends StatefulWidget {
  final String requestId;
  final String userId;
  final String userType;

  const RescueRequestDetailsPage({
    required this.requestId,
    required this.userId,
    required this.userType,
    super.key,
  });

  @override
  State<RescueRequestDetailsPage> createState() =>
      _RescueRequestDetailsPageState();
}

class _RescueRequestDetailsPageState extends State<RescueRequestDetailsPage> {
  bool _isUpdating = false;

  Future<void> _acceptRescue() async {
    setState(() => _isUpdating = true);
    await FirebaseFirestore.instance
        .collection('rescue_requests')
        .doc(widget.requestId)
        .update({
      'rescuer_id': widget.userId,
      'status': 'being rescued',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You accepted the rescue.')),
    );

    setState(() => _isUpdating = false);
  }

  Future<void> _markAsRescued() async {
    setState(() => _isUpdating = true);
    await FirebaseFirestore.instance
        .collection('rescue_requests')
        .doc(widget.requestId)
        .update({'status': 'rescued'});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as rescued.')),
    );

    setState(() => _isUpdating = false);
  }

  Future<Map<String, dynamic>?> _getRescuerInfo(String rescuerId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(rescuerId)
        .get();
    return doc.exists ? doc.data() : null;
  }

  Future<LatLng?> _getRescueLocation(Map<String, dynamic> data) async {
    final locationData = data['location'];
    if (locationData != null &&
        locationData['latitude'] != null &&
        locationData['longitude'] != null) {
      return LatLng(
        (locationData['latitude'] as num).toDouble(),
        (locationData['longitude'] as num).toDouble(),
      );
    }

    final manualAddress = data['manual_address'];
    if (manualAddress != null && manualAddress.toString().isNotEmpty) {
      return await geocodeAddress(manualAddress);
    }

    return null;
  }

  Future<void> _openDirections(double destLat, double destLng) async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${position.latitude},${position.longitude}&destination=$destLat,$destLng&travelmode=driving',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permissions are permanently denied')),
      );
      return false;
    }

    return true;
  }

  Future<String> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return '${p.street}, ${p.locality}, ${p.administrativeArea}, ${p.country}';
      }
      return 'No address found';
    } catch (_) {
      return 'Error fetching address';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rescue Request Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('rescue_requests')
            .doc(widget.requestId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Request not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'];
          final String? assignedRescuer = data['rescuer_id'];

          return FutureBuilder<LatLng?>(
            future: _getRescueLocation(data),
            builder: (context, locationSnapshot) {
              if (locationSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final location = locationSnapshot.data;
              if (location == null) {
                return const Center(child: Text('Invalid location data'));
              }

              return FutureBuilder<Map<String, dynamic>?>(
                future: assignedRescuer != null
                    ? _getRescuerInfo(assignedRescuer)
                    : null,
                builder: (context, userSnapshot) {
                  final rescuerData = userSnapshot.data;

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: SingleChildScrollView(
                      key: ValueKey(data['status']),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              clipBehavior: Clip.antiAlias,
                              child: data['image_url'] != null &&
                                  data['image_url'].toString().isNotEmpty
                                  ? Image.network(data['image_url'],
                                  height: 220, fit: BoxFit.cover)
                                  : Container(
                                height: 220,
                                color: Colors.grey[300],
                                child: const Center(
                                    child: Text('No image provided')),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 240,
                                child: FlutterMap(
                                  mapController: MapController(),
                                  options: MapOptions(
                                    initialCenter: location,
                                    initialZoom: 15,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                      'com.example.animalrescue',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: location,
                                          width: 40,
                                          height: 40,
                                          child: const Icon(Icons.location_on,
                                              size: 40, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<String>(
                              future: _getAddressFromCoordinates(
                                  location.latitude, location.longitude),
                              builder: (context, addressSnapshot) {
                                if (addressSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final address =
                                    addressSnapshot.data ?? 'No address found';
                                return Text(
                                  '📍 Location:\n$address',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(fontWeight: FontWeight.w600),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('📝 Description:',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(data['notes'] ?? '-'),
                                    const SizedBox(height: 12),
                                    Text('📌 Status: $status'),
                                    if (assignedRescuer != null)
                                      userSnapshot.connectionState ==
                                          ConnectionState.waiting
                                          ? const Text('Loading rescuer info...')
                                          : rescuerData != null
                                          ? Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 12),
                                          Text(
                                              '👤 Rescuer: ${rescuerData['name']}'),
                                          Text(
                                              '📞 Contact: ${rescuerData['phone']}'),
                                        ],
                                      )
                                          : const Text(
                                          'Rescuer: (info not found)'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _openDirections(
                                  location.latitude, location.longitude),
                              icon: const Icon(Icons.directions),
                              label: const Text('Get Directions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (assignedRescuer == null)
                              ElevatedButton.icon(
                                onPressed: _isUpdating ? null : _acceptRescue,
                                icon: const Icon(Icons.assignment_turned_in),
                                label: const Text('Accept Rescue'),
                              ),
                            if (status == 'being rescued')
                              ElevatedButton.icon(
                                onPressed: _isUpdating ? null : _markAsRescued,
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Mark as Rescued'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
