import 'package:eduportfolio/core/data/models/evidence_model.dart';
import 'package:eduportfolio/core/database/database_helper.dart';
import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:sqflite/sqflite.dart';

/// Local data source for evidences
///
/// Handles all SQLite operations for evidences table.
class EvidenceLocalDataSource {
  final DatabaseHelper _databaseHelper;

  EvidenceLocalDataSource(this._databaseHelper);

  /// Get all evidences
  Future<List<EvidenceModel>> getAllEvidences() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'evidences',
      orderBy: 'capture_date DESC',
    );

    return maps.map((map) => EvidenceModel.fromMap(map)).toList();
  }

  /// Get evidences by student ID
  Future<List<EvidenceModel>> getEvidencesByStudent(int studentId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'evidences',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'capture_date DESC',
    );

    return maps.map((map) => EvidenceModel.fromMap(map)).toList();
  }

  /// Get evidences by subject ID
  Future<List<EvidenceModel>> getEvidencesBySubject(int subjectId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'evidences',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'capture_date DESC',
    );

    return maps.map((map) => EvidenceModel.fromMap(map)).toList();
  }

  /// Get evidences by student and subject
  Future<List<EvidenceModel>> getEvidencesByStudentAndSubject(
    int studentId,
    int subjectId,
  ) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'evidences',
      where: 'student_id = ? AND subject_id = ?',
      whereArgs: [studentId, subjectId],
      orderBy: 'capture_date DESC',
    );

    return maps.map((map) => EvidenceModel.fromMap(map)).toList();
  }

  /// Get evidences by type
  Future<List<EvidenceModel>> getEvidencesByType(EvidenceType type) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'evidences',
      where: 'type = ?',
      whereArgs: [type.toDbString()],
      orderBy: 'capture_date DESC',
    );

    return maps.map((map) => EvidenceModel.fromMap(map)).toList();
  }

  /// Get evidences needing review (not assigned to student or not reviewed)
  Future<List<EvidenceModel>> getEvidencesNeedingReview() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'evidences',
      where: 'student_id IS NULL OR is_reviewed = ?',
      whereArgs: [0],
      orderBy: 'capture_date DESC',
    );

    return maps.map((map) => EvidenceModel.fromMap(map)).toList();
  }

  /// Get unassigned evidences (in temporal folder)
  Future<List<EvidenceModel>> getUnassignedEvidences() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'evidences',
      where: 'student_id IS NULL',
      orderBy: 'capture_date DESC',
    );

    return maps.map((map) => EvidenceModel.fromMap(map)).toList();
  }

  /// Get evidences by date range
  Future<List<EvidenceModel>> getEvidencesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'evidences',
      where: 'capture_date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'capture_date DESC',
    );

    return maps.map((map) => EvidenceModel.fromMap(map)).toList();
  }

  /// Get evidence by ID
  Future<EvidenceModel?> getEvidenceById(int id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'evidences',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return EvidenceModel.fromMap(maps.first);
  }

  /// Insert evidence
  Future<int> insertEvidence(EvidenceModel evidence) async {
    final db = await _databaseHelper.database;
    return db.insert(
      'evidences',
      evidence.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update evidence
  Future<int> updateEvidence(EvidenceModel evidence) async {
    final db = await _databaseHelper.database;
    return db.update(
      'evidences',
      evidence.toMap(),
      where: 'id = ?',
      whereArgs: [evidence.id],
    );
  }

  /// Delete evidence
  Future<int> deleteEvidence(int id) async {
    final db = await _databaseHelper.database;
    return db.delete(
      'evidences',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Assign evidence to student
  Future<int> assignEvidenceToStudent(int evidenceId, int studentId) async {
    final db = await _databaseHelper.database;
    return db.update(
      'evidences',
      {
        'student_id': studentId,
        'is_reviewed': 1,
      },
      where: 'id = ?',
      whereArgs: [evidenceId],
    );
  }

  /// Count evidences
  Future<int> countEvidences() async {
    final db = await _databaseHelper.database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM evidences');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Count evidences by student
  Future<int> countEvidencesByStudent(int studentId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM evidences WHERE student_id = ?',
      [studentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Count evidences needing review
  /// If [courseId] is provided, only count evidences for that course (including orphaned ones with courseId NULL)
  Future<int> countEvidencesNeedingReview({int? courseId}) async {
    final db = await _databaseHelper.database;

    String query;
    List<dynamic> args = [];

    if (courseId != null) {
      // Filter by course: include orphaned (course_id IS NULL) or matching course
      query = '''
        SELECT COUNT(*) as count FROM evidences
        WHERE (student_id IS NULL OR is_reviewed = 0)
        AND (course_id IS NULL OR course_id = ?)
      ''';
      args = [courseId];
    } else {
      // No course filter
      query = 'SELECT COUNT(*) as count FROM evidences WHERE student_id IS NULL OR is_reviewed = 0';
    }

    final result = await db.rawQuery(query, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total storage size
  Future<int> getTotalStorageSize() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(file_size) as total FROM evidences WHERE file_size IS NOT NULL',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
