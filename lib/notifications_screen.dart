import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'rescueRequestDetailsPage.dart'; // Make sure this import points to the correct file

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({Key? key, required this.userId}) : super(key: key);

  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance.collection('rescue_requests').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rescue_requests')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No rescue requests yet.'));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
              final String description = data['notes'] ?? 'No description';
              final Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
              final String formattedTime = DateFormat.yMMMd().add_jm().format(timestamp.toDate());

              return ListTile(
                leading: const Icon(Icons.notification_important),
                title: const Text('New Rescue Request'),
                subtitle: Text('$description\n$formattedTime'),
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RescueRequestDetailsPage(
                        requestId: doc.id,
                        userId: userId,
                        userType: 'rescuer', // Adjust this based on actual role
                      ),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.done),
                  tooltip: 'Mark as read',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Mark as Read'),
                        content: Text('Remove this notification from the list?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Yes')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _markAsRead(doc.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Notification marked as read')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
