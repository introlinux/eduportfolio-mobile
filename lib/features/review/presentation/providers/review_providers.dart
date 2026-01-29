import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/features/review/domain/usecases/assign_evidence_to_student_usecase.dart';
import 'package:eduportfolio/features/review/domain/usecases/assign_multiple_evidences_usecase.dart';
import 'package:eduportfolio/features/review/domain/usecases/delete_evidence_usecase.dart';
import 'package:eduportfolio/features/review/domain/usecases/delete_multiple_evidences_usecase.dart';
import 'package:eduportfolio/features/review/domain/usecases/get_unassigned_evidences_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// USECASE PROVIDERS
// ============================================================================

/// Provider for GetUnassignedEvidencesUseCase
final getUnassignedEvidencesUseCaseProvider =
    Provider<GetUnassignedEvidencesUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return GetUnassignedEvidencesUseCase(repository);
});

/// Provider for AssignEvidenceToStudentUseCase
final assignEvidenceToStudentUseCaseProvider =
    Provider<AssignEvidenceToStudentUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return AssignEvidenceToStudentUseCase(repository);
});

/// Provider for AssignMultipleEvidencesUseCase
final assignMultipleEvidencesUseCaseProvider =
    Provider<AssignMultipleEvidencesUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return AssignMultipleEvidencesUseCase(repository);
});

/// Provider for DeleteEvidenceUseCase
final deleteEvidenceUseCaseProvider = Provider<DeleteEvidenceUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return DeleteEvidenceUseCase(repository);
});

/// Provider for DeleteMultipleEvidencesUseCase
final deleteMultipleEvidencesUseCaseProvider =
    Provider<DeleteMultipleEvidencesUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return DeleteMultipleEvidencesUseCase(repository);
});

// ============================================================================
// STATE PROVIDERS
// ============================================================================

/// Provider for selection mode (enable/disable checkboxes)
final selectionModeProvider = StateProvider<bool>((ref) => false);

/// Provider for selected evidence IDs
final selectedEvidencesProvider = StateProvider<Set<int>>((ref) => {});

/// Provider for subject filter in review screen (optional)
final reviewSubjectFilterProvider = StateProvider<int?>((ref) => null);

// ============================================================================
// DATA PROVIDERS
// ============================================================================

/// Provider to get all unassigned evidences
final unassignedEvidencesProvider = FutureProvider<List<Evidence>>((ref) async {
  final useCase = ref.watch(getUnassignedEvidencesUseCaseProvider);
  final subjectFilter = ref.watch(reviewSubjectFilterProvider);

  return useCase(subjectId: subjectFilter);
});

/// Provider to count unassigned evidences
final unassignedCountProvider = FutureProvider<int>((ref) async {
  final evidences = await ref.watch(unassignedEvidencesProvider.future);
  return evidences.length;
});
