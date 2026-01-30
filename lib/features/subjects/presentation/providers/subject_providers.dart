import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to get all subjects
final allSubjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final repository = ref.watch(subjectRepositoryProvider);
  return repository.getAllSubjects();
});

/// Provider to create a new subject
final createSubjectProvider = Provider((ref) {
  final repository = ref.read(subjectRepositoryProvider);
  return (Subject subject) async {
    final id = await repository.createSubject(subject);
    ref.invalidate(allSubjectsProvider);
    ref.invalidate(defaultSubjectsProvider); // From home_providers
    return id;
  };
});

/// Provider to update a subject
final updateSubjectProvider = Provider((ref) {
  final repository = ref.read(subjectRepositoryProvider);
  return (Subject subject) async {
    await repository.updateSubject(subject);
    ref.invalidate(allSubjectsProvider);
    ref.invalidate(defaultSubjectsProvider); // From home_providers
  };
});

/// Provider to delete a subject
final deleteSubjectProvider = Provider((ref) {
  final repository = ref.read(subjectRepositoryProvider);
  return (int subjectId) async {
    await repository.deleteSubject(subjectId);
    ref.invalidate(allSubjectsProvider);
    ref.invalidate(defaultSubjectsProvider); // From home_providers
  };
});
