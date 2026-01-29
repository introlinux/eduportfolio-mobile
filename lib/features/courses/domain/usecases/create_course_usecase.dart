import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/core/domain/repositories/course_repository.dart';

/// UseCase to create a new course
class CreateCourseUseCase {
  final CourseRepository _repository;

  CreateCourseUseCase(this._repository);

  /// Create a new course
  ///
  /// [name] The name of the course (e.g., "Curso 2024-25")
  /// [startDate] The start date of the course
  /// [setAsActive] Whether to set this course as active (default: true)
  ///
  /// Returns the ID of the created course
  ///
  /// Note: If setAsActive is true, the repository implementation
  /// should automatically deactivate other courses
  Future<int> call({
    required String name,
    required DateTime startDate,
    bool setAsActive = true,
  }) async {
    // Create course entity
    final course = Course(
      name: name,
      startDate: startDate,
      isActive: setAsActive,
      createdAt: DateTime.now(),
    );

    // Persist to repository
    return await _repository.createCourse(course);
  }
}
