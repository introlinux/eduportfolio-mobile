import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:image/image.dart' as img;
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
  /// - [courseId]: Optional course ID for the active course
  ///
  /// Returns the ID of the created evidence
  Future<int> call({
    required String tempImagePath,
    required int subjectId,
    int? studentId,
    int? courseId,
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

    // Read and fix image orientation from EXIF metadata
    final tempFile = File(tempImagePath);
    final bytes = await tempFile.readAsBytes();
    final image = img.decodeImage(bytes);

    int fileSize;

    if (image != null) {
      // Apply EXIF orientation to fix rotation issues
      // This corrects images captured in landscape/portrait modes
      final orientedImage = img.bakeOrientation(image);

      // Encode and save the corrected image
      final correctedBytes = img.encodeJpg(orientedImage, quality: 90);
      await File(permanentPath).writeAsBytes(correctedBytes);

      fileSize = correctedBytes.length;
      print('✓ Image orientation corrected and saved: $permanentPath');
    } else {
      // Fallback: if image can't be decoded, just copy as-is
      await tempFile.copy(permanentPath);
      fileSize = await tempFile.length();
      print('⚠️  Could not decode image, saved without orientation fix');
    }

    final now = DateTime.now();

    // Create Evidence entity
    final evidence = Evidence(
      subjectId: subjectId,
      type: EvidenceType.image,
      filePath: permanentPath,
      captureDate: now,
      createdAt: now,
      studentId: studentId,
      courseId: courseId,
      fileSize: fileSize,
      // Mark as reviewed if facial recognition assigned a student
      // Only evidences without student assignment need manual review
      isReviewed: studentId != null,
    );

    // Save to database and return the ID
    final evidenceId = await _repository.createEvidence(evidence);

    return evidenceId;
  }
}
