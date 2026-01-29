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
final selectedSubjectFilterProvider = StateProvider<int?>((ref) => null);

// ============================================================================
// DATA PROVIDERS
// ============================================================================

/// Provider to get evidences with optional subject filter
final filteredEvidencesProvider = FutureProvider<List<Evidence>>((ref) async {
  final selectedSubjectId = ref.watch(selectedSubjectFilterProvider);

  if (selectedSubjectId == null) {
    // No filter, get all evidences
    final getAllUseCase = ref.watch(getAllEvidencesUseCaseProvider);
    return getAllUseCase();
  } else {
    // Filter by subject
    final getBySubjectUseCase = ref.watch(getEvidencesBySubjectUseCaseProvider);
    return getBySubjectUseCase(selectedSubjectId);
  }
});

/// Provider to get a single evidence by ID
final evidenceByIdProvider =
    FutureProvider.family<Evidence?, int>((ref, evidenceId) async {
  final useCase = ref.watch(getEvidenceByIdUseCaseProvider);
  return useCase(evidenceId);
});
