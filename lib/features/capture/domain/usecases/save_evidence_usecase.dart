import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/domain/repositories/subject_repository.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';
import 'package:eduportfolio/core/utils/file_naming_utils.dart';
import 'package:eduportfolio/core/utils/logger.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// UseCase for saving captured evidence
///
/// Takes an image file path (temporary), copies it to permanent storage,
/// and creates an Evidence record in the database
class SaveEvidenceUseCase {
  final EvidenceRepository _repository;
  final SubjectRepository _subjectRepository;
  final StudentRepository _studentRepository;

  SaveEvidenceUseCase(
    this._repository,
    this._subjectRepository,
    this._studentRepository,
  );

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

    // Fetch subject data to get its name for the filename
    final subject = await _subjectRepository.getSubjectById(subjectId);
    if (subject == null) {
      throw Exception('Subject with ID $subjectId not found');
    }

    // Fetch student data if available
    String? studentName;
    if (studentId != null) {
      final student = await _studentRepository.getStudentById(studentId);
      studentName = student?.name;
    }

    // Generate filename with format: [ID-ASIGNATURA]_[ID-ALUMNO]_[TIMESTAMP].jpg
    final extension = p.extension(tempImagePath);
    final fileName = _generateFileName(subject.name, studentName, extension);
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
      Logger.info('✓ Image orientation corrected and saved: $permanentPath');
    } else {
      // Fallback: if image can't be decoded, just copy as-is
      await tempFile.copy(permanentPath);
      fileSize = await tempFile.length();
      Logger.warning('Could not decode image, saved without orientation fix');
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

  /// Generate filename with format: [ID-ASIGNATURA]_[ID-ALUMNO]_[TIMESTAMP].jpg
  ///
  /// Example: MAT_Juan-Garcia_20260206_153045.jpg
  ///
  /// - [subjectName]: Full name of the subject (e.g., "Matemáticas")
  /// - [studentName]: Full name of the student (e.g., "Juan Garcia"), null if unassigned
  /// - [extension]: File extension including the dot (e.g., ".jpg")
  String _generateFileName(String subjectName, String? studentName, String extension) {
    final subjectId = FileNamingUtils.generateSubjectId(subjectName);
    final studentId = studentName != null
        ? FileNamingUtils.normalizeStudentName(studentName)
        : 'SIN-ASIGNAR';
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    return '${subjectId}_${studentId}_$timestamp$extension';
  }
}
