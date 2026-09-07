import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool emailNotifications = true;
  bool smsNotifications = false;
  String selectedLanguage = 'Français';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance
            const Text(
              'Apparence',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Mode Sombre'),
                      value: darkMode,
                      onChanged: (value) {
                        setState(() => darkMode = value);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedLanguage,
                      items: ['Français', 'English', 'Español']
                          .map((lang) => DropdownMenuItem(
                                value: lang,
                                child: Text(lang),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedLanguage = value!);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Langue',
                        prefixIcon: Icon(Icons.language),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notifications
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Notifications Email'),
                      subtitle: const Text('Recevoir les alertes par email'),
                      value: emailNotifications,
                      onChanged: (value) {
                        setState(() => emailNotifications = value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Notifications SMS'),
                      subtitle: const Text('Recevoir les alertes par SMS'),
                      value: smsNotifications,
                      onChanged: (value) {
                        setState(() => smsNotifications = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Data Management
            const Text(
              'Gestion des Données',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Sauvegarder'),
                    subtitle: const Text('Créer une sauvegarde de la base de données'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sauvegarde en cours...')),
                      );
                    },
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restaurer'),
                    subtitle: const Text('Restaurer depuis une sauvegarde'),
                    onTap: () {
                      // TODO: Implémenter
                    },
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Réinitialiser'),
                    subtitle: const Text('Supprimer toutes les données'),
                    onTap: () {
                      _showDeleteConfirmation(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About
            const Text(
              'À Propos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Version'),
                        Text('1.0.0'),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Développeur'),
                        Text('English Center'),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Base de données'),
                        Text('SQLite'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser'),
        content: const Text(
          'Êtes-vous sûr? Cette action supprimera toutes les données et ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Réinitialisation en cours...')),
              );
            },
            child: const Text('Réinitialiser', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
