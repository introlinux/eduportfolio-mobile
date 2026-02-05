import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';

/// UseCase to count evidences that need manual review
///
/// Returns the count of evidences that either:
/// - Don't have a student assigned (studentId is null)
/// - Are marked as not reviewed (isReviewed is false)
///
/// If [courseId] is provided, only counts evidences for that course
/// (including orphaned evidences with courseId NULL)
class CountPendingEvidencesUseCase {
  final EvidenceRepository _repository;

  CountPendingEvidencesUseCase(this._repository);

  Future<int> call({int? courseId}) async {
    return _repository.countEvidencesNeedingReview(courseId: courseId);
  }
}
