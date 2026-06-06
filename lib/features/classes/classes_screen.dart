import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'class_providers.dart';
import 'class_form_dialog.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Classes & Niveaux',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const ClassFormDialog(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer une classe'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              child: classesAsync.when(
                data: (classes) {
                  if (classes.isEmpty) {
                    return const Center(child: Text('Aucune classe trouvée.'));
                  }
                  return ListView(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Nom de classe')),
                          DataColumn(label: Text('Horaire')),
                          DataColumn(label: Text('Salle')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: classes.map((c) {
                          return DataRow(cells: [
                            DataCell(Text(c.name)),
                            DataCell(Text(c.schedule)),
                            DataCell(Text(c.room)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.green),
                                    tooltip: 'Voir les étudiants',
                                    onPressed: () {
                                      context.go('/classes/${c.id}');
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => ClassFormDialog(classModel: c),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      ref.read(classesProvider.notifier).deleteClass(c.id!);
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
