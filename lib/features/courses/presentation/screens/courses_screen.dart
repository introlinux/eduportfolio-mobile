import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:eduportfolio/features/courses/presentation/widgets/course_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Courses screen - Display and manage courses
///
/// Shows:
/// - List of all courses with active indicator
/// - Student count per course
/// - Options to activate, archive courses
/// - FAB to create new course
class CoursesScreen extends ConsumerWidget {
  static const routeName = '/courses';

  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coursesAsync = ref.watch(activeCoursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Cursos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed('/archived-courses');
            },
            tooltip: 'Ver cursos archivados',
          ),
        ],
      ),
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay cursos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu primer curso escolar',
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
              ref.invalidate(allCoursesProvider);
              ref.invalidate(activeCoursesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];

                return CourseCard(
                  course: course,
                  onTap: () {
                    // Navigate to course details or edit
                    Navigator.of(context).pushNamed(
                      '/course-form',
                      arguments: {'courseId': course.id},
                    );
                  },
                  onSetActive: course.endDate == null
                      ? () => _setActiveCourse(context, ref, course.id!)
                      : null,
                  onArchive: course.isActive
                      ? null
                      : () => _archiveCourse(context, ref, course.id!),
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
                'Error al cargar cursos',
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
                  ref.invalidate(allCoursesProvider);
                  ref.invalidate(activeCoursesProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/course-form');
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear curso'),
      ),
    );
  }

  Future<void> _setActiveCourse(
    BuildContext context,
    WidgetRef ref,
    int courseId,
  ) async {
    try {
      final setActiveUseCase = ref.read(setActiveCourseUseCaseProvider);
      await setActiveUseCase(courseId);

      // Invalidate providers to refresh data
      ref.invalidate(allCoursesProvider);
      ref.invalidate(activeCourseProvider);
      ref.invalidate(activeCoursesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Curso activado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al activar curso: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _archiveCourse(
    BuildContext context,
    WidgetRef ref,
    int courseId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar curso'),
        content: const Text(
          '¿Estás seguro de que quieres archivar este curso? '
          'El curso se marcará como finalizado pero los datos se conservarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final archiveUseCase = ref.read(archiveCourseUseCaseProvider);
        await archiveUseCase(courseId);

        // Invalidate providers to refresh data
        ref.invalidate(allCoursesProvider);
        ref.invalidate(activeCourseProvider);
        ref.invalidate(activeCoursesProvider);
        ref.invalidate(archivedCoursesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Curso archivado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al archivar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
