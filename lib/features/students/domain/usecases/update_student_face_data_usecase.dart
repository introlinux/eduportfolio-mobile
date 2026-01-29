import 'package:eduportfolio/core/data/repositories/student_repository.dart';

/// Updates a student's face embeddings data
class UpdateStudentFaceDataUseCase {
  final StudentRepository _repository;

  UpdateStudentFaceDataUseCase(this._repository);

  /// Updates the face embeddings for a student
  ///
  /// Parameters:
  /// - [studentId]: ID of the student to update
  /// - [faceEmbeddings]: List of 128 double values representing the face
  Future<void> call({
    required int studentId,
    required List<double> faceEmbeddings,
  }) async {
    // Get current student data
    final student = await _repository.getStudentById(studentId);

    if (student == null) {
      throw Exception('Student not found');
    }

    // Update with face embeddings
    final updatedStudent = student.copyWith(
      faceEmbeddings: faceEmbeddings,
      hasFaceData: true,
      updatedAt: DateTime.now(),
    );

    await _repository.updateStudent(updatedStudent);
  }
}
