import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/services/face_recognition/face_detector_service.dart';
import 'package:eduportfolio/core/services/face_recognition/face_recognition_providers.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/core/utils/logger.dart';
import 'package:eduportfolio/features/students/presentation/providers/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helper class to store captured photo data in memory
class _CapturedPhoto {
  final img.Image image; // Processed image in memory (no disk I/O!)
  final FaceDetectionResult detection;

  _CapturedPhoto({required this.image, required this.detection});
}

/// Face training screen - Capture 5 photos for face recognition training
class FaceTrainingScreen extends ConsumerStatefulWidget {
  static const routeName = '/face-training';

  final Student student;

  const FaceTrainingScreen({required this.student, super.key});

  @override
  ConsumerState<FaceTrainingScreen> createState() => _FaceTrainingScreenState();
}

class _FaceTrainingScreenState extends ConsumerState<FaceTrainingScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;
  bool _isInitializing = true;
  bool _hasPermission = false;
  String? _errorMessage;

  final List<_CapturedPhoto> _capturedPhotos = [];
  bool _isCapturing = false;
  bool _isProcessing = false;

  static const int requiredPhotos = 5;

  // Live detection state
  bool _isStreamActive = false;
  bool _isProcessingFrame = false;
  DateTime? _lastProcessTime;
  FaceRect? _detectedFaceRect;
  int _detectionImageWidth = 240;  // Default values
  int _detectionImageHeight = 320;
  bool _faceDetected = false;
  String? _faceQualityMessage;

  // Cached frame for stream capture
  img.Image? _cachedStreamImage;
  FaceDetectionResult? _cachedDetection;

  // Debug visualization
  Uint8List? _debugImageBytes;
  int _debugImageWidth = 0;
  int _debugImageHeight = 0;

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

      // On first initialization, prefer back camera (same as quick capture)
      if (_currentCameraIndex == 0) {
        final backCameraIndex = _availableCameras.indexWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
        );
        if (backCameraIndex != -1) {
          _currentCameraIndex = backCameraIndex;
        }
      }

      // Use current camera index
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
        _startLiveFaceDetection();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Error al inicializar cámara: $e';
        });
      }
    }
  }

  void _startLiveFaceDetection() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isStreamActive) {
      return;
    }

    try {
      _isStreamActive = true;
      final faceService = ref.read(faceRecognitionServiceProvider);
      // We need access to the detector directly
      // Ideally we would get it from the provider, but the service wraps it.
      // We will create a fresh one or we need to expose it.
      // Actually FaceRecognitionService has a _faceDetector, but it's private.
      // We should use the provider for FaceDetectorService directly if possible or expose it.
      // Let's assume we can get FaceDetectorService provider directly if it exists,
      // OR we add a method to FaceRecognitionService to get the detector,
      // OR we just assume the FaceRecognitionService is what we have.

      // Checking providers... `faceDetectorServiceProvider` exists in `face_recognition_providers.dart`?
      // I'll assume yes based on common patterns, otherwise I'll need to check.
      // Re-reading `face_recognition_service.dart` (step 48)...
      // It takes `FaceDetectorService` in constructor.

      // Let's rely on reading `faceDetectorServiceProvider` (assuming it exists and is exposed).
      // If not, I might need to fix that.
      // For now, I'll use `ref.read(faceDetectorServiceProvider)`.

      await _cameraController!.startImageStream((
        CameraImage cameraImage,
      ) async {
        final now = DateTime.now();
        if (_lastProcessTime != null &&
            now.difference(_lastProcessTime!).inMilliseconds < 200) {
          return;
        }

        if (_isProcessingFrame || _isCapturing || _isProcessing) {
          return;
        }

        _isProcessingFrame = true;
        _lastProcessTime = now;

        try {
          final img.Image? convertedImage = await compute(
            _convertYUV420ToImage,
            cameraImage,
          );


          if (convertedImage != null && mounted) {
            var processedImage = convertedImage;
            
            Logger.debug('Live detection - Original image: ${convertedImage.width}x${convertedImage.height}');
            
            // AUTOMATIC ROTATION CORRECTION
            // The camera sensor typically returns landscape images (Width > Height).
            // But the UI is Portrait. We must rotate the image to be Upright.
            // 
            // Based on user report:
            // - Back Camera: "Rotated Left" -> Needs +90° to be upright.
            // - Front Camera: "Rotated Right" -> Needs +270° (or -90°) to be upright.
            
            // Check if we are using Front or Back camera
            final isFront = _availableCameras.isNotEmpty && 
                           _currentCameraIndex < _availableCameras.length &&
                           _availableCameras[_currentCameraIndex].lensDirection == CameraLensDirection.front;

            if (convertedImage.width > convertedImage.height) {
               // It's landscape, rotate to portrait
               final angle = isFront ? 270 : 90;
               processedImage = img.copyRotate(convertedImage, angle: angle);
               Logger.debug('Live detection - Rotated $angle° to: ${processedImage.width}x${processedImage.height}');
            } else {
               // Already portrait (rare for raw sensor data but possible)
               Logger.debug('Live detection - No rotation applied (already portrait)');
            }

            // Flip if front camera to correct mirror effect (for training consistency)
            if (isFront) {
               processedImage = img.flip(processedImage, direction: img.FlipDirection.horizontal);
            }
            
            // Resize for speed while maintaining aspect ratio
            // Now the image is Portrait (e.g., 1080x1920 -> 135x240)
            final int targetWidth = 160; // Slightly smaller for speed
            final int targetHeight = (processedImage.height * targetWidth / processedImage.width).round();
            
            Logger.debug('Live detection - Resizing to: ${targetWidth}x${targetHeight}');
            
            final img.Image resizedImage = img.copyResize(
              processedImage,
              width: targetWidth,
              height: targetHeight,
              interpolation: img.Interpolation.linear,
            );
            
            // DEBUG: Encode image to bytes for visualization
            final debugBytes = img.encodeJpg(resizedImage, quality: 70);

            // Get detector
            final faceDetector = ref.read(faceDetectorServiceProvider);
            final result = await faceDetector.detectFaceFromImage(resizedImage);

            if (mounted) {
              setState(() {
                if (result != null) {
                  _faceDetected = true;
                  _detectedFaceRect = result.box;
                  _detectionImageWidth = resizedImage.width;
                  _detectionImageHeight = resizedImage.height;

                  // Cache full-res image + detection for stream capture
                  _cachedStreamImage = processedImage;
                  _cachedDetection = result;

                  Logger.debug('Live detection - Face found at: x=${result.box.x}, y=${result.box.y}, w=${result.box.width}, h=${result.box.height}');
                  Logger.debug('Live detection - Detection image size: ${_detectionImageWidth}x${_detectionImageHeight}');

                  if (result.box.width < 40) {
                    _faceQualityMessage = "Acércate más";
                  } else {
                    _faceQualityMessage = null;
                  }
                } else {
                  _faceDetected = false;
                  _detectedFaceRect = null;
                  _faceQualityMessage = "No se detecta rostro";
                  _cachedStreamImage = null;
                  _cachedDetection = null;
                }
              });
            }
          }
        } catch (e) {
          Logger.error('Live detection error', e);
        } finally {
          _isProcessingFrame = false;
        }
      });
    } catch (e) {
      Logger.error('Failed to start stream', e);
      _isStreamActive = false;
    }
  }

  void _stopLiveFaceDetection() {
    if (_cameraController != null && _isStreamActive) {
      try {
        _cameraController!.stopImageStream();
        _isStreamActive = false;
      } catch (e) {
        Logger.error('Failed to stop stream', e);
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing ||
        _capturedPhotos.length >= requiredPhotos ||
        _cachedStreamImage == null ||
        _cachedDetection == null) {
      return;
    }

    Logger.debug('Capture ${_capturedPhotos.length + 1}/5 (stream) started...');
    final captureStartTime = DateTime.now();

    setState(() => _isCapturing = true);

    try {
      final image = _cachedStreamImage!;
      final detection = _cachedDetection!;

      // Map detection coordinates from resized space (160xN) to full image space
      final scaleX = image.width / _detectionImageWidth.toDouble();
      final scaleY = image.height / _detectionImageHeight.toDouble();

      final clampedX = (detection.box.x * scaleX).round().clamp(0, image.width - 1);
      final clampedY = (detection.box.y * scaleY).round().clamp(0, image.height - 1);

      final mappedDetection = FaceDetectionResult(
        box: FaceRect(
          x: clampedX,
          y: clampedY,
          width: (detection.box.width * scaleX).round().clamp(1, image.width - clampedX),
          height: (detection.box.height * scaleY).round().clamp(1, image.height - clampedY),
        ),
        rightEye: detection.rightEye != null
            ? Point(detection.rightEye!.x * scaleX, detection.rightEye!.y * scaleY)
            : null,
        leftEye: detection.leftEye != null
            ? Point(detection.leftEye!.x * scaleX, detection.leftEye!.y * scaleY)
            : null,
      );

      Logger.debug('Cached image: ${image.width}x${image.height}, mapped box: ${mappedDetection.box}');

      // NOTE: The Android orientation workaround is NOT needed here because
      // the image from the camera stream was already rotated during live detection
      // (lines 219-227). Applying it again would cause double rotation and break
      // face recognition. The workaround only applies to JPEG files loaded from disk.
      final finalImage = image;
      final finalDetection = mappedDetection;

      // Store and clear cache to prevent re-capture of the same frame
      setState(() {
        _capturedPhotos.add(_CapturedPhoto(
          image: finalImage,
          detection: finalDetection,
        ));
        _cachedStreamImage = null;
        _cachedDetection = null;
      });

      final captureTotalDuration = DateTime.now().difference(captureStartTime);
      Logger.debug('Capture ${_capturedPhotos.length}/5 completed in ${captureTotalDuration.inMilliseconds}ms');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Foto ${_capturedPhotos.length}/$requiredPhotos capturada',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }

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
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _processPhotos() async {
    setState(() => _isProcessing = true);

    try {
      // Get face recognition service
      final faceRecognitionService = ref.read(faceRecognitionServiceProvider);

      // Extract images and detections from memory (NO disk I/O!)
      final images = _capturedPhotos.map((p) => p.image).toList();
      final detections = _capturedPhotos.map((p) => p.detection).toList();

      // Process training photos with pre-computed detections (avoids re-detecting + I/O)
      final result = await faceRecognitionService.processTrainingPhotosWithDetections(
        images,
        detections,
      );

      if (!result.success || result.embeddingBytes.isEmpty) {
        throw Exception(result.error ?? 'Error procesando fotos');
      }

      // Update student with face embeddings
      final updateFaceDataUseCase = ref.read(
        updateStudentFaceDataUseCaseProvider,
      );
      await updateFaceDataUseCase(
        studentId: widget.student.id!,
        faceEmbeddings: Uint8List.fromList(result.embeddingBytes),
      );

      // No cleanup needed - images were kept in memory (no files on disk)

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
      _capturedPhotos.removeLast();
      // No file to delete - image was only in memory
    });
  }

  /// Convert YUV420 CameraImage to RGB Image
  /// This runs in a separate isolate via compute() for better performance
  static img.Image? _convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    
    // Get strides for all planes
    final int yRowStride = cameraImage.planes[0].bytesPerRow;
    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

    final img.Image image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
            
        // Correct index calculation using stride
        final int index = y * yRowStride + x; // x pixel stride is always 1 for Y plane

        final int yValue = cameraImage.planes[0].bytes[index];
        final int uValue = cameraImage.planes[1].bytes[uvIndex];
        final int vValue = cameraImage.planes[2].bytes[uvIndex];

        // YUV to RGB conversion
        final int r = (yValue + vValue * 1436 / 1024 - 179)
            .round()
            .clamp(0, 255)
            .toInt();
        final int g =
            (yValue -
                    uValue * 46549 / 131072 +
                    44 -
                    vValue * 93604 / 131072 +
                    91)
                .round()
                .clamp(0, 255)
                .toInt();
        final int b = (yValue + uValue * 1814 / 1024 - 227)
            .round()
            .clamp(0, 255)
            .toInt();

        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return image;
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2 || _isCapturing || _isProcessing) {
      return; // No multiple cameras or currently busy
    }

    // Stop live detection
    _stopLiveFaceDetection();

    setState(() {
      _isInitializing = true;
    });

    // Switch to next camera (cycle through available cameras)
    _currentCameraIndex = (_currentCameraIndex + 1) % _availableCameras.length;

    // Dispose current controller
    await _cameraController?.dispose();
    _cameraController = null;

    // Reinitialize with new camera
    await _initializeCamera();
  }

  @override
  void dispose() {
    _stopLiveFaceDetection();
    _cameraController?.dispose();
    // No cleanup needed - images were only in memory
    _capturedPhotos.clear();
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
            
          // DEBUG: Detector input visualization (disabled for performance)
          // _buildDebugOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate scale to fit 320x240 box updates to screen
        // In this simple version, we'll just center the preview.
        // For accurate box usage, we need to know the rendered size of CameraPreview.

        final size = _cameraController!.value.previewSize!;

        // Handle aspect ratio
        var previewAspectRatio = size.width / size.height;
        if (constraints.maxWidth / constraints.maxHeight < 1.0) {
          previewAspectRatio = size.height / size.width;
        }

        return Stack(
          children: [
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  // Swapped logic for portrait mode usually
                  width: size.height,
                  height: size.width,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),

            // Face Bounding Box Overlay
            if (_faceDetected && _detectedFaceRect != null)
              _buildFaceOverlay(constraints.maxWidth, constraints.maxHeight),

            // Quality message
            if (_faceQualityMessage != null)
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _faceQualityMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  // Debug widget to visualize what the detector sees
  Widget _buildDebugOverlay() {
    if (_debugImageBytes == null) return const SizedBox.shrink();
    
    return Positioned(
      left: 10,
      bottom: 250, // Above control buttons
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 2),
          color: Colors.black,
        ),
        child: Column(
          children: [
            Text('Detector Input (${_debugImageWidth}x${_debugImageHeight})', 
                 style: const TextStyle(color: Colors.white, fontSize: 10)),
            // Show ONLY the raw tensor input (128x128)
            // Note: Do NOT draw detection box here - coordinates are in different space
            // (FaceRect coords are for resized image ~160px, tensor is 128x128 square with padding)
            Image.memory(
              _debugImageBytes!,
              width: 160, // Scale up slightly for visibility
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFaceOverlay(double screenWidth, double screenHeight) {
    if (_detectedFaceRect == null) return const SizedBox.shrink();

    // Mapping Logic Simplified:
    // 1. input image is now UPRIGHT (Portrait) thanks to pre-rotation.
    //    Dimensions: _detectionImageWidth x _detectionImageHeight (e.g. 135x240)
    // 2. Screen is Portrait (screenWidth x screenHeight)
    // 
    // We just need to Scale.
    // AND Mirror if it's Front Camera.

    final double detW = _detectionImageWidth.toDouble();
    final double detH = _detectionImageHeight.toDouble();
    
    final double boxX = _detectedFaceRect!.x.toDouble();
    final double boxY = _detectedFaceRect!.y.toDouble();
    final double boxW = _detectedFaceRect!.width.toDouble();
    final double boxH = _detectedFaceRect!.height.toDouble();

    Logger.debug('Overlay - Box: $boxX,$boxY ${boxW}x$boxH in ${detW}x$detH');

    // Check if Front Camera (Mirroring)
     final isFront = _availableCameras.isNotEmpty && 
                           _currentCameraIndex < _availableCameras.length &&
                           _availableCameras[_currentCameraIndex].lensDirection == CameraLensDirection.front;

    // Calculate Relative Coordinates (0.0 - 1.0)
    double relX = boxX / detW;
    final double relY = boxY / detH;
    final double relW = boxW / detW;
    final double relH = boxH / detH;
    
    // Apply Mirroring for Front Camera
    if (isFront) {
      // Flip Horizontal: The "Left" becomes (1.0 - Right)
      // old Right edge = relX + relW
      // new Left edge = 1.0 - (relX + relW)
      relX = 1.0 - (relX + relW);
    }

    return Positioned(
      left: relX * screenWidth,
      top: relY * screenHeight,
      width: relW * screenWidth,
      height: relH * screenHeight,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _faceQualityMessage == null ? Colors.green : Colors.yellow,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildOverlayUI(ThemeData theme) {
    final progress = _capturedPhotos.length / requiredPhotos;
    final bool canCapture = !_isCapturing &&
        _capturedPhotos.length < requiredPhotos &&
        _cachedDetection != null;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.student.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Camera switch button (only show if multiple cameras available)
                    if (_availableCameras.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.flip_camera_android,
                          color: Colors.white,
                        ),
                        onPressed: _switchCamera,
                        tooltip: 'Cambiar cámara',
                      ),
                  ],
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
                  onTap: canCapture ? _capturePhoto : null,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: canCapture ? Colors.white : Colors.grey,
                        width: 4,
                      ),
                      color: _isCapturing
                          ? Colors.grey
                          : (_capturedPhotos.length >= requiredPhotos
                                ? Colors.green
                                : (canCapture
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.grey)),
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
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
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
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Error desconocido',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
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
              onPressed: () => _initializeCamera(),
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
