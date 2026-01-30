import 'dart:io';

import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';

/// Deletes all evidences from the database and their physical files
///
/// This is a destructive operation used for cleaning/resetting the system
class DeleteAllEvidencesUseCase {
  final EvidenceRepository _repository;

  DeleteAllEvidencesUseCase(this._repository);

  /// Delete all evidences and their files
  ///
  /// Returns the number of evidences deleted
  Future<int> call() async {
    final allEvidences = await _repository.getAllEvidences();
    int deletedCount = 0;

    for (final evidence in allEvidences) {
      try {
        // Delete physical file
        final file = File(evidence.filePath);
        if (await file.exists()) {
          await file.delete();
        }

        // Delete thumbnail if exists
        if (evidence.thumbnailPath != null) {
          final thumbnail = File(evidence.thumbnailPath!);
          if (await thumbnail.exists()) {
            await thumbnail.delete();
          }
        }

        // Delete from database
        await _repository.deleteEvidence(evidence.id!);
        deletedCount++;
      } catch (e) {
        print('Error deleting evidence ${evidence.id}: $e');
        // Continue with next evidence
      }
    }

    return deletedCount;
  }
}
