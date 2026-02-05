import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/features/courses/domain/usecases/archive_course_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/create_course_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/delete_course_with_files_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/get_active_course_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/get_all_courses_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/set_active_course_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/unarchive_course_usecase.dart';
import 'package:eduportfolio/features/courses/domain/usecases/update_course_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// USECASE PROVIDERS
// ============================================================================

/// Provider for GetAllCoursesUseCase
final getAllCoursesUseCaseProvider = Provider<GetAllCoursesUseCase>((ref) {
  final repository = ref.watch(courseRepositoryProvider);
  return GetAllCoursesUseCase(repository);
});

/// Provider for GetActiveCourseUseCase
final getActiveCourseUseCaseProvider = Provider<GetActiveCourseUseCase>((ref) {
  final repository = ref.watch(courseRepositoryProvider);
  return GetActiveCourseUseCase(repository);
});

/// Provider for CreateCourseUseCase
final createCourseUseCaseProvider = Provider<CreateCourseUseCase>((ref) {
  final repository = ref.watch(courseRepositoryProvider);
  return CreateCourseUseCase(repository);
});

/// Provider for UpdateCourseUseCase
final updateCourseUseCaseProvider = Provider<UpdateCourseUseCase>((ref) {
  final repository = ref.watch(courseRepositoryProvider);
  return UpdateCourseUseCase(repository);
});

/// Provider for ArchiveCourseUseCase
final archiveCourseUseCaseProvider = Provider<ArchiveCourseUseCase>((ref) {
  final repository = ref.watch(courseRepositoryProvider);
  return ArchiveCourseUseCase(repository);
});

/// Provider for SetActiveCourseUseCase
final setActiveCourseUseCaseProvider = Provider<SetActiveCourseUseCase>((ref) {
  final repository = ref.watch(courseRepositoryProvider);
  return SetActiveCourseUseCase(repository);
});

/// Provider for UnarchiveCourseUseCase
final unarchiveCourseUseCaseProvider = Provider<UnarchiveCourseUseCase>((ref) {
  final repository = ref.watch(courseRepositoryProvider);
  return UnarchiveCourseUseCase(repository);
});

/// Provider for DeleteCourseWithFilesUseCase
final deleteCourseWithFilesUseCaseProvider = Provider<DeleteCourseWithFilesUseCase>((ref) {
  final repository = ref.watch(courseRepositoryProvider);
  return DeleteCourseWithFilesUseCase(repository);
});

// ============================================================================
// DATA PROVIDERS
// ============================================================================

/// Provider to get the active course
final activeCourseProvider = FutureProvider<Course?>((ref) async {
  final useCase = ref.watch(getActiveCourseUseCaseProvider);
  return useCase();
});

/// Provider to get all courses
final allCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final useCase = ref.watch(getAllCoursesUseCaseProvider);
  return useCase();
});

/// Provider to get active (non-archived) courses
final activeCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final allCourses = await ref.watch(allCoursesProvider.future);
  return allCourses.where((course) => course.endDate == null).toList();
});

/// Provider to get archived courses
final archivedCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final allCourses = await ref.watch(allCoursesProvider.future);
  return allCourses.where((course) => course.endDate != null).toList();
});

/// Provider to count students in a course
final courseStudentCountProvider =
    FutureProvider.family<int, int>((ref, courseId) async {
  final repository = ref.watch(studentRepositoryProvider);
  return await repository.countStudentsByCourse(courseId);
});
