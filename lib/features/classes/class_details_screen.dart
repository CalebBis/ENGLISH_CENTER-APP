import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'class_providers.dart';
import '../students/student_providers.dart';
import '../../core/models/student_model.dart';
import '../../core/models/class_model.dart';

class ClassDetailsScreen extends ConsumerWidget {
  final String classIdStr;

  const ClassDetailsScreen({super.key, required this.classIdStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int classId = int.tryParse(classIdStr) ?? 0;
    final studentsAsync = ref.watch(classStudentsProvider(classId));
    final classesAsync = ref.watch(classesProvider);
    
    ClassModel? currentClass;
    if (classesAsync.value != null) {
      currentClass = classesAsync.value!.firstWhere((c) => c.id == classId);
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/classes'),
              ),
              const SizedBox(width: 16),
              Text(
                'Détails de la classe : ${currentClass?.name ?? ''}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddStudentDialog(context, ref, classId);
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Ajouter un étudiant'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              child: studentsAsync.when(
                data: (students) {
                  if (students.isEmpty) {
                    return const Center(child: Text('Aucun étudiant dans cette classe.'));
                  }
                  return ListView(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Nom')),
                          DataColumn(label: Text('Sexe')),
                          DataColumn(label: Text('Téléphone')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: students.map((s) {
                          return DataRow(cells: [
                            DataCell(Text('${s.lastName} ${s.firstname}')),
                            DataCell(Text(s.gender)),
                            DataCell(Text(s.phone)),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.person_remove, color: Colors.red),
                                onPressed: () async {
                                  await ref.read(classRepositoryProvider).removeStudentFromClass(s.id!, classId);
                                  ref.refresh(classStudentsProvider(classId));
                                },
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Erreur: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context, WidgetRef ref, int classId) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final allStudentsAsync = ref.watch(studentsProvider);
            return AlertDialog(
              title: const Text('Sélectionner un étudiant'),
              content: SizedBox(
                width: 400,
                height: 400,
                child: allStudentsAsync.when(
                  data: (students) {
                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        return ListTile(
                          title: Text('${s.lastName} ${s.firstname}'),
                          subtitle: Text(s.phone),
                          trailing: ElevatedButton(
                            child: const Text('Ajouter'),
                            onPressed: () async {
                              await ref.read(classRepositoryProvider).enrollStudent(s.id!, classId, DateTime.now().toIso8601String());
                              ref.refresh(classStudentsProvider(classId));
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Erreur: $e'),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                )
              ],
            );
          },
        );
      },
    );
  }
}
