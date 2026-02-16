import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/domain/repositories/subject_repository.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// UseCase for saving captured audio evidence with a cover photo
///
/// Takes a temporary audio file path and cover image path, copies them to
/// permanent storage, and creates an Evidence record in the database.
class SaveAudioEvidenceUseCase {
  final EvidenceRepository _repository;
  final SubjectRepository _subjectRepository;
  final StudentRepository _studentRepository;

  SaveAudioEvidenceUseCase(
    this._repository,
    this._subjectRepository,
    this._studentRepository,
  );

  /// Save evidence from a captured audio clip
  ///
  /// Parameters:
  /// - [tempAudioPath]: Temporary path of the recorded audio file
  /// - [coverImagePath]: Path to the cover photo captured at recording start
  /// - [subjectId]: ID of the subject this evidence belongs to
  /// - [durationMs]: Duration of the audio in milliseconds
  /// - [studentId]: Optional student ID if already assigned
  /// - [courseId]: Optional course ID for the active course
  ///
  /// Returns the ID of the created evidence
  Future<int> call({
    required String tempAudioPath,
    required String coverImagePath,
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

    // Generate filename with format: AUD_[ID-ASIGNATURA]_[ID-ALUMNO]_[TIMESTAMP].opus
    final extension = p.extension(tempAudioPath);
    final fileName = _generateFileName(subject.name, studentName, extension);
    final permanentPath = '${evidencesDir.path}/$fileName';

    // Copy audio file to permanent storage
    final tempFile = File(tempAudioPath);
    await tempFile.copy(permanentPath);
    final fileSize = await tempFile.length();

    print('\u2713 Audio saved: $permanentPath ($fileSize bytes)');

    // Process cover image: compress to JPEG 75%, max 512px
    String? thumbnailPath;
    try {
      final coverFileName =
          'COVER_${p.basenameWithoutExtension(fileName)}.jpg';
      final coverDestPath = '${thumbnailsDir.path}/$coverFileName';

      final result = await FlutterImageCompress.compressAndGetFile(
        coverImagePath,
        coverDestPath,
        quality: 75,
        minWidth: 512,
        minHeight: 512,
      );

      if (result != null) {
        thumbnailPath = result.path;
        print('\u2713 Audio cover image saved: $thumbnailPath');
      }
    } catch (e) {
      print('\u26a0\ufe0f  Could not process cover image: $e');
      // Continue without cover — gallery will show a placeholder
    }

    final now = DateTime.now();

    // Create Evidence entity
    final evidence = Evidence(
      subjectId: subjectId,
      type: EvidenceType.audio,
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

  /// Generate filename with format: AUD_[ID-ASIGNATURA]_[ID-ALUMNO]_[TIMESTAMP].opus
  String _generateFileName(
      String subjectName, String? studentName, String extension) {
    final subjectId = _generateSubjectId(subjectName);

    final studentId = studentName != null
        ? _normalizeStudentName(studentName)
        : 'SIN-ASIGNAR';

    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);

    return 'AUD_${subjectId}_${studentId}_$timestamp$extension';
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
