import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _phoneController = TextEditingController();
  String _userType = 'Rescuer';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _handleSignUp(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled the sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userId = user.uid;

        // Save user info to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'phone': _phoneController.text.trim(),
          'user_type': _userType,
          'email': user.email,
          'name': user.displayName,
          'uid': userId,
        });

        // Navigate to HomeScreen with parameters
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userId: userId,
              userType: _userType,
            ),
          ),
        );
      }
    } catch (error) {
      print('Registration error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Complete Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            DropdownButton<String>(
              value: _userType,
              onChanged: (String? newValue) {
                setState(() {
                  _userType = newValue!;
                });
              },
              items: ['Rescuer', 'NGO', 'General User']
                  .map((value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ))
                  .toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _handleSignUp(context),
              child: Text('Register and Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
