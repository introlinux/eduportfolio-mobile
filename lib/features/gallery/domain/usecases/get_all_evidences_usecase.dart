import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';

/// UseCase to get all evidences
class GetAllEvidencesUseCase {
  final EvidenceRepository _repository;

  GetAllEvidencesUseCase(this._repository);

  /// Get all evidences ordered by capture date (newest first)
  Future<List<Evidence>> call() async {
    final evidences = await _repository.getAllEvidences();

    // Sort by capture date descending (newest first)
    evidences.sort((a, b) => b.captureDate.compareTo(a.captureDate));

    return evidences;
  }
}
