import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/features/capture/domain/usecases/save_evidence_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// USECASE PROVIDERS
// ============================================================================

/// Provider for SaveEvidenceUseCase
final saveEvidenceUseCaseProvider = Provider<SaveEvidenceUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return SaveEvidenceUseCase(repository);
});

// ============================================================================
// STATE PROVIDERS
// ============================================================================

/// Provider for selected image path
final selectedImagePathProvider = StateProvider<String?>((ref) => null);

/// Provider for selected subject ID
final selectedSubjectIdProvider = StateProvider<int?>((ref) => null);

/// Provider for loading state during save
final isSavingProvider = StateProvider<bool>((ref) => false);
