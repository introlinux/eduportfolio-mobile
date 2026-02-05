import 'package:eduportfolio/core/domain/entities/course.dart';

/// Repository interface for courses
///
/// Defines the contract for course data operations.
/// Implementations should handle data access and business logic.
abstract class CourseRepository {
  /// Get all courses
  Future<List<Course>> getAllCourses();

  /// Get currently active course
  Future<Course?> getActiveCourse();

  /// Get course by ID
  Future<Course?> getCourseById(int id);

  /// Create new course
  Future<int> createCourse(Course course);

  /// Update existing course
  Future<void> updateCourse(Course course);

  /// Delete course
  Future<void> deleteCourse(int id);

  /// Archive course (set end date and deactivate)
  Future<void> archiveCourse(int id, DateTime endDate);

  /// Unarchive course (remove end date, keep inactive)
  Future<void> unarchiveCourse(int id);

  /// Delete course with all associated evidence files
  Future<void> deleteCourseWithFiles(int id);

  /// Count total courses
  Future<int> countCourses();
}
