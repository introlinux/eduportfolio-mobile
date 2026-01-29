import 'package:eduportfolio/core/data/datasources/course_local_datasource.dart';
import 'package:eduportfolio/core/data/models/course_model.dart';
import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/core/domain/repositories/course_repository.dart';
import 'package:eduportfolio/core/errors/exceptions.dart';

/// Implementation of CourseRepository
///
/// Handles course data operations using local data source.
class CourseRepositoryImpl implements CourseRepository {
  final CourseLocalDataSource _localDataSource;

  CourseRepositoryImpl(this._localDataSource);

  @override
  Future<List<Course>> getAllCourses() async {
    try {
      final models = await _localDataSource.getAllCourses();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching courses: $e');
    }
  }

  @override
  Future<Course?> getActiveCourse() async {
    try {
      final model = await _localDataSource.getActiveCourse();
      return model?.toEntity();
    } catch (e) {
      throw DatabaseException('Error fetching active course: $e');
    }
  }

  @override
  Future<Course?> getCourseById(int id) async {
    try {
      final model = await _localDataSource.getCourseById(id);
      return model?.toEntity();
    } catch (e) {
      throw DatabaseException('Error fetching course by ID: $e');
    }
  }

  @override
  Future<int> createCourse(Course course) async {
    try {
      final model = CourseModel.fromEntity(course);
      return await _localDataSource.insertCourse(model);
    } catch (e) {
      throw DatabaseException('Error creating course: $e');
    }
  }

  @override
  Future<void> updateCourse(Course course) async {
    try {
      if (course.id == null) {
        throw const InvalidDataException('Course ID cannot be null for update');
      }
      final model = CourseModel.fromEntity(course);
      await _localDataSource.updateCourse(model);
    } catch (e) {
      if (e is InvalidDataException) rethrow;
      throw DatabaseException('Error updating course: $e');
    }
  }

  @override
  Future<void> deleteCourse(int id) async {
    try {
      await _localDataSource.deleteCourse(id);
    } catch (e) {
      throw DatabaseException('Error deleting course: $e');
    }
  }

  @override
  Future<void> archiveCourse(int id, DateTime endDate) async {
    try {
      await _localDataSource.archiveCourse(id, endDate);
    } catch (e) {
      throw DatabaseException('Error archiving course: $e');
    }
  }

  @override
  Future<int> countCourses() async {
    try {
      return await _localDataSource.countCourses();
    } catch (e) {
      throw DatabaseException('Error counting courses: $e');
    }
  }
}
