import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget to display the active course indicator
///
/// Shows the name of the currently active course
/// Tapping it navigates to the courses management screen
class ActiveCourseIndicator extends ConsumerWidget {
  final bool compact;

  const ActiveCourseIndicator({
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeCourseAsync = ref.watch(activeCourseProvider);

    return activeCourseAsync.when(
      data: (course) {
        if (course == null) {
          return _buildNoCourseCard(context, theme);
        }

        return InkWell(
          onTap: () {
            Navigator.of(context).pushNamed('/courses');
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: compact ? 16 : 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                SizedBox(width: compact ? 6 : 8),
                if (compact)
                  Text(
                    course.name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Curso activo',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          course.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(width: compact ? 4 : 8),
                Icon(
                  Icons.chevron_right,
                  size: compact ? 16 : 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cargando...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => _buildNoCourseCard(context, theme),
    );
  }

  Widget _buildNoCourseCard(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed('/courses');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: compact ? 16 : 20,
              color: theme.colorScheme.onErrorContainer,
            ),
            SizedBox(width: compact ? 6 : 8),
            Expanded(
              child: Text(
                compact ? 'Sin curso activo' : 'No hay curso activo',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: compact ? 4 : 8),
            Icon(
              Icons.chevron_right,
              size: compact ? 16 : 20,
              color: theme.colorScheme.onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }
}
