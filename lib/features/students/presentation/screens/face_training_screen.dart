import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/services/face_recognition/face_recognition_providers.dart';
import 'package:eduportfolio/features/students/presentation/providers/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Face training screen - Capture 5 photos for face recognition training
class FaceTrainingScreen extends ConsumerStatefulWidget {
  static const routeName = '/face-training';

  final Student student;

  const FaceTrainingScreen({
    required this.student,
    super.key,
  });

  @override
  ConsumerState<FaceTrainingScreen> createState() =>
      _FaceTrainingScreenState();
}

class _FaceTrainingScreenState extends ConsumerState<FaceTrainingScreen> {
  CameraController? _cameraController;
  bool _isInitializing = true;
  bool _hasPermission = false;
  String? _errorMessage;

  final List<File> _capturedPhotos = [];
  bool _isCapturing = false;
  bool _isProcessing = false;

  static const int requiredPhotos = 5;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      // Request camera permission
      final status = await Permission.camera.request();

      if (!status.isGranted) {
        setState(() {
          _isInitializing = false;
          _hasPermission = false;
          _errorMessage = 'Permiso de cámara denegado';
        });
        return;
      }

      setState(() => _hasPermission = true);

      // Get available cameras (use front camera for face training)
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No se encontró ninguna cámara';
        });
        return;
      }

      // Prefer front camera for face training
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Error al inicializar cámara: $e';
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing ||
        _capturedPhotos.length >= requiredPhotos) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      // Capture photo
      final image = await _cameraController!.takePicture();
      final file = File(image.path);

      // TODO: Validate that photo contains a face
      // For now, just add it
      setState(() {
        _capturedPhotos.add(file);
      });

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto ${_capturedPhotos.length}/$requiredPhotos capturada'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }

      // If we have all photos, process them
      if (_capturedPhotos.length >= requiredPhotos) {
        await _processPhotos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _processPhotos() async {
    setState(() => _isProcessing = true);

    try {
      // Get face recognition service
      final faceRecognitionService = ref.read(faceRecognitionServiceProvider);

      // Process training photos
      final result = await faceRecognitionService.processTrainingPhotos(
        _capturedPhotos,
      );

      if (!result.success || result.embeddingBytes.isEmpty) {
        throw Exception(result.error ?? 'Error procesando fotos');
      }

      // Update student with face embeddings
      final updateFaceDataUseCase =
          ref.read(updateStudentFaceDataUseCaseProvider);
      await updateFaceDataUseCase(
        studentId: widget.student.id!,
        faceEmbeddings: Uint8List.fromList(result.embeddingBytes),
      );

      // Clean up temporary files
      for (final photo in _capturedPhotos) {
        try {
          await photo.delete();
        } catch (_) {}
      }

      // Invalidate providers
      ref.invalidate(filteredStudentsProvider);
      ref.invalidate(studentByIdProvider(widget.student.id!));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Entrenamiento completado (${result.successfulPhotos}/5 fotos válidas)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar fotos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _removeLastPhoto() {
    if (_capturedPhotos.isEmpty) return;

    setState(() {
      final removed = _capturedPhotos.removeLast();
      // Delete file
      try {
        removed.deleteSync();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    // Clean up any remaining photos
    for (final photo in _capturedPhotos) {
      try {
        photo.deleteSync();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isProcessing) {
      return _buildProcessing(theme);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        title: const Text('Entrenamiento Facial'),
      ),
      body: Stack(
        children: [
          // Camera preview or error/loading
          if (_isInitializing)
            _buildLoading(theme)
          else if (!_hasPermission || _errorMessage != null)
            _buildError(theme)
          else if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            _buildCameraPreview()
          else
            _buildLoading(theme),

          // Overlay UI
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            _buildOverlayUI(theme),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildOverlayUI(ThemeData theme) {
    final progress = _capturedPhotos.length / requiredPhotos;

    return SafeArea(
      child: Column(
        children: [
          // Top info bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.student.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Progress bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_capturedPhotos.length}/$requiredPhotos fotos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Instructions
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.face, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  _getInstruction(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Bottom controls
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Remove last photo button
                if (_capturedPhotos.isNotEmpty)
                  IconButton(
                    onPressed: _removeLastPhoto,
                    icon: const Icon(Icons.undo, size: 32),
                    color: Colors.white,
                    tooltip: 'Deshacer última foto',
                  )
                else
                  const SizedBox(width: 48),

                // Capture button
                GestureDetector(
                  onTap: _isCapturing ||
                          _capturedPhotos.length >= requiredPhotos
                      ? null
                      : _capturePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _capturedPhotos.length >= requiredPhotos
                            ? Colors.grey
                            : Colors.white,
                        width: 4,
                      ),
                      color: _isCapturing
                          ? Colors.grey
                          : (_capturedPhotos.length >= requiredPhotos
                              ? Colors.green
                              : Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: _isCapturing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _capturedPhotos.length >= requiredPhotos
                                ? Icons.check
                                : Icons.camera_alt,
                            size: 40,
                            color: Colors.white,
                          ),
                  ),
                ),

                const SizedBox(width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInstruction() {
    switch (_capturedPhotos.length) {
      case 0:
        return 'Mira a la cámara\ny mantén el rostro centrado';
      case 1:
        return 'Gira ligeramente\nla cabeza a la izquierda';
      case 2:
        return 'Ahora gira ligeramente\na la derecha';
      case 3:
        return 'Inclina un poco\nla cabeza hacia arriba';
      case 4:
        return '¡Última foto!\nMira directamente a la cámara';
      default:
        return '¡Completado!\nProcesando fotos...';
    }
  }

  Widget _buildProcessing(ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Procesando fotos de entrenamiento...',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Esto puede tardar unos segundos',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Iniciando cámara...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Error desconocido',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!_hasPermission)
              ElevatedButton.icon(
                onPressed: () async {
                  await openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Abrir configuración'),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
