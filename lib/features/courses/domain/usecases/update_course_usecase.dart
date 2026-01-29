import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/core/domain/repositories/course_repository.dart';

/// UseCase to update an existing course
class UpdateCourseUseCase {
  final CourseRepository _repository;

  UpdateCourseUseCase(this._repository);

  /// Update course information
  ///
  /// Updates the course name and/or start date
  /// Does not modify the active status (use SetActiveCourseUseCase for that)
  Future<void> call({
    required int id,
    required String name,
    required DateTime startDate,
    required DateTime createdAt,
    DateTime? endDate,
    required bool isActive,
  }) async {
    // Create updated course entity
    final course = Course(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      createdAt: createdAt,
    );

    // Persist changes
    await _repository.updateCourse(course);
  }
}
