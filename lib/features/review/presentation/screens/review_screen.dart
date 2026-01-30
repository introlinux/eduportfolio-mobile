import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:eduportfolio/features/gallery/presentation/providers/gallery_providers.dart'
    as gallery;
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:eduportfolio/features/review/presentation/providers/review_providers.dart';
import 'package:eduportfolio/features/review/presentation/widgets/batch_action_bar.dart';
import 'package:eduportfolio/features/review/presentation/widgets/evidence_preview_dialog.dart';
import 'package:eduportfolio/features/review/presentation/widgets/evidence_review_card.dart';
import 'package:eduportfolio/features/students/presentation/providers/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Review screen for manually assigning unassigned evidences to students
///
/// Supports multi-selection and batch operations
class ReviewScreen extends ConsumerWidget {
  static const routeName = '/review';

  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unassignedAsync = ref.watch(unassignedEvidencesProvider);
    final subjectsAsync = ref.watch(defaultSubjectsProvider);
    final selectionMode = ref.watch(selectionModeProvider);
    final selectedEvidences = ref.watch(selectedEvidencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: unassignedAsync.when(
          data: (evidences) => Text('Revisar (${evidences.length})'),
          loading: () => const Text('Revisar'),
          error: (_, __) => const Text('Revisar'),
        ),
        actions: [
          // Selection mode toggle
          if (!selectionMode)
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () {
                ref.read(selectionModeProvider.notifier).state = true;
              },
              tooltip: 'Seleccionar',
            )
          else
            TextButton(
              onPressed: () {
                ref.read(selectionModeProvider.notifier).state = false;
                ref.read(selectedEvidencesProvider.notifier).state = {};
              },
              child: const Text('Listo'),
            ),
        ],
      ),
      body: unassignedAsync.when(
        data: (evidences) {
          if (evidences.isEmpty) {
            return _buildEmptyState(theme);
          }

          return Stack(
            children: [
              // Evidence list
              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(unassignedEvidencesProvider);
                },
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: selectedEvidences.isNotEmpty ? 250 : 16,
                  ),
                  itemCount: evidences.length,
                  itemBuilder: (context, index) {
                    final evidence = evidences[index];
                    final isSelected =
                        selectedEvidences.contains(evidence.id);

                    // Get subject for this evidence
                    final subject = subjectsAsync.whenOrNull(
                      data: (subjects) => subjects.firstWhere(
                        (s) => s.id == evidence.subjectId,
                        orElse: () => subjects.first,
                      ),
                    );

                    return EvidenceReviewCard(
                      evidence: evidence,
                      subject: subject,
                      isSelected: isSelected,
                      selectionMode: selectionMode,
                      onTap: () => _openPreview(context, ref, evidences, index),
                      onSelectionChanged: (selected) {
                        final currentSelection = ref
                            .read(selectedEvidencesProvider.notifier)
                            .state;
                        if (selected) {
                          ref.read(selectedEvidencesProvider.notifier).state = {
                            ...currentSelection,
                            evidence.id!,
                          };
                          // Auto-enable selection mode when selecting
                          ref.read(selectionModeProvider.notifier).state = true;
                        } else {
                          ref.read(selectedEvidencesProvider.notifier).state =
                              currentSelection
                                  .where((id) => id != evidence.id)
                                  .toSet();
                        }
                      },
                    );
                  },
                ),
              ),

              // Batch action bar (shown when items selected)
              if (selectedEvidences.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBatchActionBar(context, ref),
                ),
            ],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '¡Todo revisado!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay evidencias pendientes de revisión.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBatchActionBar(BuildContext context, WidgetRef ref) {
    final selectedEvidences = ref.watch(selectedEvidencesProvider);
    final activeCourseAsync = ref.watch(activeCourseProvider);

    return activeCourseAsync.when(
      data: (activeCourse) {
        if (activeCourse == null) {
          return Container(
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.all(16),
            child: const Text(
              'No hay curso activo. Crea un curso para asignar evidencias.',
              textAlign: TextAlign.center,
            ),
          );
        }

        final studentsAsync =
            ref.watch(getStudentsByCourseUseCaseProvider)(activeCourse.id!);

        return FutureBuilder<List<Student>>(
          future: studentsAsync,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final students = snapshot.data!;

            if (students.isEmpty) {
              return Container(
                color: Theme.of(context).colorScheme.errorContainer,
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'No hay estudiantes en el curso activo.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return BatchActionBar(
              selectedCount: selectedEvidences.length,
              students: students,
              onAssign: (studentId) =>
                  _handleBatchAssign(context, ref, studentId),
              onDelete: () => _handleBatchDelete(context, ref),
              onCancel: () {
                ref.read(selectionModeProvider.notifier).state = false;
                ref.read(selectedEvidencesProvider.notifier).state = {};
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Container(
        color: Theme.of(context).colorScheme.errorContainer,
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Error al cargar curso activo',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _openPreview(
    BuildContext context,
    WidgetRef ref,
    List<Evidence> evidences,
    int index,
  ) async {
    final activeCourse = await ref.read(activeCourseProvider.future);

    if (activeCourse == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay curso activo'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final students =
        await ref.read(getStudentsByCourseUseCaseProvider)(activeCourse.id!);

    if (students.isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay estudiantes en el curso activo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final subjects = await ref.read(defaultSubjectsProvider.future);

    if (!context.mounted) return;

    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => EvidencePreviewDialog(
        allEvidences: evidences,
        initialIndex: index,
        students: students,
        subjects: subjects,
        onAssign: (evidenceId, studentId) =>
            _handleAssign(context, ref, evidenceId, studentId),
        onDelete: (evidenceId) => _handleDelete(context, ref, evidenceId),
      ),
    );

    if (changed == true) {
      ref.invalidate(unassignedEvidencesProvider);
      ref.invalidate(gallery.filteredEvidencesProvider);
    }
  }

  Future<void> _handleAssign(
    BuildContext context,
    WidgetRef ref,
    int evidenceId,
    int studentId,
  ) async {
    final assignUseCase = ref.read(assignEvidenceToStudentUseCaseProvider);
    await assignUseCase(evidenceId: evidenceId, studentId: studentId);
    ref.invalidate(unassignedEvidencesProvider);
    ref.invalidate(gallery.filteredEvidencesProvider);
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    int evidenceId,
  ) async {
    final deleteUseCase = ref.read(deleteEvidenceUseCaseProvider);
    await deleteUseCase(evidenceId);
    ref.invalidate(unassignedEvidencesProvider);
    ref.invalidate(gallery.filteredEvidencesProvider);
  }

  Future<void> _handleBatchAssign(
    BuildContext context,
    WidgetRef ref,
    int studentId,
  ) async {
    final selectedEvidences = ref.read(selectedEvidencesProvider);
    final assignMultipleUseCase =
        ref.read(assignMultipleEvidencesUseCaseProvider);

    try {
      await assignMultipleUseCase(
        evidenceIds: selectedEvidences.toList(),
        studentId: studentId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${selectedEvidences.length} evidencias asignadas correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear selection and refresh
      ref.read(selectionModeProvider.notifier).state = false;
      ref.read(selectedEvidencesProvider.notifier).state = {};
      ref.invalidate(unassignedEvidencesProvider);
      ref.invalidate(gallery.filteredEvidencesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleBatchDelete(BuildContext context, WidgetRef ref) async {
    final selectedEvidences = ref.read(selectedEvidencesProvider);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar evidencias?'),
        content: Text(
          '¿Estás seguro de que quieres eliminar ${selectedEvidences.length} evidencia${selectedEvidences.length != 1 ? 's' : ''}?\n\n'
          'Esta acción no se puede deshacer.\n'
          'Los archivos se eliminarán permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final deleteMultipleUseCase =
          ref.read(deleteMultipleEvidencesUseCaseProvider);
      final deletedCount =
          await deleteMultipleUseCase(selectedEvidences.toList());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deletedCount evidencias eliminadas'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Clear selection and refresh
      ref.read(selectionModeProvider.notifier).state = false;
      ref.read(selectedEvidencesProvider.notifier).state = {};
      ref.invalidate(unassignedEvidencesProvider);
      ref.invalidate(gallery.filteredEvidencesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
