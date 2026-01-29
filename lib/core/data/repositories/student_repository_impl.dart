import 'package:eduportfolio/core/data/datasources/student_local_datasource.dart';
import 'package:eduportfolio/core/data/models/student_model.dart';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';
import 'package:eduportfolio/core/errors/exceptions.dart';

/// Implementation of StudentRepository
///
/// Handles student data operations using local data source.
class StudentRepositoryImpl implements StudentRepository {
  final StudentLocalDataSource _localDataSource;

  StudentRepositoryImpl(this._localDataSource);

  @override
  Future<List<Student>> getAllStudents() async {
    try {
      final models = await _localDataSource.getAllStudents();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching students: $e');
    }
  }

  @override
  Future<List<Student>> getStudentsByCourse(int courseId) async {
    try {
      final models = await _localDataSource.getStudentsByCourse(courseId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching students by course: $e');
    }
  }

  @override
  Future<List<Student>> getStudentsFromActiveCourse() async {
    try {
      final models = await _localDataSource.getStudentsFromActiveCourse();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching students from active course: $e');
    }
  }

  @override
  Future<Student?> getStudentById(int id) async {
    try {
      final model = await _localDataSource.getStudentById(id);
      return model?.toEntity();
    } catch (e) {
      throw DatabaseException('Error fetching student by ID: $e');
    }
  }

  @override
  Future<List<Student>> getStudentsWithFaceData() async {
    try {
      final models = await _localDataSource.getStudentsWithFaceData();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching students with face data: $e');
    }
  }

  @override
  Future<List<Student>> getActiveStudentsWithFaceData() async {
    try {
      final models = await _localDataSource.getActiveStudentsWithFaceData();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException(
        'Error fetching active students with face data: $e',
      );
    }
  }

  @override
  Future<int> createStudent(Student student) async {
    try {
      final model = StudentModel.fromEntity(student);
      return await _localDataSource.insertStudent(model);
    } catch (e) {
      throw DatabaseException('Error creating student: $e');
    }
  }

  @override
  Future<void> updateStudent(Student student) async {
    try {
      if (student.id == null) {
        throw const InvalidDataException('Student ID cannot be null for update');
      }
      final model = StudentModel.fromEntity(student);
      await _localDataSource.updateStudent(model);
    } catch (e) {
      if (e is InvalidDataException) rethrow;
      throw DatabaseException('Error updating student: $e');
    }
  }

  @override
  Future<void> deleteStudent(int id) async {
    try {
      await _localDataSource.deleteStudent(id);
    } catch (e) {
      throw DatabaseException('Error deleting student: $e');
    }
  }

  @override
  Future<int> countStudents() async {
    try {
      return await _localDataSource.countStudents();
    } catch (e) {
      throw DatabaseException('Error counting students: $e');
    }
  }

  @override
  Future<int> countStudentsByCourse(int courseId) async {
    try {
      return await _localDataSource.countStudentsByCourse(courseId);
    } catch (e) {
      throw DatabaseException('Error counting students by course: $e');
    }
  }
}
