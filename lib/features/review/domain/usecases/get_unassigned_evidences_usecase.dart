import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';

/// Gets all evidences that haven't been assigned to a student
///
/// Returns evidences where studentId is null, ordered by capture date descending
class GetUnassignedEvidencesUseCase {
  final EvidenceRepository _repository;

  GetUnassignedEvidencesUseCase(this._repository);

  /// Get unassigned evidences
  ///
  /// Parameters:
  /// - [subjectId]: Optional filter by subject
  ///
  /// Returns list of evidences ordered by captureDate DESC
  Future<List<Evidence>> call({int? subjectId}) async {
    final allEvidences = await _repository.getAllEvidences();

    // Filter unassigned evidences
    var unassigned = allEvidences.where((e) => e.studentId == null);

    // Apply subject filter if provided
    if (subjectId != null) {
      unassigned = unassigned.where((e) => e.subjectId == subjectId);
    }

    // Sort by capture date descending (most recent first)
    final list = unassigned.toList();
    list.sort((a, b) => b.captureDate.compareTo(a.captureDate));

    return list;
  }
}
