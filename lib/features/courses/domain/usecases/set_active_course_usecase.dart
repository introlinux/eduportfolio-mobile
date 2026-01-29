import 'package:eduportfolio/core/domain/repositories/course_repository.dart';

/// UseCase to set a course as active
class SetActiveCourseUseCase {
  final CourseRepository _repository;

  SetActiveCourseUseCase(this._repository);

  /// Set a course as active
  ///
  /// This will:
  /// 1. Deactivate all other courses
  /// 2. Activate the specified course
  ///
  /// [courseId] The ID of the course to activate
  ///
  /// Note: The repository implementation handles deactivating
  /// other courses automatically when updating the course status
  Future<void> call(int courseId) async {
    // Get the course to activate
    final course = await _repository.getCourseById(courseId);

    if (course == null) {
      throw Exception('Course not found with ID: $courseId');
    }

    // Get all courses
    final allCourses = await _repository.getAllCourses();

    // Deactivate all other courses
    for (final otherCourse in allCourses) {
      if (otherCourse.id != courseId && otherCourse.isActive) {
        await _repository.updateCourse(
          otherCourse.copyWith(isActive: false),
        );
      }
    }

    // Activate the specified course
    await _repository.updateCourse(
      course.copyWith(isActive: true),
    );
  }
}
