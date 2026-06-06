import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'teacher_providers.dart';
import 'teacher_form_dialog.dart';

class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(teachersProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enseignants',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const TeacherFormDialog(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un enseignant'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              child: teachersAsync.when(
                data: (teachers) {
                  if (teachers.isEmpty) {
                    return const Center(child: Text('Aucun enseignant trouvé.'));
                  }
                  return ListView(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Nom')),
                          DataColumn(label: Text('Sexe')),
                          DataColumn(label: Text('Téléphone')),
                          DataColumn(label: Text('Spécialité')),
                          DataColumn(label: Text('Statut')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: teachers.map((t) {
                          return DataRow(cells: [
                            DataCell(Text('${t.lastName} ${t.firstname}')),
                            DataCell(Text(t.gender)),
                            DataCell(Text(t.phone)),
                            DataCell(Text(t.specialty)),
                            DataCell(
                              Chip(
                                label: Text(t.status, style: const TextStyle(color: Colors.white)),
                                backgroundColor: t.status == 'Actif' ? Colors.green : Colors.red,
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
                                        builder: (_) => TeacherFormDialog(teacher: t),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      ref.read(teachersProvider.notifier).deleteTeacher(t.id!);
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

