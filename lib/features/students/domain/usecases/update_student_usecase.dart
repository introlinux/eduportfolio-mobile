import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';

/// UseCase to update an existing student
class UpdateStudentUseCase {
  final StudentRepository _repository;

  UpdateStudentUseCase(this._repository);

  /// Update student information
  /// Updates the name and/or course, preserving other fields
  Future<void> call({
    required int id,
    required int courseId,
    required String name,
    required DateTime createdAt,
  }) async {
    // Create updated student entity
    final student = Student(
      id: id,
      courseId: courseId,
      name: name,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );

    // Persist changes
    await _repository.updateStudent(student);
  }
}
