import 'dart:io';

import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/utils/logger.dart';

/// Deletes an evidence including its file and database record
///
/// WARNING: This operation cannot be undone
class DeleteEvidenceUseCase {
  final EvidenceRepository _repository;

  DeleteEvidenceUseCase(this._repository);

  /// Delete evidence
  ///
  /// Parameters:
  /// - [evidenceId]: ID of the evidence to delete
  ///
  /// Deletes:
  /// - Physical file (image/video/audio)
  /// - Thumbnail file (if exists)
  /// - Database record
  ///
  /// Throws exception if evidence not found
  Future<void> call(int evidenceId) async {
    final evidence = await _repository.getEvidenceById(evidenceId);

    if (evidence == null) {
      throw Exception('Evidence not found');
    }

    // Delete physical file
    try {
      final file = File(evidence.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      Logger.error('Error deleting file ${evidence.filePath}', e);
      // Continue even if file deletion fails
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
        // Continue even if thumbnail deletion fails
      }
    }

    // Delete database record
    await _repository.deleteEvidence(evidenceId);
  }
}
