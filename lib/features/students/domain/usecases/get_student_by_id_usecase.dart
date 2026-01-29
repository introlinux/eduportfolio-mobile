import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';

/// UseCase to get a student by ID
class GetStudentByIdUseCase {
  final StudentRepository _repository;

  GetStudentByIdUseCase(this._repository);

  /// Get a single student by ID
  /// Returns null if student not found
  Future<Student?> call(int id) async {
    return await _repository.getStudentById(id);
  }
}
