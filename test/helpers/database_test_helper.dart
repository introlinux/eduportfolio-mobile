import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Configura el entorno de SQLite para tests usando FFI (sin necesidad de dispositivo)
void setupDatabaseForTests() {
  // Inicializar sqflite FFI
  sqfliteFfiInit();
  // Establecer el factory de base de datos para usar FFI
  databaseFactory = databaseFactoryFfi;
}

/// Crea una base de datos en memoria para tests con el schema completo de la app
Future<Database> createTestDatabase() async {
  final db = await databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        // Habilitar foreign keys (necesario para SQLite)
        await db.execute('PRAGMA foreign_keys = ON');
        // Tabla de cursos
        await db.execute('''
          CREATE TABLE courses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            academic_year TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            archived_at TEXT
          )
        ''');

        // Tabla de estudiantes
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            course_id INTEGER NOT NULL,
            face_embeddings BLOB,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE
          )
        ''');

        // Tabla de asignaturas por defecto
        await db.execute('''
          CREATE TABLE subjects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            color TEXT NOT NULL,
            icon TEXT NOT NULL,
            order_index INTEGER NOT NULL
          )
        ''');

        // Insertar asignaturas por defecto
        await db.execute('''
          INSERT INTO subjects (name, color, icon, order_index) VALUES
          ('Sin asignar', 'FF9E9E9E', 'help_outline', 0),
          ('Matemáticas', 'FF2196F3', 'calculate', 1),
          ('Lengua', 'FFF44336', 'menu_book', 2),
          ('Ciencias', 'FF4CAF50', 'science', 3),
          ('Inglés', 'FFFF9800', 'language', 4),
          ('Plástica', 'FF9C27B0', 'palette', 5),
          ('Música', 'FFFF5722', 'music_note', 6),
          ('Educación Física', 'FF795548', 'sports_soccer', 7),
          ('Valores', 'FF607D8B', 'favorite', 8)
        ''');

        // Tabla de evidencias
        await db.execute('''
          CREATE TABLE evidences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER,
            subject_id INTEGER NOT NULL DEFAULT 1,
            type TEXT NOT NULL DEFAULT 'IMG',
            file_path TEXT NOT NULL,
            thumbnail_path TEXT,
            file_size INTEGER,
            duration INTEGER,
            capture_date TEXT NOT NULL,
            is_reviewed INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE SET NULL,
            FOREIGN KEY (subject_id) REFERENCES subjects (id)
          )
        ''');
      },
    ),
  );

  return db;
}

/// Cierra y elimina la base de datos de test
Future<void> closeTestDatabase(Database db) async {
  await db.close();
}

/// Helper para insertar datos de prueba comunes
class TestDataHelper {
  final Database db;

  TestDataHelper(this.db);

  /// Inserta un curso de prueba y retorna su ID
  Future<int> insertTestCourse({
    String name = 'Test Course',
    String academicYear = '2023-2024',
    bool isActive = true,
  }) async {
    return await db.insert('courses', {
      'name': name,
      'academic_year': academicYear,
      'is_active': isActive ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Inserta un estudiante de prueba y retorna su ID
  Future<int> insertTestStudent({
    required int courseId,
    String name = 'Test Student',
    List<double>? faceEmbeddings,
  }) async {
    final now = DateTime.now();
    return await db.insert('students', {
      'name': name,
      'course_id': courseId,
      'face_embeddings': faceEmbeddings != null
          ? Uint8List.fromList(_convertEmbeddingsToBlob(faceEmbeddings))
          : null,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }

  /// Inserta una evidencia de prueba y retorna su ID
  Future<int> insertTestEvidence({
    int? studentId,
    int subjectId = 1,
    String type = 'IMG',
    String filePath = '/test/path/image.jpg',
    String? thumbnailPath,
    int? fileSize,
    int? duration,
    bool isReviewed = false,
    String? notes,
    DateTime? captureDate,
  }) async {
    return await db.insert('evidences', {
      'student_id': studentId,
      'subject_id': subjectId,
      'type': type,
      'file_path': filePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (fileSize != null) 'file_size': fileSize,
      if (duration != null) 'duration': duration,
      'capture_date': (captureDate ?? DateTime.now()).toIso8601String(),
      'is_reviewed': isReviewed ? 1 : 0,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Convierte embeddings a Blob para SQLite
  List<int> _convertEmbeddingsToBlob(List<double> embeddings) {
    final buffer = List<int>.filled(embeddings.length * 8, 0);
    for (int i = 0; i < embeddings.length; i++) {
      final bytes = _doubleToBytes(embeddings[i]);
      for (int j = 0; j < 8; j++) {
        buffer[i * 8 + j] = bytes[j];
      }
    }
    return buffer;
  }

  /// Convierte un double a bytes (little endian)
  List<int> _doubleToBytes(double value) {
    final buffer = List<int>.filled(8, 0);
    final data = value.toInt();
    for (int i = 0; i < 8; i++) {
      buffer[i] = (data >> (i * 8)) & 0xFF;
    }
    return buffer;
  }
}
