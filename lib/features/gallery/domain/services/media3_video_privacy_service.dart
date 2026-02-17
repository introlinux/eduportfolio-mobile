import 'dart:io';
import 'package:flutter/services.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:eduportfolio/core/services/face_recognition/face_detector_service.dart';

/// Service to handle privacy protection for videos using Media3 Transformer.
///
/// This service uses Android's Media3 library (via Platform Channel) to add
/// emoji overlays over detected faces in videos, providing a native, hardware-
/// accelerated solution that's faster and lighter than FFmpeg.
class Media3VideoPrivacyService {
  static const _channel = MethodChannel('com.eduportfolio/media3');
  final FaceDetectorService _faceDetectorService;

  Media3VideoPrivacyService(this._faceDetectorService);

  void _log(String message) {
    final now = DateTime.now();
    print('[Media3VideoPrivacy ${now.hour}:${now.minute}:${now.second}.${now.millisecond}] $message');
  }

  /// Process a video for sharing, optionally applying privacy protection (emoji overlays).
  ///
  /// Pipeline:
  ///   1. Extract frames from video at intervals
  ///   2. Detect faces in each frame using BlazeFace
  ///   3. Map face positions to normalized coordinates with timestamps
  ///   4. Call native Media3 code to apply emoji overlays
  ///   5. Return processed video file
  Future<File> processVideoForSharing(File input, bool privacyEnabled) async {
    if (!privacyEnabled) {
      return input;
    }

    // Android-only for now (Media3 is Android-specific)
    if (!Platform.isAndroid) {
      _log('Media3 only available on Android, returning original video');
      return input;
    }

    final stopwatch = Stopwatch()..start();
    _log('START processing ${input.path}');

    try {
      // Step 1: Extract video metadata (duration, dimensions)
      _log('Step 1: Extracting video metadata...');
      final videoInfo = await _getVideoInfo(input);
      if (videoInfo == null) {
        _log('Failed to get video info, returning original');
        return input;
      }
      _log('Video: ${videoInfo['width']}x${videoInfo['height']}, ${videoInfo['duration']}ms');

      // Step 2: Extract frames and detect faces
      _log('Step 2: Extracting frames and detecting faces...');
      final faceDetections = await _extractFramesAndDetectFaces(
        input,
        videoInfo['duration'] as int,
        videoInfo['width'] as int,
        videoInfo['height'] as int,
      );
      _log('Detected ${faceDetections.length} face instances across frames');

      if (faceDetections.isEmpty) {
        _log('No faces detected, returning original video');
        return input;
      }

      // Step 3: Call native Media3 processor
      _log('Step 3: Calling Media3 processor...');
      final outputPath = await _channel.invokeMethod<String>('processVideo', {
        'inputPath': input.path,
        'faces': faceDetections,
      });

      if (outputPath == null) {
        _log('Media3 processing failed, returning original');
        return input;
      }

      _log('TOTAL SUCCESS in ${stopwatch.elapsedMilliseconds}ms');
      return File(outputPath);
    } catch (e, stack) {
      _log('CRITICAL ERROR in processVideoForSharing: $e');
      print(stack);
      return input;
    }
  }

  /// Extract video metadata (duration, width, height).
  Future<Map<String, int>?> _getVideoInfo(File videoFile) async {
    try {
      // Use video_thumbnail to get a frame and extract dimensions
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 720,
        quality: 25,
        timeMs: 0,
      );

      if (thumbnailPath == null) return null;

      final thumbnailBytes = await File(thumbnailPath).readAsBytes();
      final thumbnailImage = img.decodeImage(thumbnailBytes);

      if (thumbnailImage == null) return null;

      // Get video duration using a simple approach
      // Note: For more accurate duration, consider using video_player or native code
      final duration = await _estimateVideoDuration(videoFile);

      await File(thumbnailPath).delete();

      return {
        'width': thumbnailImage.width,
        'height': thumbnailImage.height,
        'duration': duration,
      };
    } catch (e) {
      _log('Error getting video info: $e');
      return null;
    }
  }

  /// Estimate video duration (simplified - assumes ~30fps and counts frames).
  /// For production, consider using video_player or native MediaMetadataRetriever.
  Future<int> _estimateVideoDuration(File videoFile) async {
    // Default to 10 seconds if we can't determine
    // TODO: Use video_player or MediaMetadataRetriever for accurate duration
    return 10000;
  }

  /// Extract frames from video and detect faces in each frame.
  ///
  /// Detects one face per frame (the most prominent face).
  /// Returns a list of face detections with normalized coordinates and timestamps.
  Future<List<Map<String, dynamic>>> _extractFramesAndDetectFaces(
    File videoFile,
    int durationMs,
    int videoWidth,
    int videoHeight,
  ) async {
    final faceDetections = <Map<String, dynamic>>[];

    // Sample frames every 500ms
    const samplingIntervalMs = 500;
    final numSamples = (durationMs / samplingIntervalMs).ceil();

    _log('Sampling $numSamples frames at ${samplingIntervalMs}ms intervals');

    for (int i = 0; i < numSamples; i++) {
      final timeMs = i * samplingIntervalMs;

      try {
        // Extract frame at this timestamp
        final framePath = await VideoThumbnail.thumbnailFile(
          video: videoFile.path,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.PNG,
          maxHeight: 720,
          quality: 50,
          timeMs: timeMs,
        );

        if (framePath == null) continue;

        // Decode frame
        final frameBytes = await File(framePath).readAsBytes();
        var frameImage = img.decodeImage(frameBytes);
        await File(framePath).delete();

        if (frameImage == null) continue;

        // Bake orientation
        frameImage = img.bakeOrientation(frameImage);

        // Detect face in this frame (detects one face per frame)
        final detection = await _faceDetectorService.detectFaceFromImage(
          frameImage,
          generateDebugImage: false,
        );

        // If face detected, add to list with normalized coordinates
        if (detection != null) {
          final box = detection.box;

          // Normalize coordinates to 0-1 range using frame dimensions
          // (frame may be scaled by video_thumbnail, so we use frame dimensions)
          final frameWidth = frameImage.width;
          final frameHeight = frameImage.height;

          faceDetections.add({
            'x': box.x / frameWidth,
            'y': box.y / frameHeight,
            'width': box.width / frameWidth,
            'height': box.height / frameHeight,
            'startTimeMs': timeMs,
            // Face visible until next sample or end of video
            'endTimeMs': ((i + 1) * samplingIntervalMs).clamp(0, durationMs),
          });
        }
      } catch (e) {
        _log('Error processing frame at ${timeMs}ms: $e');
      }
    }

    return faceDetections;
  }

  /// Clean up temporary files created during privacy processing.
  Future<void> cleanUpTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      for (final file in files) {
        if (file is File &&
            (path.basename(file.path).startsWith('privacy_video_') ||
                path.basename(file.path).contains('thumbnail'))) {
          try {
            await file.delete();
          } catch (e) {
            // Ignore deletion errors
          }
        }
      }
    } catch (e) {
      _log('Cleanup error: $e');
    }
  }
}
