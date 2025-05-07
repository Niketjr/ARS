import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ///////////////////////////////////////////// Add Rescue Request ///////////////////////////////////////////
  Future<void> addRescueRequest({
    required String imageUrl,
    required double latitude,
    required double longitude,
    required String notes,
    required String createdBy,
    required String userType,
  }) async {
    try {
      final docRef = _firestore.collection('rescue_requests').doc();
      await docRef.set({
        'id': docRef.id,
        'image_url': imageUrl,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'notes': notes,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'created_by': createdBy,
        'user_type': userType,
      });
      print('Rescue request added successfully');
    } catch (e) {
      print('Error adding rescue request: $e');
    }
  }

  ///////////////////////////////////////////// Update Rescue Request Status ///////////////////////////////////////////
  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    try {
      await _firestore
          .collection('rescue_requests')
          .doc(requestId)
          .update({'status': newStatus});
      print('Request status updated to $newStatus');
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  ///////////////////////////////////////////// Get Pending Rescue Requests ///////////////////////////////////////////
  Stream<QuerySnapshot> getPendingRequests() {
    return _firestore
        .collection('rescue_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  ///////////////////////////////////////////// Get Rescued Requests ///////////////////////////////////////////
  Stream<QuerySnapshot> getRescuedRequests() {
    return _firestore
        .collection('rescue_requests')
        .where('status', isEqualTo: 'rescued')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
