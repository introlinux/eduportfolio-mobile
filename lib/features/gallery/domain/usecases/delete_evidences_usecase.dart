import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/utils/logger.dart';

/// Use case to delete multiple evidences
class DeleteEvidencesUseCase {
  final EvidenceRepository repository;

  DeleteEvidencesUseCase(this.repository);

  /// Deletes multiple evidences
  /// Returns the number of evidences successfully deleted
  Future<int> call(List<int> evidenceIds) async {
    int successCount = 0;

    for (final evidenceId in evidenceIds) {
      try {
        await repository.deleteEvidence(evidenceId);
        successCount++;
      } catch (e) {
        // Log error but continue with other evidences
        Logger.error('Error deleting evidence $evidenceId', e);
      }
    }

    return successCount;
  }
}
