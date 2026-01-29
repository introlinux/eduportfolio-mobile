import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';

/// Assigns an evidence to a student
///
/// Updates the evidence with the student ID and marks it as reviewed
class AssignEvidenceToStudentUseCase {
  final EvidenceRepository _repository;

  AssignEvidenceToStudentUseCase(this._repository);

  /// Assign evidence to student
  ///
  /// Parameters:
  /// - [evidenceId]: ID of the evidence to assign
  /// - [studentId]: ID of the student to assign to
  ///
  /// Throws exception if evidence not found
  Future<void> call({
    required int evidenceId,
    required int studentId,
  }) async {
    final evidence = await _repository.getEvidenceById(evidenceId);

    if (evidence == null) {
      throw Exception('Evidence not found');
    }

    // Update evidence with student assignment
    final updated = evidence.copyWith(
      studentId: studentId,
      updatedAt: DateTime.now(),
    );

    await _repository.updateEvidence(updated);
  }
}
