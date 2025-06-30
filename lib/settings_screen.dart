import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  //final ValueChanged<bool> onThemeChanged;

  const SettingsScreen({
    required this.userId,
    //required this.onThemeChanged,
    super.key,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  //bool _isDarkTheme = false;

  void _confirmDeleteAccount() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
        Navigator.pushReplacementNamed(context, '/welcome');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final divider = const Divider(height: 32, thickness: 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            child: ListTile(
              title: const Text('User ID'),
              subtitle: Text(widget.userId),
              leading: const Icon(Icons.person_outline),
            ),
          ),

          const SizedBox(height: 24),
          const Text('Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          divider,

          SwitchListTile(
            title: const Text('Enable Notifications'),
            secondary: const Icon(Icons.notifications_active),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              // Optional: Save to local or Firebase
            },
          ),
          // SwitchListTile(
          //   title: const Text('Dark Theme'),
          //   secondary: const Icon(Icons.dark_mode),
          //   value: _isDarkTheme,
          //   onChanged: (val) {
          //     setState(() => _isDarkTheme = val);
          //     widget.onThemeChanged(val);
          //   },
          // ),

          const SizedBox(height: 24),
          const Text('More Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          divider,

          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy settings not implemented.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: _confirmDeleteAccount,
          ),
        ],
      ),
    );
  }
}
