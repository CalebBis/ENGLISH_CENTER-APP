import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'student_providers.dart';
import 'student_form_dialog.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Étudiants',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const StudentFormDialog(),
                  );
                },
                icon: const Icon(Icons.add),
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
                    return const Center(child: Text('Aucun étudiant trouvé.'));
                  }
                  return ListView(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Nom')),
                          DataColumn(label: Text('Sexe')),
                          DataColumn(label: Text('Téléphone')),
                          DataColumn(label: Text('Statut')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: students.map((s) {
                          return DataRow(cells: [
                            DataCell(Text(s.id.toString())),
                            DataCell(Text('${s.lastName} ${s.firstname}')),
                            DataCell(Text(s.gender)),
                            DataCell(Text(s.phone)),
                            DataCell(
                              Chip(
                                label: Text(s.status, style: const TextStyle(color: Colors.white)),
                                backgroundColor: s.status == 'Actif' ? Colors.green : Colors.red,
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => StudentFormDialog(student: s),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      ref.read(studentsProvider.notifier).deleteStudent(s.id!);
                                    },
                                  ),
                                ],
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
}
