import 'package:animalrescue/rescueRequestDetailsPage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';

import 'createRescueRequest_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userType;
  final ValueChanged<bool>? onThemeChanged;

  const HomeScreen({
    required this.userId,
    required this.userType,
    this.onThemeChanged,
    super.key,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initFCM();
  }

  Future<void> _initFCM() async {
    _messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'rescue_channel',
                'Rescue Notifications',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
            payload: message.data['requestId'],
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final requestId = message.data['requestId'];
        if (requestId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RescueRequestDetailsPage(
                requestId: requestId,
                userId: widget.userId,
                userType: widget.userType,
              ),
            ),
          );
        }
      });

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          final payload = response.payload;
          if (payload != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RescueRequestDetailsPage(
                  requestId: payload,
                  userId: widget.userId,
                  userType: widget.userType,
                ),
              ),
            );
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSettingsTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(userId: widget.userId),
      ),
    );
  }

  Future<String> _getAddress(Map<String, dynamic> data) async {
    final location = data['location'];
    final manualAddress = data['manual_address'];

    if (location != null &&
        location['latitude'] != null &&
        location['longitude'] != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location['latitude'],
          location['longitude'],
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        }
      } catch (_) {}
    }

    if (manualAddress != null && manualAddress.toString().isNotEmpty) {
      return manualAddress;
    }

    return 'Location not available';
  }

  Widget _buildRequestCard(DocumentSnapshot doc, {required bool isPending}) {
    final data = doc.data() as Map<String, dynamic>;

    return FutureBuilder<String>(
      future: _getAddress(data),
      builder: (context, snapshot) {
        final address = snapshot.connectionState == ConnectionState.waiting
            ? 'Fetching address...'
            : snapshot.data ?? 'Location not available';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 3,
          child: ListTile(
            leading: data['image_url'] != null
                ? Image.network(data['image_url'], width: 60, height: 60, fit: BoxFit.cover)
                : const Icon(Icons.image_not_supported),
            title: Text(data['notes'] ?? 'No description'),
            subtitle: Text('Location: $address'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RescueRequestDetailsPage(
                    requestId: doc.id,
                    userId: widget.userId,
                    userType: widget.userType,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestList(List<String> statuses, {required bool isPending}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rescue_requests')
          .where('status', whereIn: statuses)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No ${statuses.join("/")} requests.'));
        }
        return ListView(
          children: snapshot.data!.docs
              .map((doc) => _buildRequestCard(doc, isPending: isPending))
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Animal Rescue Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .get(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data() as Map<String, dynamic>?;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: CircleAvatar(backgroundColor: Colors.white),
                  );
                }

                final imageUrl = userData?['profile_image'] ?? null;

                return IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: widget.userId),
                      ),
                    );
                  },
                  icon: CircleAvatar(
                    backgroundImage: imageUrl != null && imageUrl != ''
                        ? NetworkImage(imageUrl)
                        : null,
                    backgroundColor: Colors.white,
                    child: imageUrl == null || imageUrl == ''
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Pending Requests'),
              Tab(text: 'Rescued Log'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestList(['pending', 'being rescued'], isPending: true),
            _buildRequestList(['rescued'], isPending: false),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF6A1B9A),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateRescueRequestScreen(
                  userId: widget.userId,
                  userType: widget.userType,
                ),
              ),
            );
          },
          tooltip: 'Create Rescue Request',
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              _onSettingsTapped();
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            //BottomNavigationBarItem(icon: SizedBox(), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
