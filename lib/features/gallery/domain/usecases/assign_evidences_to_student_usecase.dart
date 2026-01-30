import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';

/// Use case to assign multiple evidences to a student
class AssignEvidencesToStudentUseCase {
  final EvidenceRepository repository;

  AssignEvidencesToStudentUseCase(this.repository);

  /// Assigns multiple evidences to a student
  /// Returns the number of evidences successfully assigned
  Future<int> call(List<int> evidenceIds, int studentId) async {
    int successCount = 0;

    for (final evidenceId in evidenceIds) {
      try {
        await repository.assignEvidenceToStudent(evidenceId, studentId);
        successCount++;
      } catch (e) {
        // Log error but continue with other evidences
        print('Error assigning evidence $evidenceId: $e');
      }
    }

    return successCount;
  }
}
