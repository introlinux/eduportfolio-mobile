import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/core/services/face_recognition/face_recognition_providers.dart';
import 'package:eduportfolio/features/capture/presentation/providers/capture_providers.dart';
import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

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

  // Modo encuadre intencionado (long-press)
  bool _isLongPressActive = false;
  String? _frozenStudentName;
  int? _frozenStudentId;

  // Selección manual de estudiante
  bool _isManualSelectionActive = false;

  // Debug: cropped face image for visualization
  img.Image? _debugCroppedFace;
  Uint8List? _debugCroppedFaceBytes;
  
  // Orientation state
  Orientation _currentOrientation = Orientation.portrait;

  // Video recording state
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String? _recordingStudentName;
  int? _recordingStudentId;

  // Audio recording state
  bool _isAudioRecording = false;
  Duration _audioRecordingDuration = Duration.zero;
  Timer? _audioRecordingTimer;
  String? _audioRecordingStudentName;
  int? _audioRecordingStudentId;
  String? _audioCoverImagePath;
  AudioRecorder? _audioRecorder;
  List<double> _audioWaveform = [];
  StreamSubscription<Amplitude>? _amplitudeSubscription;

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
      // enableAudio: true needed for video recording with sound
      _cameraController = CameraController(
        camera,
        resolutionPreset,
        enableAudio: true,
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
        if (_isProcessingFrame || _isCapturing || _isLongPressActive || _isManualSelectionActive || _isAudioRecording) {
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
            var processedImage = convertedImage;
            
            // AUTOMATIC ROTATION CORRECTION (same as face_training_screen)
            // The camera sensor typically returns landscape images (Width > Height).
            // But the UI is Portrait. We must rotate the image to be Upright.
            // This MUST match the rotation applied during training for embeddings to match.
            
            // Check if we are using Front or Back camera
            final isFront = _availableCameras.isNotEmpty && 
                           _currentCameraIndex < _availableCameras.length &&
                           _availableCameras[_currentCameraIndex].lensDirection == CameraLensDirection.front;

            if (convertedImage.width > convertedImage.height) {
               // Sensor image is typically Landscape
               
               if (_currentOrientation == Orientation.landscape) {
                 // Device is in Landscape -> Sensor Image is Upright (usually)
                 // No rotation needed for standard landscape
                 // If reverse landscape (180), might need 180 rotation, but
                 // native_device_orientation is needed for that. 
                 // For now, assume simplified landscape support (angle 0).
                 processedImage = convertedImage;
                 // Note: If resizing below, aspect ratio will be preserved.
               } else {
                 // Device is in Portrait -> Sensor Image is rotated 90 deg
                 // Rotate to make it Upright
                 final angle = isFront ? 270 : 90;
                 processedImage = img.copyRotate(convertedImage, angle: angle);
               }
            }
            
            // Resize for speed while maintaining aspect ratio
            // Target width 480px (sufficient for face detection)
            final int targetWidth = 480;
            final int targetHeight = (processedImage.height * targetWidth / processedImage.width).round();

            final img.Image resizedImage = img.copyResize(
              processedImage,
              width: targetWidth,
              height: targetHeight,
              interpolation: img.Interpolation.linear,
            );

            // Flip if front camera to correct mirror effect (for recognition consistency)
            if (isFront) {
              img.flip(resizedImage, direction: img.FlipDirection.horizontal);
            }

            // Perform recognition directly from image (no JPEG I/O!)
            await _performLiveFaceRecognition(resizedImage);
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

  Future<void> _performLiveFaceRecognition(img.Image image) async {
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

      // Recognize student from image (NO file I/O, NO orientation workaround)
      final result = await faceRecognitionService.recognizeStudentFromImage(
        image,
        studentsWithFaces,
      );
      
      // Update live recognition state
      // Debug overlay disabled for performance
      /*
      if (mounted) {
        // Convert debug image to bytes for display if available
        if (result != null && result.debugCroppedFace != null) {
          try {
            final pngBytes = img.encodePng(result.debugCroppedFace!);
            _debugCroppedFaceBytes = Uint8List.fromList(pngBytes);
          } catch (e) {
            debugPrint('Error encoding debug face: $e');
          }
        }
      }
      */

        if (mounted && !_isManualSelectionActive) {
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
      if (mounted && !_isManualSelectionActive) {
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
      final activeCourse = await ref.read(activeCourseProvider.future);

      await saveUseCase(
        tempImagePath: imagePath,
        subjectId: widget.subjectId,
        studentId: studentId,
        courseId: activeCourse?.id,
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

  // =========================================================================
  // VIDEO RECORDING
  // =========================================================================

  Future<void> _startVideoRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing ||
        _isRecording) {
      return;
    }

    // Stop live recognition during recording (student already identified)
    _stopLiveRecognition();

    try {
      await _cameraController!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        // Freeze the student identity for the recording
        _recordingStudentName = _isManualSelectionActive
            ? _liveRecognitionName
            : (_liveRecognitionName ?? _frozenStudentName);
        _recordingStudentId = _isManualSelectionActive
            ? _liveRecognizedStudentId
            : (_liveRecognizedStudentId ?? _frozenStudentId);
      });

      // Start duration timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar grabación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController == null || !_isRecording) return;

    // Stop timer
    _recordingTimer?.cancel();
    _recordingTimer = null;

    try {
      final videoFile = await _cameraController!.stopVideoRecording();

      final durationMs = _recordingDuration.inMilliseconds;
      final studentId = _recordingStudentId;
      final studentName = _recordingStudentName;

      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });

      // Save the video evidence
      await _saveVideoEvidence(
        videoFile.path,
        durationMs: durationMs,
        studentId: studentId,
        studentName: studentName,
      );

      // Restart live recognition
      _startLiveRecognition();
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });

      // Restart live recognition even on error
      _startLiveRecognition();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al detener grabación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveVideoEvidence(
    String videoPath, {
    required int durationMs,
    int? studentId,
    String? studentName,
  }) async {
    try {
      final saveVideoUseCase = ref.read(saveVideoEvidenceUseCaseProvider);
      final activeCourse = await ref.read(activeCourseProvider.future);

      await saveVideoUseCase(
        tempVideoPath: videoPath,
        subjectId: widget.subjectId,
        durationMs: durationMs,
        studentId: studentId,
        courseId: activeCourse?.id,
      );

      // Invalidate home providers to refresh counts immediately
      ref.invalidate(pendingEvidencesCountProvider);
      ref.invalidate(storageInfoProvider);

      if (mounted) {
        setState(() => _capturedCount++);

        final message = studentId != null && studentName != null
            ? '🎥 Vídeo guardado - $studentName'
            : '🎥 Vídeo guardado';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 2000),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar vídeo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =========================================================================
  // AUDIO RECORDING
  // =========================================================================

  Future<void> _startAudioRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing ||
        _isRecording ||
        _isAudioRecording) {
      return;
    }

    // Request microphone permission
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso de micrófono denegado'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Stop live recognition (student already identified)
    _stopLiveRecognition();

    try {
      // Capture cover photo silently
      final coverImage = await _cameraController!.takePicture();
      _audioCoverImagePath = coverImage.path;

      // Initialize audio recorder
      _audioRecorder = AudioRecorder();

      // Configure recording: OPUS at 160kbps, 48kHz
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.opus';

      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.opus,
          bitRate: 160000,
          sampleRate: 48000,
          numChannels: 1,
        ),
        path: tempPath,
      );

      setState(() {
        _isAudioRecording = true;
        _audioRecordingDuration = Duration.zero;
        _audioWaveform = [];
        // Freeze student identity
        _audioRecordingStudentName = _isManualSelectionActive
            ? _liveRecognitionName
            : (_liveRecognitionName ?? _frozenStudentName);
        _audioRecordingStudentId = _isManualSelectionActive
            ? _liveRecognizedStudentId
            : (_liveRecognizedStudentId ?? _frozenStudentId);
      });

      // Start duration timer
      _audioRecordingTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _audioRecordingDuration += const Duration(seconds: 1);
          });
        }
      });

      // Start amplitude stream for waveform
      _amplitudeSubscription = _audioRecorder!
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amplitude) {
        if (mounted) {
          setState(() {
            // Normalize amplitude from dBFS (-160..0) to 0.0..1.0
            final normalized =
                ((amplitude.current + 60) / 60).clamp(0.0, 1.0);
            _audioWaveform.add(normalized);
            // Keep max 300 samples (30 seconds at 100ms)
            if (_audioWaveform.length > 300) {
              _audioWaveform.removeAt(0);
            }
          });
        }
      });
    } catch (e) {
      // Restart live recognition on error
      _startLiveRecognition();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar grabaci\u00f3n de audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopAudioRecording() async {
    if (_audioRecorder == null || !_isAudioRecording) return;

    // Stop timer and amplitude stream
    _audioRecordingTimer?.cancel();
    _audioRecordingTimer = null;
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    try {
      final audioPath = await _audioRecorder!.stop();
      await _audioRecorder!.dispose();
      _audioRecorder = null;

      final durationMs = _audioRecordingDuration.inMilliseconds;
      final studentId = _audioRecordingStudentId;
      final studentName = _audioRecordingStudentName;
      final coverPath = _audioCoverImagePath;

      setState(() {
        _isAudioRecording = false;
        _audioRecordingDuration = Duration.zero;
        _audioWaveform = [];
      });

      // Save the audio evidence
      if (audioPath != null && coverPath != null) {
        await _saveAudioEvidence(
          audioPath,
          coverImagePath: coverPath,
          durationMs: durationMs,
          studentId: studentId,
          studentName: studentName,
        );
      }

      // Restart live recognition
      _startLiveRecognition();
    } catch (e) {
      setState(() {
        _isAudioRecording = false;
        _audioRecordingDuration = Duration.zero;
        _audioWaveform = [];
      });

      // Restart live recognition even on error
      _startLiveRecognition();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al detener grabaci\u00f3n de audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAudioEvidence(
    String audioPath, {
    required String coverImagePath,
    required int durationMs,
    int? studentId,
    String? studentName,
  }) async {
    try {
      final saveAudioUseCase = ref.read(saveAudioEvidenceUseCaseProvider);
      final activeCourse = await ref.read(activeCourseProvider.future);

      await saveAudioUseCase(
        tempAudioPath: audioPath,
        coverImagePath: coverImagePath,
        subjectId: widget.subjectId,
        durationMs: durationMs,
        studentId: studentId,
        courseId: activeCourse?.id,
      );

      // Invalidate home providers to refresh counts immediately
      ref.invalidate(pendingEvidencesCountProvider);
      ref.invalidate(storageInfoProvider);

      if (mounted) {
        setState(() => _capturedCount++);

        final message = studentId != null && studentName != null
            ? '\ud83c\udfa4 Audio guardado - $studentName'
            : '\ud83c\udfa4 Audio guardado';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 2000),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Format a Duration as mm:ss
  String _formatRecordingDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
        _isLongPressActive = false;
        _frozenStudentName = null;
        _frozenStudentId = null;
        _recognizedStudentName = null;
        _recognizedStudentId = null;
      });
    }
  }

  void _onLongPressStart() {
    if (_isCapturing) return;
    setState(() {
      _isLongPressActive = true;
      _frozenStudentName = _liveRecognitionName;
      _frozenStudentId = _liveRecognizedStudentId;
    });
  }

  Future<void> _onLongPressEnd() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      setState(() {
        _isLongPressActive = false;
        _frozenStudentName = null;
        _frozenStudentId = null;
      });
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final image = await _cameraController!.takePicture();

      setState(() {
        _recognizedStudentName = _frozenStudentName;
        _recognizedStudentId = _frozenStudentId;
        _previewImagePath = image.path;
      });

      // Auto-save after 2 seconds unless cancelled
      await Future.delayed(const Duration(milliseconds: 2000));

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
          _isLongPressActive = false;
          _frozenStudentName = null;
          _frozenStudentId = null;
          _previewImagePath = null;
          _recognizedStudentName = null;
          _recognizedStudentId = null;
        });
      }
    }
  }

  Future<void> _openStudentSelector() async {
    final getActiveCourseUseCase = ref.read(getActiveCourseUseCaseProvider);
    final activeCourse = await getActiveCourseUseCase();

    if (!mounted) return;

    if (activeCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay curso activo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final studentRepository = ref.read(studentRepositoryProvider);
    final allStudents = await studentRepository.getAllStudents();
    final courseStudents = allStudents
        .where((s) => s.courseId == activeCourse.id)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (!mounted) return;

    if (courseStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay estudiantes en el curso activo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar estudiante'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: courseStudents.length,
            itemBuilder: (context, index) {
              final student = courseStudents[index];
              final isSelected = _isManualSelectionActive &&
                  _liveRecognizedStudentId == student.id;
              return ListTile(
                leading: Icon(
                  Icons.person,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                ),
                title: Text(student.name),
                trailing: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(context, student.id),
              );
            },
          ),
        ),
        actions: [
          if (_isManualSelectionActive)
            TextButton(
              onPressed: () => Navigator.pop(context, -1),
              child: const Text('Auto-reconocimiento'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == null) {
      // Cancelled — no change
    } else if (result == -1) {
      // Restore auto-recognition
      setState(() {
        _isManualSelectionActive = false;
        _liveRecognitionName = null;
        _liveRecognizedStudentId = null;
      });
    } else {
      // Student manually selected
      final selected = courseStudents.firstWhere((s) => s.id == result);
      setState(() {
        _isManualSelectionActive = true;
        _liveRecognitionName = selected.name;
        _liveRecognizedStudentId = selected.id;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2 || _isCapturing || _isLongPressActive) {
      return;
    }

    // Stop live recognition while switching
    _stopLiveRecognition();

    setState(() {
      _isInitializing = true;
    });

    // Switch to next camera (cycle through available cameras)
    _currentCameraIndex = (_currentCameraIndex + 1) % _availableCameras.length;

    // Dispose current controller
    await _cameraController?.dispose();
    _cameraController = null;

    // Reinitialize with new camera (will restart live recognition)
    await _initializeCamera();
  }

  @override
  void dispose() {
    _stopLiveRecognition();
    _recordingTimer?.cancel();
    _audioRecordingTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _audioRecorder?.dispose();
    _cameraController?.dispose();

    // Invalidate providers when leaving to refresh home counters
    ref.invalidate(pendingEvidencesCountProvider);
    ref.invalidate(storageInfoProvider);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update orientation on every build (rotation)
    _currentOrientation = MediaQuery.of(context).orientation;
  
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

          /*
          // DEBUG: Show what the recognizer sees
          if (_debugCroppedFaceBytes != null && !_isCapturing)
            Positioned(
              left: 20,
              bottom: 150,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  color: Colors.black,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Image.memory(
                        _debugCroppedFaceBytes!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                    Container(
                      color: Colors.red,
                      width: double.infinity,
                      padding: const EdgeInsets.all(2),
                      child: const Text(
                        'DEBUG INPUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          */
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
                    color: _isLongPressActive
                        ? Colors.blue
                        : (_liveRecognitionName != null
                            ? Colors.green
                            : Colors.orange.withValues(alpha: 0.5)),
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
                // Selección manual de estudiante
                IconButton(
                  icon: Icon(
                    Icons.person_add,
                    color: _isManualSelectionActive ? Colors.blue : Colors.white,
                  ),
                  onPressed: _isLongPressActive ? null : _openStudentSelector,
                  tooltip: 'Seleccionar estudiante',
                ),
                // Camera switch button (only show if multiple cameras available)
                if (_availableCameras.length > 1)
                  IconButton(
                    icon: const Icon(Icons.flip_camera_android, color: Colors.white),
                    onPressed: _isLongPressActive ? null : _switchCamera,
                    tooltip: 'Cambiar cámara',
                  ),
              ],
            ),
          ),

          // REC indicator (while recording video)
          if (_isRecording)
            Container(
              margin: const EdgeInsets.only(top: 60),
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Blinking red dot
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.3, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: value),
                          ),
                        );
                      },
                      // Use a key to force restart animation loop
                      key: ValueKey(_recordingDuration.inSeconds % 2 == 0),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'REC  ${_formatRecordingDuration(_recordingDuration)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Audio REC indicator (while recording audio)
          if (_isAudioRecording)
            Container(
              margin: const EdgeInsets.only(top: 60),
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Blinking blue dot
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.3, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: value),
                          ),
                        );
                      },
                      key: ValueKey(_audioRecordingDuration.inSeconds % 2 == 0),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.mic, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      _formatRecordingDuration(_audioRecordingDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Waveform overlay during audio recording
          if (_isAudioRecording && _audioCoverImagePath != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Cover photo as background
                    Positioned.fill(
                      child: Image.file(
                        File(_audioCoverImagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Dark overlay
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    // Waveform painter
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _WaveformPainter(
                          amplitudes: _audioWaveform,
                          color: Colors.blue.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Banner de estudiante: reconocimiento vivo, fijado (long-press), o durante grabación
          if (_isRecording && _recordingStudentName != null)
            Container(
              margin: const EdgeInsets.only(top: 110),
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
                      Icons.videocam,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _recordingStudentName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_isAudioRecording && _audioRecordingStudentName != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
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
                      Icons.mic,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _audioRecordingStudentName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (!_isCapturing && !_isRecording && !_isAudioRecording && (_isLongPressActive || _liveRecognitionName != null))
            Container(
              margin: const EdgeInsets.only(top: 80),
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _isLongPressActive
                      ? (_frozenStudentName != null ? Colors.blue : Colors.amber)
                      : Colors.green,
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
                    Icon(
                      _isLongPressActive
                          ? Icons.lock
                          : (_isManualSelectionActive ? Icons.person : Icons.face),
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isLongPressActive
                          ? (_frozenStudentName != null
                              ? 'Fijado: $_frozenStudentName'
                              : 'Sin estudiante reconocido')
                          : _liveRecognitionName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_isLongPressActive && !_isManualSelectionActive) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Audio capture button
                    GestureDetector(
                      onTap: (_isCapturing || _isRecording || _isLongPressActive)
                          ? null
                          : (_isAudioRecording ? _stopAudioRecording : _startAudioRecording),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isAudioRecording ? Colors.blue : Colors.white,
                            width: _isAudioRecording ? 6 : 3,
                          ),
                          color: _isAudioRecording
                              ? Colors.blue.withValues(alpha: 0.4)
                              : (_isCapturing || _isRecording || _isLongPressActive)
                                  ? Colors.grey.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.3),
                        ),
                        child: _isAudioRecording
                            ? const Icon(
                                Icons.stop,
                                size: 28,
                                color: Colors.white,
                              )
                            : Icon(
                                Icons.mic,
                                size: 28,
                                color: (_isCapturing || _isRecording || _isLongPressActive)
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.white,
                              ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Photo capture button (tap = captura rápida, long-press = encuadre intencionado)
                    GestureDetector(
                      onTap: (_isCapturing || _isRecording || _isAudioRecording) ? null : _captureImage,
                      onLongPressStart: (_isCapturing || _isRecording || _isAudioRecording) ? null : (details) => _onLongPressStart(),
                      onLongPressEnd: (details) => _onLongPressEnd(),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isLongPressActive ? Colors.blue : Colors.white,
                            width: _isLongPressActive ? 6 : 4,
                          ),
                          color: (_isCapturing || _isRecording || _isAudioRecording)
                              ? Colors.grey.withValues(alpha: 0.3)
                              : _isLongPressActive
                                  ? Colors.blue.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.3),
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                size: 36,
                                color: (_isRecording || _isAudioRecording)
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.white,
                              ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Video capture button
                    GestureDetector(
                      onTap: (_isCapturing || _isLongPressActive || _isAudioRecording)
                          ? null
                          : (_isRecording ? _stopVideoRecording : _startVideoRecording),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isRecording ? Colors.red : Colors.white,
                            width: _isRecording ? 6 : 3,
                          ),
                          color: _isRecording
                              ? Colors.red.withValues(alpha: 0.4)
                              : (_isCapturing || _isLongPressActive || _isAudioRecording)
                                  ? Colors.grey.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.3),
                        ),
                        child: _isRecording
                            ? const Icon(
                                Icons.stop,
                                size: 28,
                                color: Colors.white,
                              )
                            : Icon(
                                Icons.videocam,
                                size: 28,
                                color: (_isCapturing || _isLongPressActive || _isAudioRecording)
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
                if (_isLongPressActive) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'SOLTAR PARA CAPTURAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
                if (_isRecording) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'PULSAR STOP PARA FINALIZAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
                if (_isAudioRecording) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'GRABANDO AUDIO - PULSAR STOP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
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

/// Custom painter for audio waveform visualization
class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _WaveformPainter({
    required this.amplitudes,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Max visible bars
    const maxBars = 100;
    final visibleAmplitudes = amplitudes.length > maxBars
        ? amplitudes.sublist(amplitudes.length - maxBars)
        : amplitudes;

    final barWidth = size.width / maxBars;
    final gap = barWidth * 0.2;
    final effectiveBarWidth = barWidth - gap;

    for (int i = 0; i < visibleAmplitudes.length; i++) {
      final amplitude = visibleAmplitudes[i];
      final barHeight = math.max(2.0, amplitude * size.height * 0.9);

      final x = i * barWidth + gap / 2;
      final y = (size.height - barHeight) / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, effectiveBarWidth, barHeight),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes.length != amplitudes.length ||
        oldDelegate.amplitudes.lastOrNull != amplitudes.lastOrNull;
  }
}
