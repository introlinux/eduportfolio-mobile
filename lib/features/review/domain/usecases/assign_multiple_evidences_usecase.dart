import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';

/// Assigns multiple evidences to the same student in a batch operation
///
/// More efficient than calling assign individually for each evidence
class AssignMultipleEvidencesUseCase {
  final EvidenceRepository _repository;

  AssignMultipleEvidencesUseCase(this._repository);

  /// Assign multiple evidences to one student
  ///
  /// Parameters:
  /// - [evidenceIds]: List of evidence IDs to assign
  /// - [studentId]: ID of the student to assign all evidences to
  ///
  /// Skips evidences that are not found (logs warning but doesn't throw)
  Future<void> call({
    required List<int> evidenceIds,
    required int studentId,
  }) async {
    if (evidenceIds.isEmpty) {
      return; // Nothing to do
    }

    // Process each evidence
    for (final evidenceId in evidenceIds) {
      try {
        final evidence = await _repository.getEvidenceById(evidenceId);

        if (evidence == null) {
          // Skip missing evidence
          continue;
        }

        // Update evidence with student assignment
        final updated = evidence.copyWith(
          studentId: studentId,
          updatedAt: DateTime.now(),
        );

        await _repository.updateEvidence(updated);
      } catch (e) {
        // Log error but continue with remaining evidences
        print('Error assigning evidence $evidenceId: $e');
      }
    }
  }
}
