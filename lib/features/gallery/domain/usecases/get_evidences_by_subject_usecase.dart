import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';

/// UseCase to get evidences filtered by subject
class GetEvidencesBySubjectUseCase {
  final EvidenceRepository _repository;

  GetEvidencesBySubjectUseCase(this._repository);

  /// Get evidences for a specific subject ordered by capture date (newest first)
  Future<List<Evidence>> call(int subjectId) async {
    final evidences = await _repository.getEvidencesBySubject(subjectId);

    // Sort by capture date descending (newest first)
    evidences.sort((a, b) => b.captureDate.compareTo(a.captureDate));

    return evidences;
  }
}
