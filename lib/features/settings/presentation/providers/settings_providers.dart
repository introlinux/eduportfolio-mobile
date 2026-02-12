import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/core/services/app_settings_service.dart';
import 'package:eduportfolio/features/settings/domain/usecases/delete_all_evidences_usecase.dart';
import 'package:eduportfolio/features/settings/domain/usecases/delete_all_students_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// SERVICE PROVIDERS
// ============================================================================

// ============================================================================
// SERVICE PROVIDERS
// ============================================================================

// Shared providers moved to core_providers.dart

// ============================================================================
// USECASE PROVIDERS
// ============================================================================

/// Provider for DeleteAllEvidencesUseCase
final deleteAllEvidencesUseCaseProvider =
    Provider<DeleteAllEvidencesUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return DeleteAllEvidencesUseCase(repository);
});

/// Provider for DeleteAllStudentsUseCase
final deleteAllStudentsUseCaseProvider =
    Provider<DeleteAllStudentsUseCase>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return DeleteAllStudentsUseCase(repository);
});
