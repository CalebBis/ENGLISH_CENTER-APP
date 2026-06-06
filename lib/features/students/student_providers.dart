import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/student_model.dart';
import 'student_repository.dart';

final studentRepositoryProvider = Provider((ref) => StudentRepository());

final studentsProvider = AsyncNotifierProvider<StudentsNotifier, List<StudentModel>>(() {
  return StudentsNotifier();
});

class StudentsNotifier extends AsyncNotifier<List<StudentModel>> {
  @override
  Future<List<StudentModel>> build() async {
    return await ref.watch(studentRepositoryProvider).getAllStudents();
  }

  Future<void> addStudent(StudentModel student) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).insertStudent(student);
      return ref.read(studentRepositoryProvider).getAllStudents();
    });
  }

  Future<void> updateStudent(StudentModel student) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).updateStudent(student);
      return ref.read(studentRepositoryProvider).getAllStudents();
    });
  }

  Future<void> deleteStudent(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).deleteStudent(id);
      return ref.read(studentRepositoryProvider).getAllStudents();
    });
  }
}
