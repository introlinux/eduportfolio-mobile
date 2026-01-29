import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';

/// UseCase to get all students
class GetAllStudentsUseCase {
  final StudentRepository _repository;

  GetAllStudentsUseCase(this._repository);

  /// Get all students ordered by name
  Future<List<Student>> call() async {
    final students = await _repository.getAllStudents();

    // Sort by name alphabetically
    students.sort((a, b) => a.name.compareTo(b.name));

    return students;
  }
}
