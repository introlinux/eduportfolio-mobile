import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';

/// UseCase to create a new student
class CreateStudentUseCase {
  final StudentRepository _repository;

  CreateStudentUseCase(this._repository);

  /// Create a new student
  /// Returns the ID of the created student
  Future<int> call({
    required int courseId,
    required String name,
  }) async {
    // Create student entity with current timestamp
    final student = Student(
      courseId: courseId,
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Persist to repository
    return await _repository.createStudent(student);
  }
}
