import 'package:eduportfolio/core/domain/repositories/student_repository.dart';

/// UseCase to delete a student
class DeleteStudentUseCase {
  final StudentRepository _repository;

  DeleteStudentUseCase(this._repository);

  /// Delete a student by ID
  /// This will remove the student and their face recognition data
  /// Note: Evidences associated with this student will not be deleted
  Future<void> call(int id) async {
    await _repository.deleteStudent(id);
  }
}
