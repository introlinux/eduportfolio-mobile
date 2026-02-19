import 'dart:io';

import 'package:eduportfolio/core/data/datasources/course_local_datasource.dart';
import 'package:eduportfolio/core/utils/logger.dart';
import 'package:eduportfolio/core/data/datasources/evidence_local_datasource.dart';
import 'package:eduportfolio/core/data/models/course_model.dart';
import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/core/domain/repositories/course_repository.dart';
import 'package:eduportfolio/core/errors/exceptions.dart';

/// Implementation of CourseRepository
///
/// Handles course data operations using local data source.
class CourseRepositoryImpl implements CourseRepository {
  final CourseLocalDataSource _localDataSource;
  final EvidenceLocalDataSource _evidenceDataSource;

  CourseRepositoryImpl(this._localDataSource, this._evidenceDataSource);

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
  Future<void> unarchiveCourse(int id) async {
    try {
      await _localDataSource.unarchiveCourse(id);
    } catch (e) {
      throw DatabaseException('Error unarchiving course: $e');
    }
  }

  @override
  Future<void> deleteCourseWithFiles(int id) async {
    try {
      // Get all evidences for this course
      final evidences = await _evidenceDataSource.getAllEvidences();
      final courseEvidences = evidences.where((e) => e.courseId == id).toList();

      // Delete physical files
      for (final evidence in courseEvidences) {
        try {
          final file = File(evidence.filePath);
          if (await file.exists()) {
            await file.delete();
          }
          // Delete thumbnail if exists
          if (evidence.thumbnailPath != null) {
            final thumbnail = File(evidence.thumbnailPath!);
            if (await thumbnail.exists()) {
              await thumbnail.delete();
            }
          }
        } catch (e) {
          // Log but continue - don't fail the whole operation if one file fails
          Logger.warning('Could not delete file ${evidence.filePath}', e);
        }
      }

      // Delete evidences from DB (will cascade delete due to foreign key)
      for (final evidence in courseEvidences) {
        await _evidenceDataSource.deleteEvidence(evidence.id!);
      }

      // Delete the course (students will be cascade deleted due to foreign key)
      await _localDataSource.deleteCourse(id);
    } catch (e) {
      throw DatabaseException('Error deleting course with files: $e');
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
