import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/domain/repositories/subject_repository.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// UseCase for saving captured video evidence
///
/// Takes a video file path (temporary), copies it to permanent storage,
/// generates a thumbnail, and creates an Evidence record in the database.
class SaveVideoEvidenceUseCase {
  final EvidenceRepository _repository;
  final SubjectRepository _subjectRepository;
  final StudentRepository _studentRepository;

  SaveVideoEvidenceUseCase(
    this._repository,
    this._subjectRepository,
    this._studentRepository,
  );

  /// Save evidence from a captured video
  ///
  /// Parameters:
  /// - [tempVideoPath]: Temporary path from camera recording
  /// - [subjectId]: ID of the subject this evidence belongs to
  /// - [durationMs]: Duration of the video in milliseconds
  /// - [studentId]: Optional student ID if already assigned
  /// - [courseId]: Optional course ID for the active course
  ///
  /// Returns the ID of the created evidence
  Future<int> call({
    required String tempVideoPath,
    required int subjectId,
    required int durationMs,
    int? studentId,
    int? courseId,
  }) async {
    // Get app's documents directory for permanent storage
    final directory = await getApplicationDocumentsDirectory();
    final evidencesDir = Directory('${directory.path}/evidences');
    final thumbnailsDir = Directory('${directory.path}/evidences/thumbnails');

    // Create directories if they don't exist
    if (!await evidencesDir.exists()) {
      await evidencesDir.create(recursive: true);
    }
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
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

    // Generate filename with format: [ID-ASIGNATURA]_[ID-ALUMNO]_[TIMESTAMP].mp4
    final extension = p.extension(tempVideoPath);
    final fileName = _generateFileName(subject.name, studentName, extension);
    final permanentPath = '${evidencesDir.path}/$fileName';

    // Copy video file to permanent storage
    final tempFile = File(tempVideoPath);
    await tempFile.copy(permanentPath);
    final fileSize = await tempFile.length();

    print('✓ Video saved: $permanentPath ($fileSize bytes)');

    // Generate thumbnail from first frame
    String? thumbnailPath;
    try {
      final thumbFileName = 'THUMB_${p.basenameWithoutExtension(fileName)}.jpg';
      thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: permanentPath,
        thumbnailPath: thumbnailsDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 75,
      );
      print('✓ Video thumbnail generated: $thumbnailPath');
    } catch (e) {
      print('⚠️  Could not generate video thumbnail: $e');
      // Continue without thumbnail — gallery will show a placeholder
    }

    final now = DateTime.now();

    // Create Evidence entity
    final evidence = Evidence(
      subjectId: subjectId,
      type: EvidenceType.video,
      filePath: permanentPath,
      thumbnailPath: thumbnailPath,
      captureDate: now,
      createdAt: now,
      studentId: studentId,
      courseId: courseId,
      fileSize: fileSize,
      duration: durationMs ~/ 1000, // Store duration in seconds
      // Mark as reviewed if facial recognition assigned a student
      isReviewed: studentId != null,
    );

    // Save to database and return the ID
    final evidenceId = await _repository.createEvidence(evidence);

    return evidenceId;
  }

  /// Generate filename with format: VID_[ID-ASIGNATURA]_[ID-ALUMNO]_[TIMESTAMP].mp4
  String _generateFileName(
      String subjectName, String? studentName, String extension) {
    final subjectId = _generateSubjectId(subjectName);

    final studentId = studentName != null
        ? _normalizeStudentName(studentName)
        : 'SIN-ASIGNAR';

    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);

    return 'VID_${subjectId}_${studentId}_$timestamp$extension';
  }

  /// Extract first 3 letters of subject name in uppercase
  String _generateSubjectId(String subjectName) {
    final normalized = _removeAccents(subjectName);
    final id = normalized.length >= 3
        ? normalized.substring(0, 3).toUpperCase()
        : normalized.toUpperCase().padRight(3, 'X');
    return id;
  }

  /// Remove accents from text
  String _removeAccents(String text) {
    const withAccents = 'áéíóúÁÉÍÓÚñÑüÜ';
    const withoutAccents = 'aeiouAEIOUnNuU';
    String result = text;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Normalize student name by replacing spaces with hyphens
  String _normalizeStudentName(String name) {
    final normalized = _removeAccents(name);
    return normalized.replaceAll(' ', '-');
  }
}
