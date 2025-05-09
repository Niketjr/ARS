import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'welcome_screen.dart'; // Make sure this import matches your actual file

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController phoneController = TextEditingController();
  String userType = 'General User';
  double? latitude;
  double? longitude;

  final List<String> userTypes = ['Rescuer', 'NGO', 'General User'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        phoneController.text = data['phone'] ?? '';
        userType = data['userType'] ?? 'General User';
        latitude = data['location']?['latitude'];
        longitude = data['location']?['longitude'];
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'phone': phoneController.text,
        'userType': userType,
        'location': {
          'latitude': latitude ?? 0.0,
          'longitude': longitude ?? 0.0,
        },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'Phone Number'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter phone number' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: userType,
                items: userTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => userType = value!),
                decoration: InputDecoration(labelText: 'User Type'),
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: latitude?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Latitude'),
                onChanged: (val) => latitude = double.tryParse(val),
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: longitude?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Longitude'),
                onChanged: (val) => longitude = double.tryParse(val),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Save Changes'),
              ),
              SizedBox(height: 16),
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
