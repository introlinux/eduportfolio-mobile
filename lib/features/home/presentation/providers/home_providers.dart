import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/features/home/domain/usecases/count_pending_evidences_usecase.dart';
import 'package:eduportfolio/features/home/domain/usecases/get_default_subjects_usecase.dart';
import 'package:eduportfolio/features/home/domain/usecases/get_storage_info_usecase.dart';
import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// USECASE PROVIDERS
// ============================================================================

/// Provider for GetDefaultSubjectsUseCase
final getDefaultSubjectsUseCaseProvider =
    Provider<GetDefaultSubjectsUseCase>((ref) {
  final repository = ref.watch(subjectRepositoryProvider);
  return GetDefaultSubjectsUseCase(repository);
});

/// Provider for CountPendingEvidencesUseCase
final countPendingEvidencesUseCaseProvider =
    Provider<CountPendingEvidencesUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return CountPendingEvidencesUseCase(repository);
});

/// Provider for GetStorageInfoUseCase
final getStorageInfoUseCaseProvider = Provider<GetStorageInfoUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return GetStorageInfoUseCase(repository);
});

// ============================================================================
// DATA PROVIDERS
// ============================================================================

/// Provider to get default subjects
final defaultSubjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final useCase = ref.watch(getDefaultSubjectsUseCaseProvider);
  return useCase();
});

/// Provider to count pending evidences
/// Filters by active course if one is set
final pendingEvidencesCountProvider = FutureProvider<int>((ref) async {
  final useCase = ref.watch(countPendingEvidencesUseCaseProvider);
  final activeCourseAsync = ref.watch(activeCourseProvider);
  final activeCourse = activeCourseAsync.value;

  return useCase(courseId: activeCourse?.id);
});

/// Provider to get storage info
final storageInfoProvider = FutureProvider<StorageInfo>((ref) async {
  final useCase = ref.watch(getStorageInfoUseCaseProvider);
  return useCase();
});
