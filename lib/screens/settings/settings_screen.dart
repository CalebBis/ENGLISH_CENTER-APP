import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool emailNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apparence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('Mode Sombre'),
                value: darkMode,
                onChanged: (value) {
                  setState(() => darkMode = value);
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('Email'),
                value: emailNotifications,
                onChanged: (value) {
                  setState(() => emailNotifications = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
