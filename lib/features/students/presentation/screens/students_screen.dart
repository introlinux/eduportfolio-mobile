import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/features/students/presentation/providers/student_providers.dart';
import 'package:eduportfolio/features/students/presentation/widgets/student_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Students screen - Display and manage students
///
/// Shows:
/// - List of students from active course
/// - Student count
/// - FAB to add new student
class StudentsScreen extends ConsumerWidget {
  static const routeName = '/students';

  final int? preselectedCourseId;

  const StudentsScreen({
    this.preselectedCourseId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final studentsAsync = ref.watch(filteredStudentsProvider);
    final selectedCourseId = ref.watch(selectedCourseFilterProvider);

    // Set preselected course filter on first build
    if (preselectedCourseId != null && selectedCourseId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCourseFilterProvider.notifier).state =
            preselectedCourseId;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudiantes'),
        actions: [
          // Student count badge
          studentsAsync.whenOrNull(
            data: (students) => Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${students.length} estudiantes',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay estudiantes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Añade tu primer estudiante',
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
              ref.invalidate(filteredStudentsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];

                return StudentCard(
                  student: student,
                  onTap: () {
                    // Navigate to student detail
                    Navigator.of(context).pushNamed(
                      '/student-detail',
                      arguments: {'studentId': student.id},
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
                'Error al cargar estudiantes',
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
                  ref.invalidate(filteredStudentsProvider);
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
          // Navigate to student form (create)
          Navigator.of(context).pushNamed('/student-form');
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Añadir estudiante'),
      ),
    );
  }
}
