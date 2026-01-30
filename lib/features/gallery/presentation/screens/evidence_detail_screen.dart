import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:eduportfolio/features/students/presentation/providers/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Evidence detail screen - Full-screen view with swipe navigation
class EvidenceDetailScreen extends ConsumerStatefulWidget {
  static const routeName = '/evidence-detail';

  final List<Evidence> evidences;
  final int initialIndex;

  const EvidenceDetailScreen({
    required this.evidences,
    required this.initialIndex,
    super.key,
  });

  @override
  ConsumerState<EvidenceDetailScreen> createState() =>
      _EvidenceDetailScreenState();
}

class _EvidenceDetailScreenState extends ConsumerState<EvidenceDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showMetadata = false; // Metadata hidden by default for max image space

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Evidence get _currentEvidence => widget.evidences[_currentIndex];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(defaultSubjectsProvider);
    final studentsAsync = ref.watch(filteredStudentsProvider);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.evidences.length}'),
        actions: [
          IconButton(
            icon: Icon(_showMetadata ? Icons.info : Icons.info_outline),
            onPressed: () {
              setState(() {
                _showMetadata = !_showMetadata;
              });
            },
            tooltip: _showMetadata ? 'Ocultar información' : 'Mostrar información',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context, ref),
            tooltip: 'Eliminar',
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.evidences.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final evidence = widget.evidences[index];

          final subject = subjectsAsync.whenOrNull(
            data: (subjects) {
              try {
                return subjects.firstWhere((s) => s.id == evidence.subjectId);
              } catch (e) {
                return null;
              }
            },
          );

          final student = studentsAsync.whenOrNull(
            data: (students) {
              if (evidence.studentId == null) return null;
              try {
                return students.firstWhere((s) => s.id == evidence.studentId);
              } catch (e) {
                return null;
              }
            },
          );

          return Column(
            children: [
              // Image with zoom/pan (pinch to zoom, drag to pan)
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 8.0, // High zoom for reading small text
                    panEnabled: true,
                    scaleEnabled: true,
                    // constrained: true (default) - fits image to screen initially
                    child: Image.file(
                      File(evidence.filePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Metadata section (collapsible with animation)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _showMetadata
                    ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Student (if assigned)
                    if (student != null) ...[
                      Text(
                        'Estudiante',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Subject
                    if (subject != null) ...[
                      Text(
                        'Asignatura',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Capture date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(evidence.captureDate),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // File size
                    if (evidence.fileSizeMB != null)
                      Row(
                        children: [
                          Icon(
                            Icons.storage,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${evidence.fileSizeMB!.toStringAsFixed(2)} MB',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    // Review status
                    Row(
                      children: [
                        Icon(
                          evidence.isReviewed
                              ? Icons.check_circle
                              : Icons.pending,
                          size: 16,
                          color: evidence.isReviewed
                              ? Colors.green
                              : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          evidence.isReviewed
                              ? 'Revisada'
                              : 'Pendiente de revisar',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: evidence.isReviewed
                                ? Colors.green
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evidencia'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta evidencia? '
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Delete evidence
        final deleteUseCase = ref.read(deleteEvidenceUseCaseProvider);
        await deleteUseCase(_currentEvidence.id!);

        // Invalidate providers to refresh data
        ref.invalidate(filteredEvidencesProvider);
        ref.invalidate(pendingEvidencesCountProvider);
        ref.invalidate(storageInfoProvider);

        if (context.mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evidencia eliminada'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back if no more evidences, otherwise stay
          if (widget.evidences.length == 1) {
            Navigator.of(context).pop();
          }
        }
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
}
