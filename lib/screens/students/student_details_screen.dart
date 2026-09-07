import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../widgets/custom_widgets.dart';
import 'student_form_screen.dart';

class StudentDetailsScreen extends StatelessWidget {
  final Student student;

  const StudentDetailsScreen({Key? key, required this.student}) : super(key: key);

  void _deleteStudent(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'étudiant'),
        content: Text(
          'Voulez-vous vraiment supprimer l\'étudiant "${student.fullName}" ?\n\n'
          'Toutes ses inscriptions seront également supprimées. Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<StudentProvider>().deleteStudent(student.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Étudiant supprimé avec succès')),
        );
        Navigator.pop(context); // close details screen
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    Widget avatarChild;
    if (student.photoUrl != null && student.photoUrl!.isNotEmpty) {
      final file = File(student.photoUrl!);
      if (file.existsSync()) {
        avatarChild = CircleAvatar(radius: 50, backgroundImage: FileImage(file));
      } else {
        avatarChild = const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50));
      }
    } else {
      avatarChild = const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'étudiant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentFormScreen(student: student),
                ),
              ).then((_) {
                // Return to list after edit to ensure refresh
                Navigator.pop(context);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteStudent(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profil (Header)
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    avatarChild,
                    const SizedBox(height: 16),
                    Text(
                      student.fullName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informations personnelles
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informations personnelles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildDetailRow(Icons.calendar_today, 'Date de naissance', student.dateOfBirth != null ? dateFormat.format(student.dateOfBirth!) : 'Non renseignée'),
                  _buildDetailRow(Icons.location_city, 'Lieu de naissance', student.placeOfBirth ?? 'Non renseigné'),
                  _buildDetailRow(Icons.location_on, 'Adresse', student.address ?? 'Non renseignée'),
                  _buildDetailRow(Icons.phone, 'Téléphone', student.phone),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Classe
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Classe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (student.englishClass != null) ...[
                    _buildDetailRow(Icons.school, 'Classe actuelle', student.englishClass!.name),
                    _buildDetailRow(Icons.leaderboard, 'Niveau', student.englishClass!.level),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Aucune classe assignée', style: TextStyle(color: Colors.grey)),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tuteur
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tuteur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (student.guardianLastName != null && student.guardianLastName!.isNotEmpty) ...[
                    _buildDetailRow(Icons.person_outline, 'Nom', student.guardianLastName!),
                    _buildDetailRow(Icons.person_outline, 'Prénom', student.guardianFirstName ?? ''),
                    _buildDetailRow(Icons.phone, 'Téléphone', student.guardianPhone ?? 'Non renseigné'),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Aucune information de tuteur', style: TextStyle(color: Colors.grey)),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
