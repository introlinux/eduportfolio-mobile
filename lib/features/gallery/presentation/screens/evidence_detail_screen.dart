import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
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

class _EvidenceDetailScreenState extends ConsumerState<EvidenceDetailScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _showMetadata = false; // Metadata hidden by default for max image space

  // Transformation controller for each image to track zoom state
  final Map<int, TransformationController> _transformControllers = {};
  bool _wasZoomed = false; // Track previous zoom state to avoid unnecessary rebuilds

  // Animation controller for smooth zoom transitions
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;
  int? _animatingIndex; // Track which image is being animated

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Initialize transformation controllers for all evidences
    for (int i = 0; i < widget.evidences.length; i++) {
      _transformControllers[i] = TransformationController();
    }

    // Initialize animation controller for zoom transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_zoomAnimation != null && _animatingIndex != null) {
          _transformControllers[_animatingIndex]?.value = _zoomAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    for (var controller in _transformControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Check if current image is zoomed
  bool get _isZoomed {
    final controller = _transformControllers[_currentIndex];
    if (controller == null) return false;
    final scale = controller.value.getMaxScaleOnAxis();
    return scale > 1.01; // Small threshold for floating point comparison
  }

  // Update PageView physics only when zoom state changes
  void _updateZoomState() {
    final isZoomed = _isZoomed;
    if (isZoomed != _wasZoomed) {
      setState(() {
        _wasZoomed = isZoomed;
      });
    }
  }

  // Handle double tap with zoom animation focused on tap position
  void _handleDoubleTap(int index, Offset tapPosition) {
    final controller = _transformControllers[index]!;
    final currentScale = controller.value.getMaxScaleOnAxis();

    // Cancel any ongoing animation
    _animationController.stop();
    _animatingIndex = index;

    Matrix4 endMatrix;

    if (currentScale > 1.5) {
      // Reset to no zoom with smooth animation
      endMatrix = Matrix4.identity();
    } else {
      // Zoom to 2.5x centered on tap position
      const targetScale = 2.5;

      // Calculate transformation to zoom towards the tap position
      // The focal point (tap position) should stay in the same screen position
      final double focalPointX = tapPosition.dx;
      final double focalPointY = tapPosition.dy;

      // Create transformation matrix that zooms towards the focal point
      // Formula: translate by (focal * (1 - scale)) then scale
      // This keeps the focal point fixed in screen coordinates
      endMatrix = Matrix4.identity()
        ..translate(focalPointX * (1 - targetScale), focalPointY * (1 - targetScale))
        ..scale(targetScale);
    }

    // Create animation from current matrix to end matrix
    _zoomAnimation = Matrix4Tween(
      begin: controller.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animation
    _animationController.forward(from: 0.0).then((_) {
      _animatingIndex = null;
      _updateZoomState();
    });
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
        // Allow swipe only when not zoomed
        physics: _isZoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
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
              // Image with zoom/pan (pinch to zoom, drag to pan when zoomed)
              Expanded(
                child: GestureDetector(
                  onDoubleTapDown: (details) {
                    // Capture tap position for zoom focus
                    _handleDoubleTap(index, details.localPosition);
                  },
                  child: InteractiveViewer(
                    transformationController: _transformControllers[index],
                    minScale: 1.0,
                    maxScale: 4.0,
                    panEnabled: true,
                    scaleEnabled: true,
                    constrained: true,
                    // Proper boundaries to prevent black frames
                    boundaryMargin: const EdgeInsets.all(0),
                    onInteractionUpdate: (details) {
                      // Update PageView physics only if zoom state changed
                      _updateZoomState();
                    },
                    onInteractionEnd: (details) {
                      // Final update when interaction ends
                      _updateZoomState();
                    },
                    child: Center(
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
                    // Subject dropdown (editable)
                    Text(
                      'Asignatura',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    subjectsAsync.when(
                      data: (subjects) => DropdownButtonFormField<int>(
                        value: evidence.subjectId,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: subjects.map((s) {
                          return DropdownMenuItem<int>(
                            value: s.id,
                            child: Text(s.name),
                          );
                        }).toList(),
                        onChanged: (newSubjectId) async {
                          if (newSubjectId != null) {
                            await _updateSubject(newSubjectId, ref);
                          }
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Error cargando asignaturas'),
                    ),
                    const SizedBox(height: 16),

                    // Student dropdown (editable)
                    Text(
                      'Estudiante',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    studentsAsync.when(
                      data: (students) => DropdownButtonFormField<int?>(
                        value: evidence.studentId,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Sin asignar'),
                          ),
                          ...students.map((s) {
                            return DropdownMenuItem<int?>(
                              value: s.id,
                              child: Text(s.name),
                            );
                          }),
                        ],
                        onChanged: (newStudentId) async {
                          await _updateStudent(newStudentId, ref);
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Error cargando estudiantes'),
                    ),
                    const SizedBox(height: 16),
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

  Future<void> _updateSubject(int newSubjectId, WidgetRef ref) async {
    try {
      final updatedEvidence = _currentEvidence.copyWith(subjectId: newSubjectId);
      final repository = ref.read(evidenceRepositoryProvider);
      await repository.updateEvidence(updatedEvidence);

      // Refresh providers
      ref.invalidate(filteredEvidencesProvider);
      ref.invalidate(pendingEvidencesCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asignatura actualizada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateStudent(int? newStudentId, WidgetRef ref) async {
    try {
      final repository = ref.read(evidenceRepositoryProvider);

      if (newStudentId != null) {
        // Assign to student (also updates isReviewed automatically)
        await repository.assignEvidenceToStudent(
          _currentEvidence.id!,
          newStudentId,
        );
      } else {
        // Unassign (set to null) - create new instance with explicit null
        final updatedEvidence = Evidence(
          id: _currentEvidence.id,
          studentId: null, // Explicitly set to null
          subjectId: _currentEvidence.subjectId,
          type: _currentEvidence.type,
          filePath: _currentEvidence.filePath,
          thumbnailPath: _currentEvidence.thumbnailPath,
          fileSize: _currentEvidence.fileSize,
          duration: _currentEvidence.duration,
          captureDate: _currentEvidence.captureDate,
          isReviewed: false, // Unassigned means not reviewed
          notes: _currentEvidence.notes,
          createdAt: _currentEvidence.createdAt,
        );
        await repository.updateEvidence(updatedEvidence);
      }

      // Refresh providers
      ref.invalidate(filteredEvidencesProvider);
      ref.invalidate(pendingEvidencesCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStudentId != null
                  ? 'Estudiante asignado'
                  : 'Estudiante desasignado',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
