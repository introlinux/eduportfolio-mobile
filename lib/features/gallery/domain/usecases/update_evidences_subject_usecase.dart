import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/utils/logger.dart';

/// Use case to update subject for multiple evidences
class UpdateEvidencesSubjectUseCase {
  final EvidenceRepository repository;

  UpdateEvidencesSubjectUseCase(this.repository);

  /// Updates the subject for multiple evidences
  /// Returns the number of evidences successfully updated
  Future<int> call(List<int> evidenceIds, int subjectId) async {
    int successCount = 0;

    for (final evidenceId in evidenceIds) {
      try {
        final evidence = await repository.getEvidenceById(evidenceId);
        if (evidence != null) {
          final updated = evidence.copyWith(subjectId: subjectId);
          await repository.updateEvidence(updated);
          successCount++;
        }
      } catch (e) {
        // Log error but continue with other evidences
        Logger.error('Error updating evidence $evidenceId', e);
      }
    }

    return successCount;
  }
}
