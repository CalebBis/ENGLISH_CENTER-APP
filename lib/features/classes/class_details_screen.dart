import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'class_providers.dart';
import '../students/student_providers.dart';
import '../../core/models/student_model.dart';
import '../../core/models/class_model.dart';

/// Écran de détails d'une classe.
///
/// Affiche :
/// - Le nom de la classe sélectionnée.
/// - La liste des étudiants actuellement inscrits dans cette classe.
/// - Un bouton pour ajouter un étudiant à la classe.
/// - Un bouton de retour vers la liste des classes.
///
/// [classIdStr] : l'identifiant de la classe passé comme paramètre de route (sous forme de String).
class ClassDetailsScreen extends ConsumerWidget {
  /// Identifiant de la classe, reçu depuis l'URL de navigation (ex: '/classes/3' → '3').
  final String classIdStr;

  const ClassDetailsScreen({super.key, required this.classIdStr});

  /// Construit l'écran de détails de la classe.
  ///
  /// - Convertit [classIdStr] en entier.
  /// - Observe les étudiants inscrits dans la classe via [classStudentsProvider].
  /// - Observe toutes les classes pour retrouver le nom de la classe courante.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Conversion de l'ID textuel en entier (0 si la conversion échoue).
    final int classId = int.tryParse(classIdStr) ?? 0;

    // Observe la liste des étudiants inscrits dans cette classe (async).
    final studentsAsync = ref.watch(classStudentsProvider(classId));

    // Observe toutes les classes pour retrouver le nom de la classe courante.
    final classesAsync = ref.watch(classesProvider);

    // Cherche la classe correspondant à l'ID courant dans la liste chargée.
    ClassModel? currentClass;
    if (classesAsync.value != null) {
      currentClass = classesAsync.value!.firstWhere((c) => c.id == classId);
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- BARRE D'EN-TÊTE ---
          Row(
            children: [
              /// Bouton de retour : navigue vers la liste des classes (/classes).
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/classes'),
              ),
              const SizedBox(width: 16),

              /// Titre de l'écran avec le nom de la classe.
              Text(
                'Détails de la classe : ${currentClass?.name ?? ''}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              /// Espace flexible pour pousser le bouton d'ajout à droite.
              const Spacer(),

              /// Bouton "Ajouter un étudiant" : ouvre la boîte de dialogue
              /// de sélection d'un étudiant à inscrire dans la classe.
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

          /// --- TABLEAU DES ÉTUDIANTS INSCRITS ---
          Expanded(
            child: Card(
              /// Affichage réactif selon l'état asynchrone de [studentsAsync].
              child: studentsAsync.when(
                /// CAS : données chargées avec succès.
                data: (students) {
                  // Si aucun étudiant n'est inscrit, affiche un message informatif.
                  if (students.isEmpty) {
                    return const Center(child: Text('Aucun étudiant dans cette classe.'));
                  }

                  /// Tableau de données affichant les étudiants inscrits.
                  return ListView(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Nom')),       // Colonne : Nom complet
                          DataColumn(label: Text('Sexe')),      // Colonne : Sexe (M/F)
                          DataColumn(label: Text('Téléphone')), // Colonne : Téléphone
                          DataColumn(label: Text('Actions')),   // Colonne : Bouton suppression
                        ],
                        rows: students.map((s) {
                          return DataRow(cells: [
                            /// Affiche le nom de famille suivi du prénom.
                            DataCell(Text('${s.lastName} ${s.firstname}')),
                            DataCell(Text(s.gender)),
                            DataCell(Text(s.phone)),

                            /// Bouton de suppression d'un étudiant de la classe.
                            /// Appelle [removeStudentFromClass] puis actualise la liste.
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.person_remove, color: Colors.red),
                                onPressed: () async {
                                  // Supprime l'inscription de l'étudiant dans la BDD.
                                  await ref.read(classRepositoryProvider).removeStudentFromClass(s.id!, classId);
                                  // Rafraîchit la liste des étudiants affichée.
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

                /// CAS : chargement en cours → affiche un indicateur de progression.
                loading: () => const Center(child: CircularProgressIndicator()),

                /// CAS : erreur lors du chargement → affiche le message d'erreur.
                error: (e, st) => Center(child: Text('Erreur: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche une boîte de dialogue pour sélectionner un étudiant à inscrire dans la classe.
  ///
  /// Liste tous les étudiants existants dans le système et permet d'en ajouter un
  /// via le bouton "Ajouter" en face de chaque entrée.
  ///
  /// [context] : contexte Flutter pour afficher le dialogue.
  /// [ref]     : référence Riverpod pour accéder aux providers.
  /// [classId] : identifiant de la classe cible pour l'inscription.
  void _showAddStudentDialog(BuildContext context, WidgetRef ref, int classId) {
    showDialog(
      context: context,
      builder: (context) {
        /// [Consumer] permet d'accéder aux providers Riverpod dans un builder standard.
        return Consumer(
          builder: (context, ref, child) {
            // Observe la liste complète de tous les étudiants.
            final allStudentsAsync = ref.watch(studentsProvider);

            return AlertDialog(
              title: const Text('Sélectionner un étudiant'),
              content: SizedBox(
                width: 400,
                height: 400, // Hauteur fixe pour permettre le défilement
                child: allStudentsAsync.when(
                  /// CAS : étudiants chargés → affiche la liste avec bouton "Ajouter".
                  data: (students) {
                    return ListView.builder(
                      itemCount: students.length,
                      /// Construit une tuile par étudiant.
                      itemBuilder: (context, index) {
                        final s = students[index];
                        return ListTile(
                          title: Text('${s.lastName} ${s.firstname}'),
                          subtitle: Text(s.phone),

                          /// Bouton "Ajouter" : inscrit l'étudiant dans la classe.
                          trailing: ElevatedButton(
                            child: const Text('Ajouter'),
                            onPressed: () async {
                              // Enregistre l'inscription en base de données.
                              await ref.read(classRepositoryProvider).enrollStudent(
                                s.id!, classId, DateTime.now().toIso8601String(),
                              );
                              // Actualise la liste affichée dans l'écran parent.
                              ref.refresh(classStudentsProvider(classId));
                              // Ferme la boîte de dialogue.
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
                /// Bouton "Fermer" : ferme la boîte de dialogue sans modification.
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
