import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/core/services/face_recognition/face_recognition_providers.dart';
import 'package:eduportfolio/features/capture/presentation/providers/capture_providers.dart';
import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:eduportfolio/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Quick capture screen with active camera for fast evidence capture
class QuickCaptureScreen extends ConsumerStatefulWidget {
  static const routeName = '/quick-capture';

  final int subjectId;
  final Subject subject;

  const QuickCaptureScreen({
    required this.subjectId,
    required this.subject,
    super.key,
  });

  @override
  ConsumerState<QuickCaptureScreen> createState() =>
      _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends ConsumerState<QuickCaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;
  bool _isInitializing = true;
  bool _hasPermission = false;
  String? _errorMessage;
  int _capturedCount = 0;
  bool _isCapturing = false;
  String? _previewImagePath;
  String? _recognizedStudentName;
  int? _recognizedStudentId;

  // Live recognition state
  String? _liveRecognitionName;
  int? _liveRecognizedStudentId;
  bool _isProcessingFrame = false;
  DateTime? _lastProcessTime;
  bool _isStreamActive = false;

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

      // Get available cameras
      _availableCameras = await availableCameras();

      if (_availableCameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No se encontró ninguna cámara';
        });
        return;
      }

      // Use current camera index (back camera by default)
      final camera = _availableCameras[_currentCameraIndex];

      // Get configured resolution preset
      final settingsService = ref.read(appSettingsServiceProvider);
      final resolutionPreset = await settingsService.getResolutionPreset();

      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        resolutionPreset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isInitializing = false);
        // Start live recognition after camera is ready
        _startLiveRecognition();
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Error al inicializar cámara: $e';
      });
    }
  }

  void _startLiveRecognition() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isStreamActive) {
      return;
    }

    try {
      _isStreamActive = true;

      await _cameraController!.startImageStream((CameraImage cameraImage) async {
        // Throttle: process every 500ms for better responsiveness
        // GPU acceleration makes this faster without impacting battery significantly
        final now = DateTime.now();
        if (_lastProcessTime != null &&
            now.difference(_lastProcessTime!).inMilliseconds < 500) {
          return;
        }

        // Skip if already processing or capturing
        if (_isProcessingFrame || _isCapturing) {
          return;
        }

        _isProcessingFrame = true;
        _lastProcessTime = now;

        try {
          // Convert YUV420 to RGB Image
          final img.Image? convertedImage = await compute(
            _convertYUV420ToImage,
            cameraImage,
          );

          if (convertedImage != null && mounted) {
            // Resize to 640x480 for better face detection accuracy
            // Higher resolution helps detect smaller/distant faces
            final img.Image resizedImage = img.copyResize(
              convertedImage,
              width: 640,
              height: 480,
              interpolation: img.Interpolation.linear, // Better quality for improved detection
            );

            // Save temporarily as JPEG
            final tempDir = await getTemporaryDirectory();
            final tempPath =
                '${tempDir.path}/frame_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File(tempPath);

            // Encode with good quality for better face detection
            final jpegBytes = img.encodeJpg(resizedImage, quality: 90);
            await file.writeAsBytes(jpegBytes);

            // Perform recognition
            await _performLiveFaceRecognition(tempPath);

            // Clean up temporary file
            try {
              await file.delete();
            } catch (_) {
              // Ignore deletion errors
            }
          }
        } catch (e) {
          debugPrint('Live recognition error: $e');
        } finally {
          _isProcessingFrame = false;
        }
      });
    } catch (e) {
      debugPrint('Failed to start image stream: $e');
      _isStreamActive = false;
    }
  }

  void _stopLiveRecognition() {
    if (_cameraController != null && _isStreamActive) {
      try {
        _cameraController!.stopImageStream();
        _isStreamActive = false;
      } catch (e) {
        debugPrint('Failed to stop image stream: $e');
      }
    }
  }

  /// Convert YUV420 CameraImage to RGB Image
  /// This runs in a separate isolate via compute() for better performance
  static img.Image? _convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

    final img.Image image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final int yValue = cameraImage.planes[0].bytes[index];
        final int uValue = cameraImage.planes[1].bytes[uvIndex];
        final int vValue = cameraImage.planes[2].bytes[uvIndex];

        // YUV to RGB conversion
        final int r = (yValue + vValue * 1436 / 1024 - 179)
            .round()
            .clamp(0, 255)
            .toInt();
        final int g = (yValue -
                    uValue * 46549 / 131072 +
                    44 -
                    vValue * 93604 / 131072 +
                    91)
            .round()
            .clamp(0, 255)
            .toInt();
        final int b =
            (yValue + uValue * 1814 / 1024 - 227).round().clamp(0, 255).toInt();

        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return image;
  }

  Future<void> _performLiveFaceRecognition(String imagePath) async {
    try {
      // Get face recognition service
      final faceRecognitionService = ref.read(faceRecognitionServiceProvider);

      // Get active course to filter students
      final getActiveCourseUseCase = ref.read(getActiveCourseUseCaseProvider);
      final activeCourse = await getActiveCourseUseCase();

      if (activeCourse == null) {
        // No active course, clear recognition
        if (mounted) {
          setState(() {
            _liveRecognitionName = null;
            _liveRecognizedStudentId = null;
          });
        }
        return;
      }

      // Get students with face data from active course
      final studentRepository = ref.read(studentRepositoryProvider);
      final allStudents = await studentRepository.getAllStudents();
      final studentsWithFaces = allStudents
          .where((s) => s.courseId == activeCourse.id && s.hasFaceData)
          .toList();

      if (studentsWithFaces.isEmpty) {
        // No students with face data, clear recognition
        if (mounted) {
          setState(() {
            _liveRecognitionName = null;
            _liveRecognizedStudentId = null;
          });
        }
        return;
      }

      // Recognize student in frame
      final result = await faceRecognitionService.recognizeStudent(
        File(imagePath),
        studentsWithFaces,
      );

      // Update live recognition state
      if (mounted) {
        setState(() {
          if (result != null && result.student != null) {
            _liveRecognitionName = result.student!.name;
            _liveRecognizedStudentId = result.student!.id;
          } else {
            _liveRecognitionName = null;
            _liveRecognizedStudentId = null;
          }
        });
      }
    } catch (e) {
      // Recognition failed, clear state
      if (mounted) {
        setState(() {
          _liveRecognitionName = null;
          _liveRecognizedStudentId = null;
        });
      }
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      // Take picture
      final image = await _cameraController!.takePicture();

      // Use live recognition result instead of processing again
      // This makes capture instant since recognition already happened
      setState(() {
        _recognizedStudentName = _liveRecognitionName;
        _recognizedStudentId = _liveRecognizedStudentId;
        _previewImagePath = image.path;
      });

      // Auto-save after 2 seconds unless cancelled
      await Future.delayed(const Duration(milliseconds: 2000));

      // If preview still showing (not cancelled), save
      if (mounted && _previewImagePath != null) {
        await _saveEvidence(image.path, studentId: _recognizedStudentId);
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
        setState(() {
          _isCapturing = false;
          _previewImagePath = null;
          _recognizedStudentName = null;
          _recognizedStudentId = null;
        });
      }
    }
  }

  Future<void> _performFaceRecognition(String imagePath) async {
    try {
      // Get face recognition service
      final faceRecognitionService = ref.read(faceRecognitionServiceProvider);

      // Get active course to filter students
      final getActiveCourseUseCase = ref.read(getActiveCourseUseCaseProvider);
      final activeCourse = await getActiveCourseUseCase();

      if (activeCourse == null) {
        // No active course, skip recognition
        return;
      }

      // Get students with face data from active course
      final studentRepository = ref.read(studentRepositoryProvider);
      final allStudents = await studentRepository.getAllStudents();
      final studentsWithFaces = allStudents
          .where((s) => s.courseId == activeCourse.id && s.hasFaceData)
          .toList();

      if (studentsWithFaces.isEmpty) {
        // No students with face data
        return;
      }

      // Recognize student in image
      final result = await faceRecognitionService.recognizeStudent(
        File(imagePath),
        studentsWithFaces,
      );

      if (result != null && result.student != null) {
        setState(() {
          _recognizedStudentName = result.student!.name;
          _recognizedStudentId = result.student!.id;
        });
      }
    } catch (e) {
      // Recognition failed, but don't block capture
      // Just log and continue without recognition
      debugPrint('Face recognition error: $e');
    }
  }

  Future<void> _saveEvidence(String imagePath, {int? studentId}) async {
    try {
      final saveUseCase = ref.read(saveEvidenceUseCaseProvider);

      await saveUseCase(
        tempImagePath: imagePath,
        subjectId: widget.subjectId,
        studentId: studentId,
      );

      // Invalidate home providers to refresh counts immediately
      ref.invalidate(pendingEvidencesCountProvider);
      ref.invalidate(storageInfoProvider);

      if (mounted) {
        setState(() => _capturedCount++);

        // Visual feedback with recognition info
        final message = studentId != null && _recognizedStudentName != null
            ? '✓ Evidencia guardada - $_recognizedStudentName'
            : '✓ Evidencia ${_capturedCount} guardada';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelPreview() {
    if (_previewImagePath != null) {
      // Delete the temporary file
      try {
        File(_previewImagePath!).deleteSync();
      } catch (e) {
        // Ignore deletion errors
      }

      setState(() {
        _previewImagePath = null;
        _isCapturing = false;
        _recognizedStudentName = null;
        _recognizedStudentId = null;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2 || _isCapturing) {
      return; // No multiple cameras or currently capturing
    }

    // Stop live recognition while switching
    _stopLiveRecognition();

    // Switch to next camera (cycle through available cameras)
    _currentCameraIndex = (_currentCameraIndex + 1) % _availableCameras.length;

    // Dispose current controller
    await _cameraController?.dispose();

    // Reinitialize with new camera (will restart live recognition)
    await _initializeCamera();
  }

  @override
  void dispose() {
    _stopLiveRecognition();
    _cameraController?.dispose();

    // Invalidate providers when leaving to refresh home counters
    ref.invalidate(pendingEvidencesCountProvider);
    ref.invalidate(storageInfoProvider);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show preview if capturing
    if (_previewImagePath != null) {
      return _buildPreview(theme);
    }

    return Scaffold(
      backgroundColor: Colors.black,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get camera preview size
        final previewSize = _cameraController!.value.previewSize!;

        // Calculate aspect ratios
        // Camera preview is typically in landscape (width > height)
        // We need to handle both portrait and landscape device orientations
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final screenAspectRatio = screenWidth / screenHeight;

        // Camera preview aspect ratio (swap if needed for portrait)
        var previewAspectRatio = previewSize.width / previewSize.height;

        // If screen is in portrait but preview is landscape, swap
        if (screenAspectRatio < 1.0) {
          previewAspectRatio = previewSize.height / previewSize.width;
        }

        return Stack(
          children: [
            // Camera preview
            Center(
              child: AspectRatio(
                aspectRatio: previewAspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            ),
            // Border overlay for recognition status
            if (!_isCapturing)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _liveRecognitionName != null
                        ? Colors.green
                        : Colors.orange.withValues(alpha: 0.5),
                    width: 6,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOverlayUI(ThemeData theme) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar with subject name and back button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.subject.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_capturedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$_capturedCount guardadas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Camera switch button (only show if multiple cameras available)
                if (_availableCameras.length > 1)
                  IconButton(
                    icon: const Icon(Icons.flip_camera_android, color: Colors.white),
                    onPressed: _switchCamera,
                    tooltip: 'Cambiar cámara',
                  ),
              ],
            ),
          ),

          // Live recognition overlay
          if (_liveRecognitionName != null && !_isCapturing)
            Container(
              margin: const EdgeInsets.only(top: 80),
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.face,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _liveRecognitionName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

          const Spacer(),

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Capture button
                GestureDetector(
                  onTap: _isCapturing ? null : _captureImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isCapturing
                          ? Colors.grey
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                    child: _isCapturing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isCapturing ? 'Capturando...' : 'CAPTURAR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final isRecognized = _recognizedStudentName != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image preview with colored border
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isRecognized ? Colors.green : Colors.orange,
                  width: 4,
                ),
              ),
              child: Image.file(
                File(_previewImagePath!),
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Recognition result banner
          if (isRecognized)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 80),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.face,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _recognizedStudentName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Cancel button overlay
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  onPressed: _cancelPreview,
                  icon: const Icon(Icons.close),
                  label: const Text('CANCELAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Auto-save message
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  isRecognized
                      ? 'Guardando y asignando a $_recognizedStudentName...'
                      : 'Guardando automáticamente...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
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
