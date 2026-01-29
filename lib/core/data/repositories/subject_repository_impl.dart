import '../../domain/entities/subject.dart';
import '../../domain/repositories/subject_repository.dart';
import '../../errors/exceptions.dart';
import '../datasources/subject_local_datasource.dart';
import '../models/subject_model.dart';

/// Implementation of SubjectRepository
///
/// Handles subject data operations using local data source.
class SubjectRepositoryImpl implements SubjectRepository {
  final SubjectLocalDataSource _localDataSource;

  SubjectRepositoryImpl(this._localDataSource);

  @override
  Future<List<Subject>> getAllSubjects() async {
    try {
      final models = await _localDataSource.getAllSubjects();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching subjects: $e');
    }
  }

  @override
  Future<List<Subject>> getDefaultSubjects() async {
    try {
      final models = await _localDataSource.getDefaultSubjects();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching default subjects: $e');
    }
  }

  @override
  Future<Subject?> getSubjectById(int id) async {
    try {
      final model = await _localDataSource.getSubjectById(id);
      return model?.toEntity();
    } catch (e) {
      throw DatabaseException('Error fetching subject by ID: $e');
    }
  }

  @override
  Future<Subject?> getSubjectByName(String name) async {
    try {
      final model = await _localDataSource.getSubjectByName(name);
      return model?.toEntity();
    } catch (e) {
      throw DatabaseException('Error fetching subject by name: $e');
    }
  }

  @override
  Future<int> createSubject(Subject subject) async {
    try {
      final model = SubjectModel.fromEntity(subject);
      return await _localDataSource.insertSubject(model);
    } catch (e) {
      throw DatabaseException('Error creating subject: $e');
    }
  }

  @override
  Future<void> updateSubject(Subject subject) async {
    try {
      if (subject.id == null) {
        throw InvalidDataException('Subject ID cannot be null for update');
      }
      final model = SubjectModel.fromEntity(subject);
      await _localDataSource.updateSubject(model);
    } catch (e) {
      if (e is InvalidDataException) rethrow;
      throw DatabaseException('Error updating subject: $e');
    }
  }

  @override
  Future<void> deleteSubject(int id) async {
    try {
      await _localDataSource.deleteSubject(id);
    } catch (e) {
      throw DatabaseException('Error deleting subject: $e');
    }
  }

  @override
  Future<int> countSubjects() async {
    try {
      return await _localDataSource.countSubjects();
    } catch (e) {
      throw DatabaseException('Error counting subjects: $e');
    }
  }
}
