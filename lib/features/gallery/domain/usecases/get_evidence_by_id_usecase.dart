import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';

/// UseCase to get a single evidence by ID
class GetEvidenceByIdUseCase {
  final EvidenceRepository _repository;

  GetEvidenceByIdUseCase(this._repository);

  /// Get evidence by ID
  ///
  /// Returns null if evidence not found
  Future<Evidence?> call(int evidenceId) async {
    return _repository.getEvidenceById(evidenceId);
  }
}
