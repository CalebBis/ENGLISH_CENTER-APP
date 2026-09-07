import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/teacher.dart';
import '../../providers/teacher_provider.dart';
import 'teacher_form_screen.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({Key? key}) : super(key: key);

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<TeacherProvider>().loadTeachers();
      }
    });
    _searchController.addListener(() {
      context.read<TeacherProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openForm({Teacher? teacher}) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherFormScreen(teacher: teacher),
      ),
    );
    if (mounted) {
      context.read<TeacherProvider>().loadTeachers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Enseignants'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un enseignant',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<TeacherProvider>().setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(
            child: Consumer<TeacherProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final teachers = provider.teachers;

                if (teachers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          provider.searchQuery.isEmpty
                              ? 'Aucun enseignant enregistré'
                              : 'Aucun résultat pour "${provider.searchQuery}"',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        headingRowColor: WidgetStateProperty.all(
                          AppTheme.primaryColor.withValues(alpha: 0.08),
                        ),
                        columns: const [
                          DataColumn(label: Text('Photo', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Nom complet', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Lieu de naissance', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: teachers.map((t) => _buildRow(t)).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  DataRow _buildRow(Teacher teacher) {
    return DataRow(
      onSelectChanged: (_) => _openForm(teacher: teacher),
      cells: [
        DataCell(_buildAvatar(teacher)),
        DataCell(Text(teacher.fullName)),
        DataCell(Text(teacher.phone)),
        DataCell(Text(teacher.placeOfBirth ?? '-')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: AppTheme.accentColor,
                tooltip: 'Modifier',
                onPressed: () => _openForm(teacher: teacher),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                tooltip: 'Supprimer',
                onPressed: () => _confirmDelete(teacher),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(Teacher teacher) {
    if (teacher.photoUrl != null && teacher.photoUrl!.isNotEmpty) {
      final file = File(teacher.photoUrl!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: 20,
          backgroundImage: FileImage(file),
        );
      }
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
      child: Text(
        teacher.lastName.isNotEmpty ? teacher.lastName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Teacher teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer ${teacher.fullName} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<TeacherProvider>().deleteTeacher(teacher.id);
    }
  }
}

