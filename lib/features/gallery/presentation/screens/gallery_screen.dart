import 'package:eduportfolio/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:eduportfolio/features/gallery/presentation/widgets/evidence_card.dart';
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:eduportfolio/features/students/presentation/providers/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gallery screen - Display all captured evidences
class GalleryScreen extends ConsumerWidget {
  static const routeName = '/gallery';

  final int? preselectedSubjectId;

  const GalleryScreen({
    this.preselectedSubjectId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final evidencesAsync = ref.watch(filteredEvidencesProvider);
    final subjectsAsync = ref.watch(defaultSubjectsProvider);
    final studentsAsync = ref.watch(filteredStudentsProvider);
    final selectedSubjectId = ref.watch(selectedSubjectFilterProvider);
    final selectedStudentId = ref.watch(selectedStudentFilterProvider);

    // Set preselected subject filter on first build
    if (preselectedSubjectId != null && selectedSubjectId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedSubjectFilterProvider.notifier).state =
            preselectedSubjectId;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería'),
        actions: [
          // Subject filter dropdown
          subjectsAsync.when(
            data: (subjects) {
              return PopupMenuButton<int?>(
                icon: Icon(
                  selectedSubjectId == null
                      ? Icons.filter_list
                      : Icons.filter_list_alt,
                ),
                tooltip: 'Filtrar por asignatura',
                onSelected: (subjectId) {
                  ref.read(selectedSubjectFilterProvider.notifier).state =
                      subjectId;
                },
                itemBuilder: (context) => [
                  PopupMenuItem<int?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(
                          selectedSubjectId == null
                              ? Icons.check
                              : Icons.check_box_outline_blank,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Todas las asignaturas'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  ...subjects.map(
                    (subject) => PopupMenuItem<int?>(
                      value: subject.id,
                      child: Row(
                        children: [
                          Icon(
                            selectedSubjectId == subject.id
                                ? Icons.check
                                : Icons.check_box_outline_blank,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(subject.name),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          // Student filter dropdown
          studentsAsync.when(
            data: (students) {
              if (students.isEmpty) return const SizedBox.shrink();

              return PopupMenuButton<int?>(
                icon: Icon(
                  selectedStudentId == null
                      ? Icons.person_outline
                      : Icons.person,
                ),
                tooltip: 'Filtrar por estudiante',
                onSelected: (studentId) {
                  ref.read(selectedStudentFilterProvider.notifier).state =
                      studentId;
                },
                itemBuilder: (context) => [
                  PopupMenuItem<int?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(
                          selectedStudentId == null
                              ? Icons.check
                              : Icons.check_box_outline_blank,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Todos los estudiantes'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  ...students.map(
                    (student) => PopupMenuItem<int?>(
                      value: student.id,
                      child: Row(
                        children: [
                          Icon(
                            selectedStudentId == student.id
                                ? Icons.check
                                : Icons.check_box_outline_blank,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(student.name),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: evidencesAsync.when(
        data: (evidences) {
          if (evidences.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyStateMessage(selectedSubjectId, selectedStudentId),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Captura tu primera evidencia',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(filteredEvidencesProvider);
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: evidences.length,
              itemBuilder: (context, index) {
                final evidence = evidences[index];

                // Get subject for this evidence
                final subject = subjectsAsync.whenOrNull(
                  data: (subjects) => subjects.firstWhere(
                    (s) => s.id == evidence.subjectId,
                    orElse: () => subjects.first,
                  ),
                );

                return EvidenceCard(
                  evidence: evidence,
                  subject: subject,
                  onTap: () {
                    // Navigate to evidence detail with all evidences for swipe navigation
                    Navigator.of(context).pushNamed(
                      '/evidence-detail',
                      arguments: {
                        'evidences': evidences,
                        'initialIndex': index,
                      },
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar evidencias',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(filteredEvidencesProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEmptyStateMessage(int? subjectId, int? studentId) {
    if (subjectId != null && studentId != null) {
      return 'No hay evidencias para este estudiante y asignatura';
    } else if (subjectId != null) {
      return 'No hay evidencias para esta asignatura';
    } else if (studentId != null) {
      return 'No hay evidencias para este estudiante';
    } else {
      return 'No hay evidencias';
    }
  }
}
