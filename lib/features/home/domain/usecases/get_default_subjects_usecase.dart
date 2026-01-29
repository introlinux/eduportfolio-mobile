import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/core/domain/repositories/subject_repository.dart';

/// UseCase to get default subjects for the home screen
///
/// Returns the 5 default subjects (Matemáticas, Lengua, Ciencias, Inglés, Artística)
class GetDefaultSubjectsUseCase {
  final SubjectRepository _repository;

  GetDefaultSubjectsUseCase(this._repository);

  Future<List<Subject>> call() async {
    return _repository.getDefaultSubjects();
  }
}
