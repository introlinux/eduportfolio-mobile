import 'package:eduportfolio/core/domain/entities/student.dart';

/// Repository interface for students
///
/// Defines the contract for student data operations.
/// Implementations should handle data access and business logic.
abstract class StudentRepository {
  /// Get all students
  Future<List<Student>> getAllStudents();

  /// Get students by course ID
  Future<List<Student>> getStudentsByCourse(int courseId);

  /// Get students from active course
  Future<List<Student>> getStudentsFromActiveCourse();

  /// Get student by ID
  Future<Student?> getStudentById(int id);

  /// Get students with face recognition data
  Future<List<Student>> getStudentsWithFaceData();

  /// Get students from active course with face recognition data
  Future<List<Student>> getActiveStudentsWithFaceData();

  /// Create new student
  Future<int> createStudent(Student student);

  /// Update existing student
  Future<void> updateStudent(Student student);

  /// Delete student
  Future<void> deleteStudent(int id);

  /// Count total students
  Future<int> countStudents();

  /// Count students by course
  Future<int> countStudentsByCourse(int courseId);
}
