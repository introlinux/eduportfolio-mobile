import 'package:eduportfolio/core/domain/repositories/student_repository.dart';

/// Deletes all students from the database and their face embeddings
///
/// This is a destructive operation used for cleaning/resetting the system
class DeleteAllStudentsUseCase {
  final StudentRepository _repository;

  DeleteAllStudentsUseCase(this._repository);

  /// Delete all students and their face embeddings
  ///
  /// Returns the number of students deleted
  Future<int> call() async {
    final allStudents = await _repository.getAllStudents();
    int deletedCount = 0;

    for (final student in allStudents) {
      try {
        // Delete from database (including face embeddings)
        await _repository.deleteStudent(student.id!);
        deletedCount++;
      } catch (e) {
        print('Error deleting student ${student.id}: $e');
        // Continue with next student
      }
    }

    return deletedCount;
  }
}
