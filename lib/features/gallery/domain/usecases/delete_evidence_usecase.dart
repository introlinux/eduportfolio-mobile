import 'dart:io';

import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';

/// UseCase to delete an evidence
///
/// Deletes both the database record and the physical file
class DeleteEvidenceUseCase {
  final EvidenceRepository _repository;

  DeleteEvidenceUseCase(this._repository);

  /// Delete evidence by ID
  ///
  /// This will:
  /// 1. Get the evidence from DB to retrieve file path
  /// 2. Delete the physical file
  /// 3. Delete the database record
  Future<void> call(int evidenceId) async {
    // Get evidence to retrieve file path
    final evidence = await _repository.getEvidenceById(evidenceId);

    if (evidence == null) {
      throw Exception('Evidence not found: $evidenceId');
    }

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

    // Delete database record
    await _repository.deleteEvidence(evidenceId);
  }
}
