import 'dart:typed_data';

import 'package:eduportfolio/core/domain/repositories/student_repository.dart';

/// Updates a student's face embeddings data
class UpdateStudentFaceDataUseCase {
  final StudentRepository _repository;

  UpdateStudentFaceDataUseCase(this._repository);

  /// Updates the face embeddings for a student
  ///
  /// Parameters:
  /// - [studentId]: ID of the student to update
  /// - [faceEmbeddings]: Byte array representing the face embeddings
  Future<void> call({
    required int studentId,
    required Uint8List faceEmbeddings,
  }) async {
    // Get current student data
    final student = await _repository.getStudentById(studentId);

    if (student == null) {
      throw Exception('Student not found');
    }

    // Update with face embeddings
    // Note: hasFaceData will automatically be true when faceEmbeddings is set
    final updatedStudent = student.copyWith(
      faceEmbeddings: faceEmbeddings,
      updatedAt: DateTime.now(),
    );

    await _repository.updateStudent(updatedStudent);
  }
}
