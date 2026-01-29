import 'package:eduportfolio/core/domain/repositories/course_repository.dart';

/// UseCase to archive a course
class ArchiveCourseUseCase {
  final CourseRepository _repository;

  ArchiveCourseUseCase(this._repository);

  /// Archive a course by setting its end date and deactivating it
  ///
  /// [courseId] The ID of the course to archive
  /// [endDate] The end date of the course (defaults to today)
  ///
  /// This will automatically deactivate the course and set its end date
  Future<void> call(int courseId, {DateTime? endDate}) async {
    final archiveDate = endDate ?? DateTime.now();
    await _repository.archiveCourse(courseId, archiveDate);
  }
}
