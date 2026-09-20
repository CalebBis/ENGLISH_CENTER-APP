import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/english_class.dart';
import '../../models/teacher.dart';
import '../../services/dao/class_dao.dart';
import '../classes/class_details_screen.dart';
import 'teacher_form_screen.dart';

class TeacherDetailScreen extends StatefulWidget {
  final Teacher teacher;

  const TeacherDetailScreen({Key? key, required this.teacher}) : super(key: key);

  @override
  State<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen> {
  final ClassDao _classDao = ClassDao();
  List<EnglishClass> _assignedClasses = [];
  bool _isLoading = true;
  late Teacher _teacher;

  @override
  void initState() {
    super.initState();
    _teacher = widget.teacher;
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final classes = await _classDao.getClassesByTeacherId(_teacher.id);
    if (mounted) {
      setState(() {
        _assignedClasses = classes;
        _isLoading = false;
      });
    }
  }

  void _openForm() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherFormScreen(teacher: _teacher),
      ),
    );
    if (updated == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'enseignant'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: _openForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralInfoCard(),
            const SizedBox(height: 24),
            _buildAssignedClassesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations générales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _teacher.fullName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.phone, 'Téléphone', _teacher.phone),
                      _buildInfoRow(Icons.email, 'Email', _teacher.email),
                      if (_teacher.dateOfBirth != null)
                        _buildInfoRow(Icons.cake, 'Date de naissance', DateFormat('dd/MM/yyyy').format(_teacher.dateOfBirth!)),
                      if (_teacher.placeOfBirth != null && _teacher.placeOfBirth!.isNotEmpty)
                        _buildInfoRow(Icons.location_city, 'Lieu de naissance', _teacher.placeOfBirth!),
                      if (_teacher.address != null && _teacher.address!.isNotEmpty)
                        _buildInfoRow(Icons.home, 'Adresse', _teacher.address!),
                      if (_teacher.specializations.isNotEmpty)
                        _buildInfoRow(Icons.school, 'Spécialisations', _teacher.specializations.join(', ')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(text: '$label : ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (_teacher.photoUrl != null && _teacher.photoUrl!.isNotEmpty) {
      final file = File(_teacher.photoUrl!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
        );
      }
    }
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        _teacher.lastName.isNotEmpty ? _teacher.lastName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 40,
        ),
      ),
    );
  }

  Widget _buildAssignedClassesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classe(s) assignée(s)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_assignedClasses.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Aucune classe assignée pour le moment',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _assignedClasses.length,
            itemBuilder: (context, index) {
              final c = _assignedClasses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Niveau : ${c.level}\n'
                    'Étudiants inscrits : ${c.currentEnrollment} / ${c.isUnlimited ? "Illimité" : c.maxCapacity}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  isThreeLine: true,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassDetailsScreen(englishClass: c),
                      ),
                    );
                    _loadClasses();
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}
