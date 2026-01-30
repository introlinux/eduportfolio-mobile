import 'package:eduportfolio/features/gallery/presentation/providers/gallery_providers.dart'
    as gallery;
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:eduportfolio/features/settings/presentation/providers/settings_providers.dart';
import 'package:eduportfolio/features/students/presentation/providers/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings screen for app configuration and system cleanup
class SettingsScreen extends ConsumerWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          // System Cleanup Section
          _buildSectionHeader(
            context,
            'Limpieza del Sistema',
            Icons.cleaning_services,
          ),
          _buildCleanupOption(
            context: context,
            ref: ref,
            title: 'Eliminar todas las evidencias',
            subtitle:
                'Borra todas las evidencias capturadas y sus archivos.\nMantiene estudiantes, cursos y asignaturas.',
            icon: Icons.photo_library_outlined,
            iconColor: theme.colorScheme.error,
            onTap: () => _confirmDeleteEvidences(context, ref),
          ),
          const Divider(),
          _buildCleanupOption(
            context: context,
            ref: ref,
            title: 'Eliminar estudiantes y evidencias',
            subtitle:
                'Borra todos los estudiantes, sus datos faciales y todas las evidencias.\nMantiene cursos y asignaturas.',
            icon: Icons.people_outline,
            iconColor: theme.colorScheme.error,
            onTap: () => _confirmDeleteAll(context, ref),
          ),
          const Divider(height: 32),

          // Info Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Estas operaciones son permanentes y no se pueden deshacer.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanupOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Future<void> _confirmDeleteEvidences(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar todas las evidencias?'),
        content: const Text(
          'Esta acción eliminará:\n\n'
          '• Todas las evidencias capturadas\n'
          '• Todos los archivos de fotos, videos y audios\n'
          '• Todas las miniaturas\n\n'
          'Los estudiantes, cursos y asignaturas se mantendrán.\n\n'
          'Esta acción no se puede deshacer.',
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
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteEvidences(context, ref);
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar estudiantes y evidencias?'),
        content: const Text(
          'Esta acción eliminará:\n\n'
          '• Todos los estudiantes\n'
          '• Todas las fotos de entrenamiento facial\n'
          '• Todos los datos de reconocimiento facial\n'
          '• Todas las evidencias capturadas\n'
          '• Todos los archivos de fotos, videos y audios\n\n'
          'Los cursos y asignaturas se mantendrán.\n\n'
          'Esta acción no se puede deshacer.',
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
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteAll(context, ref);
    }
  }

  Future<void> _deleteEvidences(BuildContext context, WidgetRef ref) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Eliminando evidencias...'),
          ],
        ),
      ),
    );

    try {
      final deleteUseCase = ref.read(deleteAllEvidencesUseCaseProvider);
      final deletedCount = await deleteUseCase();

      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Invalidate providers to refresh UI
        ref.invalidate(gallery.filteredEvidencesProvider);
        ref.invalidate(pendingEvidencesCountProvider);
        ref.invalidate(storageInfoProvider);

        // Show success message and navigate back to force refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deletedCount evidencias eliminadas correctamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to home to force refresh
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar evidencias: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Eliminando estudiantes y evidencias...'),
          ],
        ),
      ),
    );

    try {
      // Delete evidences first
      final deleteEvidencesUseCase = ref.read(deleteAllEvidencesUseCaseProvider);
      final evidencesDeleted = await deleteEvidencesUseCase();

      // Then delete students
      final deleteStudentsUseCase = ref.read(deleteAllStudentsUseCaseProvider);
      final studentsDeleted = await deleteStudentsUseCase();

      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Invalidate providers to refresh UI
        ref.invalidate(gallery.filteredEvidencesProvider);
        ref.invalidate(pendingEvidencesCountProvider);
        ref.invalidate(storageInfoProvider);
        ref.invalidate(filteredStudentsProvider);

        // Show success message and navigate back to force refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$studentsDeleted estudiantes y $evidencesDeleted evidencias eliminados correctamente',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to home to force refresh
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
