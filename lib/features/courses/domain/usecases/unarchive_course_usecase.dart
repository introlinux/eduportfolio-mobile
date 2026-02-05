import 'package:eduportfolio/core/domain/repositories/course_repository.dart';

/// UseCase to unarchive a course
class UnarchiveCourseUseCase {
  final CourseRepository _repository;

  UnarchiveCourseUseCase(this._repository);

  /// Unarchive a course by removing its end date
  ///
  /// [courseId] The ID of the course to unarchive
  ///
  /// This will remove the end date and keep the course inactive.
  /// The user can then manually activate it if desired.
  Future<void> call(int courseId) async {
    await _repository.unarchiveCourse(courseId);
  }
}
