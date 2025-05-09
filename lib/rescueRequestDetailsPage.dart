import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RescueRequestDetailsPage extends StatefulWidget {
  final String requestId;
  final String userId;
  final String userType; // 'rescuer', 'general', 'ngo'

  const RescueRequestDetailsPage({
    required this.requestId,
    required this.userId,
    required this.userType,
    super.key,
  });

  @override
  State<RescueRequestDetailsPage> createState() => _RescueRequestDetailsPageState();
}

class _RescueRequestDetailsPageState extends State<RescueRequestDetailsPage> {
  bool _isUpdating = false;

  Future<void> _acceptRescue() async {
    setState(() => _isUpdating = true);
    await FirebaseFirestore.instance.collection('rescue_requests').doc(widget.requestId).update({
      'rescuer_id': widget.userId,
      'status': 'being rescued',
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You accepted the rescue.')));
    setState(() => _isUpdating = false);
  }

  Future<void> _markAsRescued() async {
    setState(() => _isUpdating = true);
    await FirebaseFirestore.instance.collection('rescue_requests').doc(widget.requestId).update({
      'status': 'rescued',
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked as rescued.')));
    setState(() => _isUpdating = false);
  }

  Future<Map<String, dynamic>?> _getRescuerInfo(String rescuerId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(rescuerId).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rescue Request Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('rescue_requests').doc(widget.requestId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Request not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final LatLng location = LatLng(
            data['location']['latitude'],
            data['location']['longitude'],
          );
          final String status = data['status'];
          final String? assignedRescuer = data['rescuer_id'];

          return FutureBuilder<Map<String, dynamic>?>(
            future: assignedRescuer != null ? _getRescuerInfo(assignedRescuer) : null,
            builder: (context, userSnapshot) {
              final rescuerData = userSnapshot.data;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data['image_url'] != null && data['image_url'].toString().isNotEmpty)
                      Image.network(data['image_url'], height: 200, fit: BoxFit.cover)
                    else
                      Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(child: Text('No image provided')),
                      ),
                    SizedBox(height: 10),
                    SizedBox(
                      height: 250,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: location,
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId('animal_location'),
                            position: location,
                          ),
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Description: ${data['notes']}', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Status: $status', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 8),

                          if (assignedRescuer != null)
                            userSnapshot.connectionState == ConnectionState.waiting
                                ? Text('Loading rescuer info...')
                                : rescuerData != null
                                ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rescuer: ${rescuerData['name']}', style: TextStyle(fontSize: 16)),
                                Text('Contact: ${rescuerData['phone']}', style: TextStyle(fontSize: 16)),
                              ],
                            )
                                : Text('Rescuer: (info not found)', style: TextStyle(fontSize: 16)),

                          SizedBox(height: 20),

                          if (assignedRescuer == null)
                            ElevatedButton.icon(
                              onPressed: _isUpdating ? null : _acceptRescue,
                              icon: Icon(Icons.assignment_turned_in),
                              label: Text('Accept Rescue'),
                            ),

                          // 🔔 NEW BUTTON visible to ALL user types if status is 'being rescued'
                          if (status == 'being rescued')
                            ElevatedButton.icon(
                              onPressed: _isUpdating ? null : _markAsRescued,
                              icon: Icon(Icons.check_circle),
                              label: Text('Rescued'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
