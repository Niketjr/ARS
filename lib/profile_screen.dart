import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String email = '';
  String phone = '';
  String userType = '';
  String? photoURL;

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  List<Map<String, dynamic>> pastActivities = [];

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadPastActivities();
  }

  Future<void> _loadUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        print('Loaded user data: $data');
        setState(() {
          name = data['name'] ?? '';
          phone = data['phone'] ?? '';
          email = data['email'] ?? '';
          userType = data['user_type'] ?? '';
          photoURL = user?.photoURL;
          nameController.text = name;
          phoneController.text = phone;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<void> _loadPastActivities() async {
    List<Map<String, dynamic>> activities = [];

    try {
      // Requests made by user
      final requestedSnapshot = await FirebaseFirestore.instance
          .collection('rescue_requests')
          .where('user_id', isEqualTo: widget.userId)
          .get();

      for (var doc in requestedSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'Requested',
          'timestamp': data['timestamp'],
          'location': data['location'],
          'address': data['location']?['address'],
        });
      }

      // Rescues done by user
      final rescuedSnapshot = await FirebaseFirestore.instance
          .collection('rescue_requests')
          .where('rescuer_id', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'rescued')
          .get();

      for (var doc in rescuedSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'Rescued',
          'timestamp': data['timestamp'],
          'location': data['location'],
        });
      }

      setState(() {
        pastActivities = activities;
      });
    } catch (e) {
      print('Error fetching past activities: $e');
    }
  }


  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'name': nameController.text,
        'phone': phoneController.text,
      });
      setState(() {
        name = nameController.text;
        phone = phoneController.text;
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    }
  }

  Future<void> _confirmSignOut() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Logout')),
        ],
      ),
    );

    if (result == true) {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => WelcomeScreen()),
              (route) => false,
        );
      }
    }
  }

  Widget _buildField({
    required String label,
    required String value,
    TextEditingController? controller,
    bool editable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey[700])),
        isEditing && editable
            ? TextFormField(
          controller: controller,
          validator: (val) => val == null || val.isEmpty ? 'Enter $label' : null,
        )
            : Text(value, style: TextStyle(fontSize: 16)),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: photoURL != null
              ? NetworkImage(photoURL!)
              : AssetImage('assets/default_avatar.png') as ImageProvider,
        ),
        SizedBox(height: 12),
        Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(email, style: TextStyle(color: Colors.grey[700])),
        Text(userType, style: TextStyle(color: Colors.grey[600])),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActivityList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Past Activities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        if (pastActivities.isEmpty)
          Text('No past activities found.', style: TextStyle(color: Colors.grey)),
        ...pastActivities.map((activity) {
          final type = activity['type'];
          final timestamp = activity['timestamp'] != null
              ? (activity['timestamp'] as Timestamp).toDate()
              : null;
          final location = activity['location'];
          final lat = location?['latitude']?.toStringAsFixed(4) ?? 'N/A';
          final lng = location?['longitude']?.toStringAsFixed(4) ?? 'N/A';
          final address = activity['address'] ?? 'No address available';

          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Icon(
                type == 'Requested' ? Icons.help_outline : Icons.check_circle_outline,
                color: type == 'Requested' ? Colors.orange : Colors.green,
              ),
              title: Text('$type'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📍 Address: $address'),
                  if (timestamp != null)
                    Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)}'),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _saveProfile();
              } else {
                setState(() => isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Divider(),
              _buildField(label: 'Name', value: name, controller: nameController, editable: true),
              _buildField(label: 'Phone Number', value: phone, controller: phoneController, editable: true),
              Divider(),
              _buildActivityList(),
              SizedBox(height: 24),
              OutlinedButton(
                onPressed: _confirmSignOut,
                child: Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
