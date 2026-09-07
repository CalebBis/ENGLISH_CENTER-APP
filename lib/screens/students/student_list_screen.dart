import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/class_provider.dart';
import '../../widgets/custom_widgets.dart';
import 'student_form_screen.dart';
import 'student_details_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({Key? key}) : super(key: key);

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadStudents();
      context.read<ClassProvider>().loadClasses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<StudentProvider>().searchStudents(
      _searchController.text,
      _selectedClassId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Étudiants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentFormScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    controller: _searchController,
                    label: 'Rechercher un étudiant',
                    prefixIcon: Icons.search,
                    onChanged: (val) => _onSearchChanged(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Consumer<ClassProvider>(
                    builder: (context, classProvider, child) {
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Filtrer par classe',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        value: _selectedClassId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Toutes les classes')),
                          ...classProvider.classes.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedClassId = val);
                          _onSearchChanged();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<StudentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Aucun étudiant trouvé.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const StudentFormScreen()),
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Ajouter un étudiant'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.students.length,
                  itemBuilder: (context, index) {
                    final student = provider.students[index];
                    
                    Widget avatarChild;
                    if (student.photoUrl != null && student.photoUrl!.isNotEmpty) {
                      final file = File(student.photoUrl!);
                      if (file.existsSync()) {
                        avatarChild = CircleAvatar(backgroundImage: FileImage(file));
                      } else {
                        avatarChild = const CircleAvatar(child: Icon(Icons.person));
                      }
                    } else {
                      avatarChild = const CircleAvatar(child: Icon(Icons.person));
                    }

                    return CustomCard(
                      padding: const EdgeInsets.all(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentDetailsScreen(student: student),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: avatarChild,
                        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Téléphone : ${student.phone}'),
                            Text(
                              'Classe : ${student.englishClass?.name ?? 'Non assigné'}',
                              style: TextStyle(
                                color: student.englishClass == null ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
