import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// UseCase for saving captured evidence
///
/// Takes an image file path (temporary), copies it to permanent storage,
/// and creates an Evidence record in the database
class SaveEvidenceUseCase {
  final EvidenceRepository _repository;

  SaveEvidenceUseCase(this._repository);

  /// Save evidence from a captured/picked image
  ///
  /// Parameters:
  /// - [tempImagePath]: Temporary path from image_picker
  /// - [subjectId]: ID of the subject this evidence belongs to
  /// - [studentId]: Optional student ID if already assigned
  ///
  /// Returns the ID of the created evidence
  Future<int> call({
    required String tempImagePath,
    required int subjectId,
    int? studentId,
  }) async {
    // Get app's documents directory for permanent storage
    final directory = await getApplicationDocumentsDirectory();
    final evidencesDir = Directory('${directory.path}/evidences');

    // Create evidences directory if it doesn't exist
    if (!await evidencesDir.exists()) {
      await evidencesDir.create(recursive: true);
    }

    // Generate unique filename using timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(tempImagePath);
    final fileName = 'evidence_$timestamp$extension';
    final permanentPath = '${evidencesDir.path}/$fileName';

    // Copy file from temporary location to permanent storage
    final tempFile = File(tempImagePath);
    await tempFile.copy(permanentPath);

    // Get file size
    final fileSize = await tempFile.length();

    final now = DateTime.now();

    // Create Evidence entity
    final evidence = Evidence(
      subjectId: subjectId,
      type: EvidenceType.image,
      filePath: permanentPath,
      captureDate: now,
      createdAt: now,
      studentId: studentId,
      fileSize: fileSize,
      // TODO: When real face recognition is implemented, mark as reviewed if studentId != null
      // For now, always mark as not reviewed since face recognition is in placeholder mode
      isReviewed: false,
    );

    // Save to database and return the ID
    final evidenceId = await _repository.createEvidence(evidence);

    return evidenceId;
  }
}
