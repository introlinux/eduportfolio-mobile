import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/core/domain/repositories/course_repository.dart';

/// UseCase to get all courses
class GetAllCoursesUseCase {
  final CourseRepository _repository;

  GetAllCoursesUseCase(this._repository);

  /// Get all courses ordered by start date (newest first)
  Future<List<Course>> call() async {
    final courses = await _repository.getAllCourses();

    // Sort by start date descending (newest first)
    courses.sort((a, b) => b.startDate.compareTo(a.startDate));

    return courses;
  }
}
