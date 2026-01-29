import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/core/domain/repositories/course_repository.dart';

/// UseCase to get the active course
class GetActiveCourseUseCase {
  final CourseRepository _repository;

  GetActiveCourseUseCase(this._repository);

  /// Get the currently active course
  /// Returns null if no course is active
  Future<Course?> call() async {
    return await _repository.getActiveCourse();
  }
}
