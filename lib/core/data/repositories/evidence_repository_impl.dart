import 'package:eduportfolio/core/data/datasources/evidence_local_datasource.dart';
import 'package:eduportfolio/core/data/models/evidence_model.dart';
import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/errors/exceptions.dart';

/// Implementation of EvidenceRepository
///
/// Handles evidence data operations using local data source.
class EvidenceRepositoryImpl implements EvidenceRepository {
  final EvidenceLocalDataSource _localDataSource;

  EvidenceRepositoryImpl(this._localDataSource);

  @override
  Future<List<Evidence>> getAllEvidences() async {
    try {
      final models = await _localDataSource.getAllEvidences();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching evidences: $e');
    }
  }

  @override
  Future<List<Evidence>> getEvidencesByStudent(int studentId) async {
    try {
      final models = await _localDataSource.getEvidencesByStudent(studentId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching evidences by student: $e');
    }
  }

  @override
  Future<List<Evidence>> getEvidencesBySubject(int subjectId) async {
    try {
      final models = await _localDataSource.getEvidencesBySubject(subjectId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching evidences by subject: $e');
    }
  }

  @override
  Future<List<Evidence>> getEvidencesByStudentAndSubject(
    int studentId,
    int subjectId,
  ) async {
    try {
      final models = await _localDataSource.getEvidencesByStudentAndSubject(
        studentId,
        subjectId,
      );
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException(
        'Error fetching evidences by student and subject: $e',
      );
    }
  }

  @override
  Future<List<Evidence>> getEvidencesByType(EvidenceType type) async {
    try {
      final models = await _localDataSource.getEvidencesByType(type);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching evidences by type: $e');
    }
  }

  @override
  Future<List<Evidence>> getEvidencesNeedingReview() async {
    try {
      final models = await _localDataSource.getEvidencesNeedingReview();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching evidences needing review: $e');
    }
  }

  @override
  Future<List<Evidence>> getUnassignedEvidences() async {
    try {
      final models = await _localDataSource.getUnassignedEvidences();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching unassigned evidences: $e');
    }
  }

  @override
  Future<List<Evidence>> getEvidencesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final models = await _localDataSource.getEvidencesByDateRange(
        startDate,
        endDate,
      );
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching evidences by date range: $e');
    }
  }

  @override
  Future<Evidence?> getEvidenceById(int id) async {
    try {
      final model = await _localDataSource.getEvidenceById(id);
      return model?.toEntity();
    } catch (e) {
      throw DatabaseException('Error fetching evidence by ID: $e');
    }
  }

  @override
  Future<int> createEvidence(Evidence evidence) async {
    try {
      final model = EvidenceModel.fromEntity(evidence);
      return await _localDataSource.insertEvidence(model);
    } catch (e) {
      throw DatabaseException('Error creating evidence: $e');
    }
  }

  @override
  Future<void> updateEvidence(Evidence evidence) async {
    try {
      if (evidence.id == null) {
        throw const InvalidDataException('Evidence ID cannot be null for update');
      }
      final model = EvidenceModel.fromEntity(evidence);
      await _localDataSource.updateEvidence(model);
    } catch (e) {
      if (e is InvalidDataException) rethrow;
      throw DatabaseException('Error updating evidence: $e');
    }
  }

  @override
  Future<void> deleteEvidence(int id) async {
    try {
      await _localDataSource.deleteEvidence(id);
    } catch (e) {
      throw DatabaseException('Error deleting evidence: $e');
    }
  }

  @override
  Future<void> assignEvidenceToStudent(int evidenceId, int studentId) async {
    try {
      await _localDataSource.assignEvidenceToStudent(evidenceId, studentId);
    } catch (e) {
      throw DatabaseException('Error assigning evidence to student: $e');
    }
  }

  @override
  Future<int> countEvidences() async {
    try {
      return await _localDataSource.countEvidences();
    } catch (e) {
      throw DatabaseException('Error counting evidences: $e');
    }
  }

  @override
  Future<int> countEvidencesByStudent(int studentId) async {
    try {
      return await _localDataSource.countEvidencesByStudent(studentId);
    } catch (e) {
      throw DatabaseException('Error counting evidences by student: $e');
    }
  }

  @override
  Future<int> countEvidencesNeedingReview() async {
    try {
      return await _localDataSource.countEvidencesNeedingReview();
    } catch (e) {
      throw DatabaseException('Error counting evidences needing review: $e');
    }
  }

  @override
  Future<int> getTotalStorageSize() async {
    try {
      return await _localDataSource.getTotalStorageSize();
    } catch (e) {
      throw DatabaseException('Error getting total storage size: $e');
    }
  }
}
