import 'dart:io';

import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/utils/logger.dart';

/// Deletes multiple evidences in a batch operation
///
/// WARNING: This operation cannot be undone
class DeleteMultipleEvidencesUseCase {
  final EvidenceRepository _repository;

  DeleteMultipleEvidencesUseCase(this._repository);

  /// Delete multiple evidences
  ///
  /// Parameters:
  /// - [evidenceIds]: List of evidence IDs to delete
  ///
  /// Deletes files and database records for all evidences
  /// Continues on error (logs but doesn't throw)
  ///
  /// Returns number of successfully deleted evidences
  Future<int> call(List<int> evidenceIds) async {
    if (evidenceIds.isEmpty) {
      return 0; // Nothing to do
    }

    int deletedCount = 0;

    // Process each evidence
    for (final evidenceId in evidenceIds) {
      try {
        final evidence = await _repository.getEvidenceById(evidenceId);

        if (evidence == null) {
          // Skip missing evidence
          continue;
        }

        // Delete physical file
        try {
          final file = File(evidence.filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          Logger.error('Error deleting file ${evidence.filePath}', e);
          // Continue anyway
        }

        // Delete thumbnail if exists
        if (evidence.thumbnailPath != null) {
          try {
            final thumbnail = File(evidence.thumbnailPath!);
            if (await thumbnail.exists()) {
              await thumbnail.delete();
            }
          } catch (e) {
            Logger.error('Error deleting thumbnail ${evidence.thumbnailPath}', e);
            // Continue anyway
          }
        }

        // Delete database record
        await _repository.deleteEvidence(evidenceId);
        deletedCount++;
      } catch (e) {
        // Log error but continue with remaining evidences
        Logger.error('Error deleting evidence $evidenceId', e);
      }
    }

    return deletedCount;
  }
}
