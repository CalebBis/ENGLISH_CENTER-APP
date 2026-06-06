import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/student_model.dart';
import 'student_repository.dart';

/// Provider Riverpod qui fournit une instance unique de [StudentRepository].
///
/// En exposant le repository via un [Provider], on facilite les tests unitaires
/// (possibilité de substituer le repository par un mock) et on centralise
/// la gestion des dépendances.
final studentRepositoryProvider = Provider((ref) => StudentRepository());

/// Provider Riverpod asynchrone qui expose la liste des étudiants et gère leur état.
///
/// C'est un [AsyncNotifierProvider] : il combine la gestion asynchrone (chargement,
/// erreur, données) avec la possibilité de modifier l'état (ajout, modification, suppression).
///
/// Les widgets qui observent ce provider se reconstruisent automatiquement
/// à chaque changement de la liste des étudiants.
final studentsProvider = AsyncNotifierProvider<StudentsNotifier, List<StudentModel>>(() {
  return StudentsNotifier();
});

/// Notifier qui gère l'état de la liste des étudiants.
///
/// Hérite de [AsyncNotifier] ce qui lui permet de gérer les états :
/// - `loading` : chargement en cours.
/// - `data`    : liste des étudiants disponible.
/// - `error`   : une erreur s'est produite.
///
/// Expose des méthodes pour modifier la liste (ajout, modification, suppression).
class StudentsNotifier extends AsyncNotifier<List<StudentModel>> {
  /// Charge la liste initiale des étudiants depuis la base de données.
  ///
  /// Cette méthode est appelée automatiquement par Riverpod lors de la
  /// première utilisation du provider. Elle récupère tous les étudiants via le repository.
  @override
  Future<List<StudentModel>> build() async {
    return await ref.watch(studentRepositoryProvider).getAllStudents();
  }

  /// Ajoute un nouvel étudiant dans la base de données et actualise la liste.
  ///
  /// Étapes :
  /// 1. Passe l'état en `loading` pour indiquer le chargement aux widgets observateurs.
  /// 2. Insère l'étudiant via [StudentRepository.insertStudent].
  /// 3. Recharge la liste complète depuis la BDD et la retourne comme nouvel état.
  ///
  /// [AsyncValue.guard] capture automatiquement les exceptions et passe à l'état `error`.
  Future<void> addStudent(StudentModel student) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).insertStudent(student);
      return ref.read(studentRepositoryProvider).getAllStudents();
    });
  }

  /// Modifie un étudiant existant dans la base de données et actualise la liste.
  ///
  /// Même mécanisme que [addStudent] mais appelle [updateStudent] sur le repository.
  /// L'ID de l'étudiant dans [student] identifie la ligne à mettre à jour.
  Future<void> updateStudent(StudentModel student) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).updateStudent(student);
      return ref.read(studentRepositoryProvider).getAllStudents();
    });
  }

  /// Supprime un étudiant par son [id] et actualise la liste.
  ///
  /// [id] : l'identifiant unique de l'étudiant à supprimer.
  /// Après la suppression, la liste est rechargée pour refléter les changements dans l'UI.
  Future<void> deleteStudent(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).deleteStudent(id);
      return ref.read(studentRepositoryProvider).getAllStudents();
    });
  }
}
