import 'package:sqflite/sqflite.dart';

import '../../database/database_helper.dart';
import '../models/course_model.dart';

/// Local data source for courses
///
/// Handles all SQLite operations for courses table.
class CourseLocalDataSource {
  final DatabaseHelper _databaseHelper;

  CourseLocalDataSource(this._databaseHelper);

  /// Get all courses
  Future<List<CourseModel>> getAllCourses() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'courses',
      orderBy: 'start_date DESC',
    );

    return maps.map((map) => CourseModel.fromMap(map)).toList();
  }

  /// Get active course
  Future<CourseModel?> getActiveCourse() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'courses',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return CourseModel.fromMap(maps.first);
  }

  /// Get course by ID
  Future<CourseModel?> getCourseById(int id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return CourseModel.fromMap(maps.first);
  }

  /// Insert course
  Future<int> insertCourse(CourseModel course) async {
    final db = await _databaseHelper.database;

    // If this course is active, deactivate all others
    if (course.isActive) {
      await db.update(
        'courses',
        {'is_active': 0},
        where: 'is_active = ?',
        whereArgs: [1],
      );
    }

    return await db.insert(
      'courses',
      course.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update course
  Future<int> updateCourse(CourseModel course) async {
    final db = await _databaseHelper.database;

    // If this course is being activated, deactivate all others
    if (course.isActive) {
      await db.update(
        'courses',
        {'is_active': 0},
        where: 'is_active = ? AND id != ?',
        whereArgs: [1, course.id],
      );
    }

    return await db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  /// Delete course
  Future<int> deleteCourse(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Archive course (set end_date and deactivate)
  Future<int> archiveCourse(int id, DateTime endDate) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'courses',
      {
        'end_date': endDate.toIso8601String(),
        'is_active': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Count courses
  Future<int> countCourses() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM courses');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
