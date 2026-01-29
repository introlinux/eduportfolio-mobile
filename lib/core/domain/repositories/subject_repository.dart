import 'package:eduportfolio/core/domain/entities/subject.dart';

/// Repository interface for subjects
///
/// Defines the contract for subject data operations.
/// Implementations should handle data access and business logic.
abstract class SubjectRepository {
  /// Get all subjects
  Future<List<Subject>> getAllSubjects();

  /// Get default subjects
  Future<List<Subject>> getDefaultSubjects();

  /// Get subject by ID
  Future<Subject?> getSubjectById(int id);

  /// Get subject by name
  Future<Subject?> getSubjectByName(String name);

  /// Create new subject
  Future<int> createSubject(Subject subject);

  /// Update existing subject
  Future<void> updateSubject(Subject subject);

  /// Delete subject
  Future<void> deleteSubject(int id);

  /// Count total subjects
  Future<int> countSubjects();
}
