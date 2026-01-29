import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/features/students/domain/usecases/create_student_usecase.dart';
import 'package:eduportfolio/features/students/domain/usecases/delete_student_usecase.dart';
import 'package:eduportfolio/features/students/domain/usecases/get_all_students_usecase.dart';
import 'package:eduportfolio/features/students/domain/usecases/get_student_by_id_usecase.dart';
import 'package:eduportfolio/features/students/domain/usecases/get_students_by_course_usecase.dart';
import 'package:eduportfolio/features/students/domain/usecases/update_student_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// USECASE PROVIDERS
// ============================================================================

/// Provider for GetAllStudentsUseCase
final getAllStudentsUseCaseProvider = Provider<GetAllStudentsUseCase>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return GetAllStudentsUseCase(repository);
});

/// Provider for GetStudentsByCourseUseCase
final getStudentsByCourseUseCaseProvider =
    Provider<GetStudentsByCourseUseCase>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return GetStudentsByCourseUseCase(repository);
});

/// Provider for GetStudentByIdUseCase
final getStudentByIdUseCaseProvider = Provider<GetStudentByIdUseCase>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return GetStudentByIdUseCase(repository);
});

/// Provider for CreateStudentUseCase
final createStudentUseCaseProvider = Provider<CreateStudentUseCase>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return CreateStudentUseCase(repository);
});

/// Provider for UpdateStudentUseCase
final updateStudentUseCaseProvider = Provider<UpdateStudentUseCase>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return UpdateStudentUseCase(repository);
});

/// Provider for DeleteStudentUseCase
final deleteStudentUseCaseProvider = Provider<DeleteStudentUseCase>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return DeleteStudentUseCase(repository);
});

// ============================================================================
// STATE PROVIDERS
// ============================================================================

/// Provider for selected course filter (null = show all)
final selectedCourseFilterProvider = StateProvider<int?>((ref) => null);

// ============================================================================
// DATA PROVIDERS
// ============================================================================

/// Provider to get students with optional course filter
final filteredStudentsProvider = FutureProvider<List<Student>>((ref) async {
  final selectedCourseId = ref.watch(selectedCourseFilterProvider);

  if (selectedCourseId == null) {
    // No filter, get all students
    final getAllUseCase = ref.watch(getAllStudentsUseCaseProvider);
    return getAllUseCase();
  } else {
    // Filter by course
    final getByCourseUseCase = ref.watch(getStudentsByCourseUseCaseProvider);
    return getByCourseUseCase(selectedCourseId);
  }
});

/// Provider to get a single student by ID
final studentByIdProvider =
    FutureProvider.family<Student?, int>((ref, studentId) async {
  final useCase = ref.watch(getStudentByIdUseCaseProvider);
  return useCase(studentId);
});

/// Provider to count students by course
final studentCountByCourseProvider =
    FutureProvider.family<int, int>((ref, courseId) async {
  final students = await ref.watch(getStudentsByCourseUseCaseProvider)(courseId);
  return students.length;
});
