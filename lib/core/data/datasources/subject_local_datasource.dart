import 'package:eduportfolio/core/data/models/subject_model.dart';
import 'package:eduportfolio/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Local data source for subjects
///
/// Handles all SQLite operations for subjects table.
class SubjectLocalDataSource {
  final DatabaseHelper _databaseHelper;

  SubjectLocalDataSource(this._databaseHelper);

  /// Get all subjects
  Future<List<SubjectModel>> getAllSubjects() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'subjects',
      orderBy: 'name ASC',
    );

    return maps.map((map) => SubjectModel.fromMap(map)).toList();
  }

  /// Get default subjects
  Future<List<SubjectModel>> getDefaultSubjects() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'subjects',
      where: 'is_default = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return maps.map((map) => SubjectModel.fromMap(map)).toList();
  }

  /// Get subject by ID
  Future<SubjectModel?> getSubjectById(int id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return SubjectModel.fromMap(maps.first);
  }

  /// Get subject by name
  Future<SubjectModel?> getSubjectByName(String name) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'subjects',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return SubjectModel.fromMap(maps.first);
  }

  /// Insert subject
  Future<int> insertSubject(SubjectModel subject) async {
    final db = await _databaseHelper.database;
    return db.insert(
      'subjects',
      subject.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update subject
  Future<int> updateSubject(SubjectModel subject) async {
    final db = await _databaseHelper.database;
    return db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  /// Delete subject
  /// If the subject has evidences, they will be reassigned to the first default subject
  /// If no default subject exists, the deletion will fail
  Future<int> deleteSubject(int id) async {
    final db = await _databaseHelper.database;

    // Check if there are evidences with this subject
    final evidencesCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM evidences WHERE subject_id = ?',
      [id],
    );
    final count = Sqflite.firstIntValue(evidencesCount) ?? 0;

    if (count > 0) {
      // Find the first default subject (excluding the one being deleted)
      final defaultSubjects = await db.query(
        'subjects',
        where: 'is_default = ? AND id != ?',
        whereArgs: [1, id],
        limit: 1,
      );

      if (defaultSubjects.isEmpty) {
        throw Exception(
          'Cannot delete subject: $count evidences are using this subject and no other default subject exists to reassign them.',
        );
      }

      final defaultSubjectId = defaultSubjects.first['id'] as int;

      // Reassign all evidences to the first default subject
      await db.update(
        'evidences',
        {'subject_id': defaultSubjectId, 'is_reviewed': 0}, // Mark as not reviewed
        where: 'subject_id = ?',
        whereArgs: [id],
      );
    }

    // Now delete the subject
    return db.delete(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Count subjects
  Future<int> countSubjects() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM subjects');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
