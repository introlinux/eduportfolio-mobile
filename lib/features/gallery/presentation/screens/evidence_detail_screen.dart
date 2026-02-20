import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:eduportfolio/core/utils/logger.dart';
import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';

import 'package:eduportfolio/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:eduportfolio/features/gallery/presentation/widgets/share_preview_dialog.dart';
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:eduportfolio/features/students/presentation/providers/student_providers.dart';
import 'package:eduportfolio/features/subjects/presentation/providers/subject_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:video_player/video_player.dart';

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

  // Local cache of updated evidences to reflect changes immediately
  final Map<int, Evidence> _updatedEvidences = {};

  // Transformation controller for each image to track zoom state
  final Map<int, TransformationController> _transformControllers = {};
  bool _wasZoomed = false; // Track previous zoom state to avoid unnecessary rebuilds

  // Animation controller for smooth zoom transitions
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;
  int? _animatingIndex; // Track which image is being animated

  // Video player controllers
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  int? _activeVideoIndex;

  // Audio player controllers
  ja.AudioPlayer? _audioPlayer;
  int? _activeAudioIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Auto-expand metadata panel if current evidence needs review
    final initialEvidence = widget.evidences[widget.initialIndex];
    _showMetadata = initialEvidence.needsReview;

    // Initialize media player if initial evidence is video or audio
    if (initialEvidence.type == EvidenceType.video) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initVideoPlayer(widget.initialIndex);
      });
    } else if (initialEvidence.type == EvidenceType.audio) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initAudioPlayer(widget.initialIndex);
      });
    }

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
    _disposeVideoControllers();
    _disposeAudioPlayer();
    for (var controller in _transformControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _disposeVideoControllers() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
    _activeVideoIndex = null;
  }

  void _disposeAudioPlayer() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _activeAudioIndex = null;
  }

  Future<void> _initAudioPlayer(int index) async {
    final evidence = _getEvidence(index);
    if (evidence.type != EvidenceType.audio) return;
    if (_activeAudioIndex == index) return;

    _disposeAudioPlayer();
    _activeAudioIndex = index;

    try {
      _audioPlayer = ja.AudioPlayer();
      await _audioPlayer!.setFilePath(evidence.filePath);

      if (mounted) setState(() {});
    } catch (e) {
      Logger.error('Error initializing audio player', e);
    }
  }

  Future<void> _initVideoPlayer(int index) async {
    final evidence = _getEvidence(index);
    if (evidence.type != EvidenceType.video) return;
    if (_activeVideoIndex == index) return; // Already initialized

    // Dispose previous video controllers if any
    _disposeVideoControllers();
    _activeVideoIndex = index;

    try {
      _videoPlayerController = VideoPlayerController.file(
        File(evidence.filePath),
      );
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        showControls: true,
        allowFullScreen: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blue,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightBlue.withValues(alpha: 0.3),
        ),
      );

      if (mounted) setState(() {});
    } catch (e) {
      Logger.error('Error initializing video player', e);
    }
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

  Evidence get _currentEvidence =>
      _updatedEvidences[_currentIndex] ?? widget.evidences[_currentIndex];

  // Get evidence for any index, using cache if available
  Evidence _getEvidence(int index) =>
      _updatedEvidences[index] ?? widget.evidences[index];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(allSubjectsProvider);
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
            icon: const Icon(Icons.share),
            onPressed: () => _handleShare(context, ref),
            tooltip: 'Compartir',
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
            // Auto-expand metadata if new evidence needs review
            final newEvidence = _getEvidence(index);
            if (newEvidence.needsReview) {
              _showMetadata = true;
            }
            // Initialize media player based on type
            if (newEvidence.type == EvidenceType.video) {
              _disposeAudioPlayer();
              _initVideoPlayer(index);
            } else if (newEvidence.type == EvidenceType.audio) {
              _disposeVideoControllers();
              _initAudioPlayer(index);
            } else {
              _disposeVideoControllers();
              _disposeAudioPlayer();
            }
          });
        },
        itemBuilder: (context, index) {
          // Use cached evidence if available, otherwise original
          final evidence = _getEvidence(index);

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
              // Content: Image with zoom/pan, Video player, or Audio player
              Expanded(
                child: evidence.type == EvidenceType.video
                    ? _buildVideoPlayer(evidence, index)
                    : evidence.type == EvidenceType.audio
                        ? _buildAudioPlayer(evidence, index)
                        : GestureDetector(
                        onDoubleTapDown: (details) {
                          _handleDoubleTap(index, details.localPosition);
                        },
                        child: InteractiveViewer(
                          transformationController: _transformControllers[index],
                          minScale: 1.0,
                          maxScale: 4.0,
                          panEnabled: true,
                          scaleEnabled: true,
                          constrained: true,
                          boundaryMargin: const EdgeInsets.all(0),
                          onInteractionUpdate: (details) {
                            _updateZoomState();
                          },
                          onInteractionEnd: (details) {
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
                      data: (subjects) {
                        final uniqueSubjects = <int, Subject>{};
                        for (final subject in subjects) {
                          if (subject.id != null) {
                            uniqueSubjects[subject.id!] = subject;
                          }
                        }

                        final subjectsList = uniqueSubjects.values.toList()
                          ..sort((a, b) => a.name.compareTo(b.name));

                        // If current subjectId doesn't exist in list, use first available
                        final validSubjectId = uniqueSubjects.containsKey(evidence.subjectId)
                            ? evidence.subjectId
                            : (subjectsList.isNotEmpty ? subjectsList.first.id : null);

                        return DropdownButtonFormField<int>(
                          value: validSubjectId,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          items: subjectsList.map((s) {
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
                        );
                      },
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
                      data: (students) {
                        final uniqueStudents = <int, Student>{};
                        for (final student in students) {
                          if (student.id != null) {
                            uniqueStudents[student.id!] = student;
                          }
                        }

                        final studentsList = uniqueStudents.values.toList()
                          ..sort((a, b) => a.name.compareTo(b.name));

                        // Validate that current studentId exists in list (or allow null)
                        final validStudentId = evidence.studentId == null ||
                                uniqueStudents.containsKey(evidence.studentId)
                            ? evidence.studentId
                            : null;

                        return DropdownButtonFormField<int?>(
                          value: validStudentId,
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
                            ...studentsList.map((s) {
                              return DropdownMenuItem<int?>(
                                value: s.id,
                                child: Text(s.name),
                              );
                            }),
                          ],
                          onChanged: (newStudentId) async {
                            await _updateStudent(newStudentId, ref);
                          },
                        );
                      },
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
                    // Duration (video/audio)
                    if (evidence.duration != null &&
                        (evidence.type == EvidenceType.video ||
                            evidence.type == EvidenceType.audio))
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(evidence.duration!),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    if (evidence.duration != null &&
                        (evidence.type == EvidenceType.video ||
                            evidence.type == EvidenceType.audio))
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
      // Mark as reviewed if evidence has both subject and student assigned
      final hasStudent = _currentEvidence.studentId != null;
      final shouldBeReviewed = hasStudent; // Has student AND will have subject

      final updatedEvidence = _currentEvidence.copyWith(
        subjectId: newSubjectId,
        isReviewed: shouldBeReviewed,
      );
      final repository = ref.read(evidenceRepositoryProvider);
      await repository.updateEvidence(updatedEvidence);

      // Update local cache and rebuild to show changes immediately
      setState(() {
        _updatedEvidences[_currentIndex] = updatedEvidence;
      });

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

      // Mark as reviewed only if has both subject and student
      final hasStudentAfterUpdate = newStudentId != null;
      final shouldBeReviewed = hasStudentAfterUpdate;

      // Update with new student and reviewed status
      final updatedEvidence = _currentEvidence.copyWith(
        studentId: newStudentId, // Can be null to unassign
        isReviewed: shouldBeReviewed,
      );

      await repository.updateEvidence(updatedEvidence);

      // Update local cache and rebuild to show changes immediately
      setState(() {
        _updatedEvidences[_currentIndex] = updatedEvidence;
      });

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

  Future<void> _handleShare(BuildContext context, WidgetRef ref) async {
    final evidence = _currentEvidence;
    final file = File(evidence.filePath);
    final privacyService = ref.read(privacyServiceProvider);
    final videoPrivacyService = ref.read(media3VideoPrivacyServiceProvider);

    await showDialog(
      context: context,
      builder: (context) => SharePreviewDialog(
        originalFiles: [file],
        thumbnailPaths: evidence.thumbnailPath != null 
            ? {evidence.filePath: evidence.thumbnailPath!} 
            : null,
        privacyService: privacyService,
        videoPrivacyService: videoPrivacyService,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildAudioPlayer(Evidence evidence, int index) {
    // Trigger initialization if not already done
    if (_activeAudioIndex != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initAudioPlayer(index);
      });
    }

    return Stack(
      children: [
        // Cover image as background
        if (evidence.thumbnailPath != null)
          Positioned.fill(
            child: Image.file(
              File(evidence.thumbnailPath!),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.mic, size: 64, color: Colors.white54),
              ),
            ),
          )
        else
          const Center(
            child: Icon(Icons.mic, size: 64, color: Colors.white54),
          ),

        // Audio controls overlay at bottom
        if (_audioPlayer != null && _activeAudioIndex == index)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play/pause button
                  StreamBuilder<ja.PlayerState>(
                    stream: _audioPlayer!.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final playing = playerState?.playing ?? false;
                      final processingState = playerState?.processingState;

                      if (processingState == ja.ProcessingState.completed) {
                        // Reset to beginning when completed
                        return IconButton(
                          iconSize: 56,
                          icon: const Icon(Icons.replay, color: Colors.white),
                          onPressed: () {
                            _audioPlayer!.seek(Duration.zero);
                            _audioPlayer!.play();
                          },
                        );
                      }

                      return IconButton(
                        iconSize: 56,
                        icon: Icon(
                          playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (playing) {
                            _audioPlayer!.pause();
                          } else {
                            _audioPlayer!.play();
                          }
                        },
                      );
                    },
                  ),
                  // Seek bar
                  StreamBuilder<Duration>(
                    stream: _audioPlayer!.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = _audioPlayer!.duration ?? Duration.zero;

                      return Row(
                        children: [
                          Text(
                            _formatDurationMs(position),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: duration.inMilliseconds > 0
                                  ? position.inMilliseconds
                                      .toDouble()
                                      .clamp(0, duration.inMilliseconds.toDouble())
                                  : 0,
                              max: duration.inMilliseconds > 0
                                  ? duration.inMilliseconds.toDouble()
                                  : 1,
                              activeColor: Colors.blue,
                              inactiveColor: Colors.white24,
                              onChanged: (value) {
                                _audioPlayer!.seek(
                                  Duration(milliseconds: value.toInt()),
                                );
                              },
                            ),
                          ),
                          Text(
                            _formatDurationMs(duration),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }

  String _formatDurationMs(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildVideoPlayer(Evidence evidence, int index) {
    // Trigger initialization if not already done
    if (_activeVideoIndex != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initVideoPlayer(index);
      });
    }

    if (_chewieController != null && _activeVideoIndex == index) {
      return Chewie(controller: _chewieController!);
    }

    // Show loading state or thumbnail while initializing
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (evidence.thumbnailPath != null)
            Expanded(
              child: Image.file(
                File(evidence.thumbnailPath!),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.videocam,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            )
          else
            const Icon(
              Icons.videocam,
              size: 64,
              color: Colors.white54,
            ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 8),
          const Text(
            'Cargando vídeo...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
