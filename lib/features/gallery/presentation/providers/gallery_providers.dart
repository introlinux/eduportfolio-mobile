import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/delete_evidence_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_all_evidences_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_evidence_by_id_usecase.dart';
import 'package:eduportfolio/features/gallery/domain/usecases/get_evidences_by_subject_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// ============================================================================
// STATE PROVIDERS
// ============================================================================

/// Provider for selected subject filter (null = show all)
/// Auto-disposes when not in use (resets filter when leaving gallery)
final selectedSubjectFilterProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Provider for selected student filter (null = show all)
/// Auto-disposes when not in use (resets filter when leaving gallery)
final selectedStudentFilterProvider = StateProvider.autoDispose<int?>((ref) => null);

// ============================================================================
// DATA PROVIDERS
// ============================================================================

/// Provider to get evidences with optional subject and student filters
/// Ordered by capture date (most recent first)
final filteredEvidencesProvider = FutureProvider.autoDispose<List<Evidence>>((ref) async {
  final selectedSubjectId = ref.watch(selectedSubjectFilterProvider);
  final selectedStudentId = ref.watch(selectedStudentFilterProvider);

  // Get all evidences first
  final getAllUseCase = ref.watch(getAllEvidencesUseCaseProvider);
  var evidences = await getAllUseCase();

  // Apply subject filter if selected
  if (selectedSubjectId != null) {
    evidences = evidences.where((e) => e.subjectId == selectedSubjectId).toList();
  }

  // Apply student filter if selected
  if (selectedStudentId != null) {
    evidences = evidences.where((e) => e.studentId == selectedStudentId).toList();
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
