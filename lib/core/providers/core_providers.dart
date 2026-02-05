import 'package:eduportfolio/core/data/datasources/course_local_datasource.dart';
import 'package:eduportfolio/core/data/datasources/evidence_local_datasource.dart';
import 'package:eduportfolio/core/data/datasources/image_capture_datasource.dart';
import 'package:eduportfolio/core/data/datasources/student_local_datasource.dart';
import 'package:eduportfolio/core/data/datasources/subject_local_datasource.dart';
import 'package:eduportfolio/core/data/repositories/course_repository_impl.dart';
import 'package:eduportfolio/core/data/repositories/evidence_repository_impl.dart';
import 'package:eduportfolio/core/data/repositories/student_repository_impl.dart';
import 'package:eduportfolio/core/data/repositories/subject_repository_impl.dart';
import 'package:eduportfolio/core/database/database_providers.dart';
import 'package:eduportfolio/core/domain/repositories/course_repository.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';
import 'package:eduportfolio/core/domain/repositories/subject_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// DATASOURCE PROVIDERS
// ============================================================================

/// Provider for CourseLocalDataSource
final courseLocalDataSourceProvider = Provider<CourseLocalDataSource>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return CourseLocalDataSource(databaseHelper);
});

/// Provider for StudentLocalDataSource
final studentLocalDataSourceProvider = Provider<StudentLocalDataSource>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return StudentLocalDataSource(databaseHelper);
});

/// Provider for SubjectLocalDataSource
final subjectLocalDataSourceProvider = Provider<SubjectLocalDataSource>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return SubjectLocalDataSource(databaseHelper);
});

/// Provider for EvidenceLocalDataSource
final evidenceLocalDataSourceProvider =
    Provider<EvidenceLocalDataSource>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return EvidenceLocalDataSource(databaseHelper);
});

/// Provider for ImageCaptureDataSource
final imageCaptureDataSourceProvider =
    Provider<ImageCaptureDataSource>((ref) {
  return ImageCaptureDataSourceImpl();
});

// ============================================================================
// REPOSITORY PROVIDERS
// ============================================================================

/// Provider for CourseRepository
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final dataSource = ref.watch(courseLocalDataSourceProvider);
  final evidenceDataSource = ref.watch(evidenceLocalDataSourceProvider);
  return CourseRepositoryImpl(dataSource, evidenceDataSource);
});

/// Provider for StudentRepository
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final dataSource = ref.watch(studentLocalDataSourceProvider);
  return StudentRepositoryImpl(dataSource);
});

/// Provider for SubjectRepository
final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  final dataSource = ref.watch(subjectLocalDataSourceProvider);
  return SubjectRepositoryImpl(dataSource);
});

/// Provider for EvidenceRepository
final evidenceRepositoryProvider = Provider<EvidenceRepository>((ref) {
  final dataSource = ref.watch(evidenceLocalDataSourceProvider);
  return EvidenceRepositoryImpl(dataSource);
});
