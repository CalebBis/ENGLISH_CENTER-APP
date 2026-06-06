import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/teacher_model.dart';
import 'teacher_repository.dart';

final teacherRepositoryProvider = Provider((ref) => TeacherRepository());

final teachersProvider = AsyncNotifierProvider<TeachersNotifier, List<TeacherModel>>(() {
  return TeachersNotifier();
});

class TeachersNotifier extends AsyncNotifier<List<TeacherModel>> {
  @override
  Future<List<TeacherModel>> build() async {
    return await ref.watch(teacherRepositoryProvider).getAllTeachers();
  }

  Future<void> addTeacher(TeacherModel teacher) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(teacherRepositoryProvider).insertTeacher(teacher);
      return ref.read(teacherRepositoryProvider).getAllTeachers();
    });
  }

  Future<void> updateTeacher(TeacherModel teacher) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(teacherRepositoryProvider).updateTeacher(teacher);
      return ref.read(teacherRepositoryProvider).getAllTeachers();
    });
  }

  Future<void> deleteTeacher(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(teacherRepositoryProvider).deleteTeacher(id);
      return ref.read(teacherRepositoryProvider).getAllTeachers();
    });
  }
}
