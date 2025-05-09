import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;

  const SettingsScreen({required this.userId, super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isDarkTheme = false;

  void _confirmDeleteAccount() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account deleted successfully')));
        Navigator.pushReplacementNamed(context, '/welcome');
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: Text('User ID: ${widget.userId}'),
            subtitle: Text('For internal reference'),
          ),
          Divider(),
          SwitchListTile(
            title: Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              // Optional: Save to Firebase or local storage using widget.userId
            },
          ),
          SwitchListTile(
            title: Text('Dark Theme'),
            value: _isDarkTheme,
            onChanged: (val) {
              setState(() => _isDarkTheme = val);
              // Optional: Implement actual theme logic
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy Settings'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Privacy settings not implemented.')));
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text('Delete Account'),
            onTap: _confirmDeleteAccount,
          ),
        ],
      ),
    );
  }
}
