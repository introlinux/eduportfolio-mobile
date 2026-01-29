import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';

/// UseCase to get students by course
class GetStudentsByCourseUseCase {
  final StudentRepository _repository;

  GetStudentsByCourseUseCase(this._repository);

  /// Get students for a specific course ordered by name
  Future<List<Student>> call(int courseId) async {
    final students = await _repository.getStudentsByCourse(courseId);

    // Sort by name alphabetically
    students.sort((a, b) => a.name.compareTo(b.name));

    return students;
  }
}
