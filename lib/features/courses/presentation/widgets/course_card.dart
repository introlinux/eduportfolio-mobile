import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Card widget to display a course in the list
class CourseCard extends ConsumerWidget {
  final Course course;
  final VoidCallback? onTap;
  final VoidCallback? onSetActive;
  final VoidCallback? onArchive;

  const CourseCard({
    required this.course,
    this.onTap,
    this.onSetActive,
    this.onArchive,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final studentCountAsync = course.id != null
        ? ref.watch(courseStudentCountProvider(course.id!))
        : const AsyncValue.data(0);

    final isArchived = course.endDate != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: course.isActive ? 2 : 0,
      color: course.isActive
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and badges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: course.isActive
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                  ),
                  if (course.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ACTIVO',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isArchived && !course.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ARCHIVADO',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Start date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: course.isActive
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Inicio: ${dateFormat.format(course.startDate)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: course.isActive
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (course.endDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.event_busy,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fin: ${dateFormat.format(course.endDate!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Student count
              studentCountAsync.when(
                data: (count) => Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: course.isActive
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count estudiantes',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: course.isActive
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              // Action buttons
              if (!course.isActive || isArchived) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!course.isActive && !isArchived)
                      TextButton.icon(
                        onPressed: onSetActive,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Activar'),
                      ),
                    if (!isArchived)
                      TextButton.icon(
                        onPressed: onArchive,
                        icon: const Icon(Icons.archive_outlined, size: 18),
                        label: const Text('Archivar'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
