import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/features/subjects/presentation/providers/subject_providers.dart';
import 'package:eduportfolio/features/subjects/presentation/widgets/subject_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for managing subjects (CRUD operations)
class SubjectsManagementScreen extends ConsumerWidget {
  static const routeName = '/subjects-management';

  const SubjectsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(allSubjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Asignaturas'),
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay asignaturas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu primera asignatura',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort subjects: default first, then alphabetically
          final sortedSubjects = [...subjects]..sort((a, b) {
              if (a.isDefault && !b.isDefault) return -1;
              if (!a.isDefault && b.isDefault) return 1;
              return a.name.compareTo(b.name);
            });

          return ListView.builder(
            itemCount: sortedSubjects.length,
            itemBuilder: (context, index) {
              final subject = sortedSubjects[index];
              return _SubjectListTile(subject: subject);
            },
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
                'Error al cargar asignaturas',
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
                  ref.invalidate(allSubjectsProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Asignatura'),
      ),
    );
  }

  Future<void> _showSubjectDialog(
    BuildContext context,
    WidgetRef ref,
    Subject? subject,
  ) async {
    final result = await showDialog<Subject>(
      context: context,
      builder: (context) => SubjectFormDialog(subject: subject),
    );

    if (result != null && context.mounted) {
      try {
        if (subject == null) {
          // Create new subject
          await ref.read(createSubjectProvider)(result);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Asignatura creada'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Update existing subject
          await ref.read(updateSubjectProvider)(result);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Asignatura actualizada'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// List tile widget for displaying a subject
class _SubjectListTile extends ConsumerWidget {
  final Subject subject;

  const _SubjectListTile({required this.subject});

  Color _getColorFromString(String? colorString) {
    if (colorString == null) return _getDefaultColor();
    try {
      return Color(int.parse(colorString));
    } catch (e) {
      return _getDefaultColor();
    }
  }

  Color _getDefaultColor() {
    // Default color based on subject name
    switch (subject.name.toLowerCase()) {
      case 'matemáticas':
        return const Color(0xFF1E88E5);
      case 'lengua':
        return const Color(0xFFE53935);
      case 'ciencias':
        return const Color(0xFF43A047);
      case 'inglés':
        return const Color(0xFFFB8C00);
      case 'artística':
        return const Color(0xFF8E24AA);
      default:
        return const Color(0xFF2196F3);
    }
  }

  IconData _getIconFromString(String? iconString) {
    if (iconString == null) return _getDefaultIcon();

    final iconMap = {
      'book': Icons.book,
      'calculate': Icons.calculate,
      'science': Icons.science,
      'language': Icons.language,
      'palette': Icons.palette,
      'music_note': Icons.music_note,
      'sports_soccer': Icons.sports_soccer,
      'history_edu': Icons.history_edu,
      'map': Icons.map,
      'computer': Icons.computer,
      'edit': Icons.edit,
      'menu_book': Icons.menu_book,
      'help_outline': Icons.help_outline,
    };
    return iconMap[iconString] ?? _getDefaultIcon();
  }

  IconData _getDefaultIcon() {
    // Default icon based on subject name
    switch (subject.name.toLowerCase()) {
      case 'matemáticas':
        return Icons.calculate;
      case 'lengua':
        return Icons.menu_book;
      case 'ciencias':
        return Icons.science;
      case 'inglés':
        return Icons.language;
      case 'artística':
        return Icons.palette;
      default:
        return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = subject.color != null
        ? _getColorFromString(subject.color!)
        : theme.colorScheme.primary;
    final icon = subject.icon != null
        ? _getIconFromString(subject.icon!)
        : Icons.book;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                subject.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (subject.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DEFAULT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editSubject(context, ref),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: theme.colorScheme.error,
              onPressed: () => _deleteSubject(context, ref),
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSubject(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Subject>(
      context: context,
      builder: (context) => SubjectFormDialog(subject: subject),
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(updateSubjectProvider)(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asignatura actualizada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSubject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar asignatura'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${subject.name}"?\n\n'
          'Si hay evidencias asociadas:\n'
          '• Se moverán a "Sin Asignación"\n'
          '• Se marcarán como pendientes de revisar\n'
          '• Las evidencias NO se eliminarán\n\n'
          'Podrás reasignarlas más tarde desde la pantalla de revisión.',
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

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(deleteSubjectProvider)(subject.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asignatura eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }
}
