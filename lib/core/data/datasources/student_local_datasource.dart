import 'package:sqflite/sqflite.dart';

import '../../database/database_helper.dart';
import '../models/student_model.dart';

/// Local data source for students
///
/// Handles all SQLite operations for students table.
class StudentLocalDataSource {
  final DatabaseHelper _databaseHelper;

  StudentLocalDataSource(this._databaseHelper);

  /// Get all students
  Future<List<StudentModel>> getAllStudents() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'students',
      orderBy: 'name ASC',
    );

    return maps.map((map) => StudentModel.fromMap(map)).toList();
  }

  /// Get students by course ID
  Future<List<StudentModel>> getStudentsByCourse(int courseId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'students',
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => StudentModel.fromMap(map)).toList();
  }

  /// Get students from active course
  Future<List<StudentModel>> getStudentsFromActiveCourse() async {
    final db = await _databaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM students s
      INNER JOIN courses c ON s.course_id = c.id
      WHERE c.is_active = 1
      ORDER BY s.name ASC
    ''');

    return maps.map((map) => StudentModel.fromMap(map)).toList();
  }

  /// Get student by ID
  Future<StudentModel?> getStudentById(int id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return StudentModel.fromMap(maps.first);
  }

  /// Get students with face data
  Future<List<StudentModel>> getStudentsWithFaceData() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'students',
      where: 'face_embeddings IS NOT NULL',
      orderBy: 'name ASC',
    );

    return maps.map((map) => StudentModel.fromMap(map)).toList();
  }

  /// Get students from active course with face data
  Future<List<StudentModel>> getActiveStudentsWithFaceData() async {
    final db = await _databaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM students s
      INNER JOIN courses c ON s.course_id = c.id
      WHERE c.is_active = 1 AND s.face_embeddings IS NOT NULL
      ORDER BY s.name ASC
    ''');

    return maps.map((map) => StudentModel.fromMap(map)).toList();
  }

  /// Insert student
  Future<int> insertStudent(StudentModel student) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'students',
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update student
  Future<int> updateStudent(StudentModel student) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  /// Delete student
  ///
  /// Note: This will set student_id to NULL in evidences table (ON DELETE SET NULL)
  Future<int> deleteStudent(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Count students
  Future<int> countStudents() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM students');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Count students by course
  Future<int> countStudentsByCourse(int courseId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM students WHERE course_id = ?',
      [courseId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
