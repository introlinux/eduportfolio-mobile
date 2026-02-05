import 'package:eduportfolio/core/domain/entities/evidence.dart';

/// Repository interface for evidences
///
/// Defines the contract for evidence data operations.
/// Implementations should handle data access and business logic.
abstract class EvidenceRepository {
  /// Get all evidences
  Future<List<Evidence>> getAllEvidences();

  /// Get evidences by student ID
  Future<List<Evidence>> getEvidencesByStudent(int studentId);

  /// Get evidences by subject ID
  Future<List<Evidence>> getEvidencesBySubject(int subjectId);

  /// Get evidences by student and subject
  Future<List<Evidence>> getEvidencesByStudentAndSubject(
    int studentId,
    int subjectId,
  );

  /// Get evidences by type
  Future<List<Evidence>> getEvidencesByType(EvidenceType type);

  /// Get evidences needing review
  Future<List<Evidence>> getEvidencesNeedingReview();

  /// Get unassigned evidences (in temporal folder)
  Future<List<Evidence>> getUnassignedEvidences();

  /// Get evidences by date range
  Future<List<Evidence>> getEvidencesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get evidence by ID
  Future<Evidence?> getEvidenceById(int id);

  /// Create new evidence
  Future<int> createEvidence(Evidence evidence);

  /// Update existing evidence
  Future<void> updateEvidence(Evidence evidence);

  /// Delete evidence
  Future<void> deleteEvidence(int id);

  /// Assign evidence to student
  Future<void> assignEvidenceToStudent(int evidenceId, int studentId);

  /// Count total evidences
  Future<int> countEvidences();

  /// Count evidences by student
  Future<int> countEvidencesByStudent(int studentId);

  /// Count evidences needing review
  Future<int> countEvidencesNeedingReview({int? courseId});

  /// Get total storage size in bytes
  Future<int> getTotalStorageSize();
}
