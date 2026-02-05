import 'package:eduportfolio/core/domain/repositories/course_repository.dart';

/// UseCase to permanently delete a course with all its evidence files
class DeleteCourseWithFilesUseCase {
  final CourseRepository _repository;

  DeleteCourseWithFilesUseCase(this._repository);

  /// Delete a course and all associated evidence files
  ///
  /// [courseId] The ID of the course to delete
  ///
  /// WARNING: This action is irreversible. It will:
  /// - Delete all evidence files (images, videos, etc.) for this course
  /// - Delete all evidence records from the database
  /// - Delete all students from this course
  /// - Delete the course itself
  Future<void> call(int courseId) async {
    await _repository.deleteCourseWithFiles(courseId);
  }
}
