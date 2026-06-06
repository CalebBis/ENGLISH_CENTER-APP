import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/class_model.dart';
import '../../core/models/student_model.dart';
import 'class_repository.dart';

final classRepositoryProvider = Provider((ref) => ClassRepository());

final classesProvider = AsyncNotifierProvider<ClassesNotifier, List<ClassModel>>(() {
  return ClassesNotifier();
});

class ClassesNotifier extends AsyncNotifier<List<ClassModel>> {
  @override
  Future<List<ClassModel>> build() async {
    return await ref.watch(classRepositoryProvider).getAllClasses();
  }

  Future<void> addClass(ClassModel classModel) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(classRepositoryProvider).insertClass(classModel);
      return ref.read(classRepositoryProvider).getAllClasses();
    });
  }

  Future<void> updateClass(ClassModel classModel) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(classRepositoryProvider).updateClass(classModel);
      return ref.read(classRepositoryProvider).getAllClasses();
    });
  }

  Future<void> deleteClass(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(classRepositoryProvider).deleteClass(id);
      return ref.read(classRepositoryProvider).getAllClasses();
    });
  }
}

final levelsProvider = FutureProvider<List<LevelModel>>((ref) async {
  return ref.watch(classRepositoryProvider).getAllLevels();
});

final classStudentsProvider = FutureProvider.family<List<StudentModel>, int>((ref, classId) async {
  return ref.watch(classRepositoryProvider).getStudentsByClass(classId);
});
