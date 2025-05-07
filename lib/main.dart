import 'dart:developer';
import 'package:animalrescue/registration_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';
import 'splash_screen.dart';
import '_dataupload.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await Service().addRescueRequest(
  //   imageUrl: 'https://example.com/image.jpg',
  //   latitude: 12.9716,
  //   longitude: 77.5946,
  //   notes: 'Injured dog spotted near the park.',
  //   createdBy: 'user123',
  //   userType: 'general',
  // );

  runApp(AnimalRescueApp());
}

class AnimalRescueApp extends StatelessWidget {
  const AnimalRescueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Rescue',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return SplashScreen();
              }

              // If user doc exists, navigate to HomeScreen
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final userType = userData['user_type'] ?? 'Unknown';

                return HomeScreen(
                  userId: user.uid,
                  userType: userType,
                );
              } else {
                // Redirect to registration screen
                return RegistrationScreen();
              }
            },
          );
        } else {
          return WelcomeScreen();
        }
      },
    );
  }
}


