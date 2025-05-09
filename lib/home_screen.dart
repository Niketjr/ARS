import 'package:animalrescue/rescueRequestDetailsPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'createRescueRequest_screen.dart';

// Import your target screens for navigation
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userType; // e.g., 'rescuer', 'ngo', etc.

  const HomeScreen({required this.userId, required this.userType, super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // Already on Home, do nothing
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationsScreen(userId: widget.userId),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: widget.userId),
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SettingsScreen(userId: widget.userId),
        ),
      );
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildRequestCard(DocumentSnapshot doc, {required bool isPending}) {
    final data = doc.data() as Map<String, dynamic>;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: ListTile(
        leading: data['image_url'] != null
            ? Image.network(data['image_url'], width: 60, height: 60, fit: BoxFit.cover)
            : Icon(Icons.image_not_supported),
        title: Text(data['notes'] ?? 'No description'),
        subtitle: data['location'] != null
            ? Text(
          'Location: ${data['location']['latitude'].toStringAsFixed(4)}, ${data['location']['longitude'].toStringAsFixed(4)}',
        )
            : Text('Location not available'),
        trailing: Icon(Icons.chevron_right),
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
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
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
  void dispose() {
    _tabController.dispose(); // Proper cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Animal Rescue Dashboard'),
        bottom: TabBar(
          controller: _tabController,
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
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
