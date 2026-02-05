import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/assign_evidences_to_student_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/delete_evidence_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/delete_evidences_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_all_evidences_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_evidence_by_id_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_evidences_by_subject_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/update_evidences_subject_usecase.dart';
import 'package:eduportfolio/core/services/face_recognition/face_recognition_providers.dart';
import 'package:eduportfolio/features/gallery/domain/services/privacy_service.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/update_evidences_subject_usecase.dart';
import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Review status filter options for gallery
enum ReviewStatusFilter {
  all, // Show all evidences
  pending, // Show only pending review (isReviewed = false)
  reviewed, // Show only reviewed (isReviewed = true)
}

// ============================================================================
// USECASE PROVIDERS
// ============================================================================

/// Provider for GetAllEvidencesUseCase
final getAllEvidencesUseCaseProvider =
    Provider<GetAllEvidencesUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return GetAllEvidencesUseCase(repository);
});

/// Provider for GetEvidencesBySubjectUseCase
final getEvidencesBySubjectUseCaseProvider =
    Provider<GetEvidencesBySubjectUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return GetEvidencesBySubjectUseCase(repository);
});

/// Provider for DeleteEvidenceUseCase
final deleteEvidenceUseCaseProvider = Provider<DeleteEvidenceUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return DeleteEvidenceUseCase(repository);
});

/// Provider for GetEvidenceByIdUseCase
final getEvidenceByIdUseCaseProvider =
    Provider<GetEvidenceByIdUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return GetEvidenceByIdUseCase(repository);
});

/// Provider for UpdateEvidencesSubjectUseCase
final updateEvidencesSubjectUseCaseProvider =
    Provider<UpdateEvidencesSubjectUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return UpdateEvidencesSubjectUseCase(repository);
});

/// Provider for AssignEvidencesToStudentUseCase
final assignEvidencesToStudentUseCaseProvider =
    Provider<AssignEvidencesToStudentUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return AssignEvidencesToStudentUseCase(repository);
});

/// Provider for DeleteEvidencesUseCase (batch delete)
final deleteEvidencesUseCaseProvider = Provider<DeleteEvidencesUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return DeleteEvidencesUseCase(repository);
});

/// Provider for PrivacyService
final privacyServiceProvider = Provider<PrivacyService>((ref) {
  final faceDetectorService = ref.watch(faceDetectorServiceProvider);
  return PrivacyService(faceDetectorService);
});

// ============================================================================
// STATE PROVIDERS
// ============================================================================

/// Provider for selected subject filter (null = show all)
/// Auto-disposes when not in use (resets filter when leaving gallery)
final selectedSubjectFilterProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Provider for selected student filter (null = show all)
/// Auto-disposes when not in use (resets filter when leaving gallery)
final selectedStudentFilterProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Provider for review status filter (defaults to all)
/// Auto-disposes when not in use (resets filter when leaving gallery)
final reviewStatusFilterProvider = StateProvider.autoDispose<ReviewStatusFilter>(
  (ref) => ReviewStatusFilter.all,
);

// ============================================================================
// DATA PROVIDERS
// ============================================================================

/// Provider to get evidences with optional subject, student, and review status filters
/// Ordered by capture date (most recent first)
final filteredEvidencesProvider = FutureProvider.autoDispose<List<Evidence>>((ref) async {
  final selectedSubjectId = ref.watch(selectedSubjectFilterProvider);
  final selectedStudentId = ref.watch(selectedStudentFilterProvider);
  final reviewStatusFilter = ref.watch(reviewStatusFilterProvider);
  final activeCourseAsync = ref.watch(activeCourseProvider);
  final activeCourse = activeCourseAsync.value;

  // Get all evidences first
  final getAllUseCase = ref.watch(getAllEvidencesUseCaseProvider);
  var evidences = await getAllUseCase();

  // Apply course filter if active course exists
  if (activeCourse != null) {
    evidences = evidences.where((e) => e.courseId == null || e.courseId == activeCourse.id).toList();
  }

  // Apply subject filter if selected
  if (selectedSubjectId != null) {
    evidences = evidences.where((e) => e.subjectId == selectedSubjectId).toList();
  }

  // Apply student filter if selected
  if (selectedStudentId != null) {
    evidences = evidences.where((e) => e.studentId == selectedStudentId).toList();
  }

  // Apply review status filter
  switch (reviewStatusFilter) {
    case ReviewStatusFilter.pending:
      evidences = evidences.where((e) => !e.isReviewed).toList();
      break;
    case ReviewStatusFilter.reviewed:
      evidences = evidences.where((e) => e.isReviewed).toList();
      break;
    case ReviewStatusFilter.all:
      // No filtering needed
      break;
  }

  // Sort by capture date (most recent first)
  evidences.sort((a, b) => b.captureDate.compareTo(a.captureDate));

  return evidences;
});

/// Provider to get a single evidence by ID
final evidenceByIdProvider =
    FutureProvider.family<Evidence?, int>((ref, evidenceId) async {
  final useCase = ref.watch(getEvidenceByIdUseCaseProvider);
  return useCase(evidenceId);
});
