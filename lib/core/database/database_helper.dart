import 'package:eduportfolio/core/constants/app_constants.dart';
import 'package:eduportfolio/core/utils/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Database helper singleton for managing SQLite database
///
/// Handles database creation, migrations, and provides access to the database instance.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  /// Get database instance, creating it if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    Logger.info('Initializing database at: $path');

    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    Logger.info('Creating database tables (version $version)');

    await db.transaction((txn) async {
      // Create courses table
      await txn.execute('''
        CREATE TABLE courses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create students table
      await txn.execute('''
        CREATE TABLE students (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          course_id INTEGER NOT NULL,
          name TEXT NOT NULL UNIQUE,
          face_embeddings BLOB,
          enrollment_date TEXT DEFAULT CURRENT_TIMESTAMP,
          is_active INTEGER DEFAULT 1,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
        )
      ''');

      // Create subjects table
      await txn.execute('''
        CREATE TABLE subjects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          color TEXT,
          icon TEXT,
          is_default INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create evidences table
      await txn.execute('''
        CREATE TABLE evidences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          student_id INTEGER,
          course_id INTEGER,
          subject_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          file_path TEXT NOT NULL,
          thumbnail_path TEXT,
          file_size INTEGER,
          duration INTEGER,
          capture_date TEXT NOT NULL,
          is_reviewed INTEGER DEFAULT 1,
          notes TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          confidence REAL,
          method TEXT,
          FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL,
          FOREIGN KEY (course_id) REFERENCES courses(id),
          FOREIGN KEY (subject_id) REFERENCES subjects(id)
        )
      ''');

      // Create indexes for better query performance
      await txn.execute(
        'CREATE INDEX idx_students_course_id ON students(course_id)',
      );
      await txn.execute(
        'CREATE INDEX idx_evidences_student_id ON evidences(student_id)',
      );
      await txn.execute(
        'CREATE INDEX idx_evidences_course_id ON evidences(course_id)',
      );
      await txn.execute(
        'CREATE INDEX idx_evidences_subject_id ON evidences(subject_id)',
      );
      await txn.execute(
        'CREATE INDEX idx_evidences_capture_date ON evidences(capture_date)',
      );
      await txn.execute(
        'CREATE INDEX idx_evidences_is_reviewed ON evidences(is_reviewed)',
      );

      // Insert default subjects
      for (final subject in AppConstants.defaultSubjects) {
        await txn.insert('subjects', {
          'name': subject,
          'is_default': 1,
        });
      }

      Logger.info('Database tables created successfully');
    });
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Logger.info('Upgrading database from v$oldVersion to v$newVersion');

    if (oldVersion < 2) {
      Logger.info('Migrating to v2: Adding course_id to evidences');
      await db.transaction((txn) async {
        // Add course_id column
        await txn.execute(
          'ALTER TABLE evidences ADD COLUMN course_id INTEGER REFERENCES courses(id)',
        );

        // Backfill assigned evidences with course_id from students
        await txn.execute('''
          UPDATE evidences
          SET course_id = (
            SELECT course_id
            FROM students
            WHERE students.id = evidences.student_id
          )
          WHERE student_id IS NOT NULL
        ''');

        // Create index for course_id
        await txn.execute(
          'CREATE INDEX idx_evidences_course_id ON evidences(course_id)',
        );
      });
      Logger.info('Migration to v2 completed');
    }

    if (oldVersion < 3) {
      Logger.info('Migrating to v3: Adding UNIQUE constraint to student names');
      await db.transaction((txn) async {
        // Create new students table with UNIQUE constraint on name
        await txn.execute('''
          CREATE TABLE students_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            course_id INTEGER NOT NULL,
            name TEXT NOT NULL UNIQUE,
            face_embeddings BLOB,
            enrollment_date TEXT DEFAULT CURRENT_TIMESTAMP,
            is_active INTEGER DEFAULT 1,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
          )
        ''');

        // Copy data, keeping only first occurrence of each name per course
        // (in case there are duplicates)
        await txn.execute('''
          INSERT INTO students_new (id, course_id, name, face_embeddings, created_at, updated_at, enrollment_date, is_active)
          SELECT
            id,
            course_id,
            name,
            face_embeddings,
            created_at,
            updated_at,
            COALESCE(created_at, CURRENT_TIMESTAMP) as enrollment_date,
            1 as is_active
          FROM students
          WHERE id IN (
            SELECT MIN(id)
            FROM students
            GROUP BY name, course_id
          )
        ''');

        // Drop old table
        await txn.execute('DROP TABLE students');

        // Rename new table
        await txn.execute('ALTER TABLE students_new RENAME TO students');

        // Recreate index
        await txn.execute(
          'CREATE INDEX idx_students_course_id ON students(course_id)',
        );
      });
      Logger.info('Migration to v3 completed');
    }

    if (oldVersion < 4) {
      Logger.info('Migrating to v4: Adding desktop compatibility fields');
      await db.transaction((txn) async {
        // Add enrollment_date and is_active to students
        await txn.execute(
          'ALTER TABLE students ADD COLUMN enrollment_date TEXT DEFAULT CURRENT_TIMESTAMP',
        );
        await txn.execute(
          'ALTER TABLE students ADD COLUMN is_active INTEGER DEFAULT 1',
        );

        // Backfill enrollment_date with created_at
        await txn.execute(
          'UPDATE students SET enrollment_date = created_at WHERE enrollment_date IS NULL',
        );

        // Add confidence and method to evidences
        await txn.execute('ALTER TABLE evidences ADD COLUMN confidence REAL');
        await txn.execute('ALTER TABLE evidences ADD COLUMN method TEXT');
      });
      Logger.info('Migration to v4 completed');
    }
  }

  /// Called when database is opened
  Future<void> _onOpen(Database db) async {
    Logger.info('Database opened');

    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      Logger.info('Database closed');
    }
  }

  /// Delete database (useful for testing)
  Future<void> deleteDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);
    await deleteDatabase(path);
    _database = null;
    Logger.info('Database deleted');
  }
}
