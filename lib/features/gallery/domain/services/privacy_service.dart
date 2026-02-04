import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:eduportfolio/core/services/face_recognition/face_detector_service.dart';

/// Service to handle privacy protection (face pixelation) for shared images
class PrivacyService {
  final FaceDetectorService _faceDetectorService;

  PrivacyService(this._faceDetectorService);

  void _log(String message) {
    final now = DateTime.now();
    print('[PrivacyService ${now.hour}:${now.minute}:${now.second}.${now.millisecond}] $message');
  }

  /// Process an image for sharing, optionally applying privacy protection (pixelation)
  Future<File> processImageForSharing(File input, bool privacyEnabled) async {
    if (!privacyEnabled) {
      return input;
    }

    final stopwatch = Stopwatch()..start();
    _log('START processing ${input.path}');

    try {
      // 1. Detect face
      _log('Step 1: Detecting face...');
      final detectionResult = await _faceDetectorService.detectFace(input);
      _log('Face detection finished in ${stopwatch.elapsedMilliseconds}ms');

      if (detectionResult == null) {
        _log('No face detected. Returning original.');
        return input;
      }
      _log('Face detected at ${detectionResult.box}');

      // 2. Process image (Resize + Pixelate + Fix Rotation)
      _log('Step 2: Starting image processing...');
      final processStart = stopwatch.elapsedMilliseconds;
      final processedPath = await _processImage(input, detectionResult.box);
      _log('Image processing finished in ${stopwatch.elapsedMilliseconds - processStart}ms');

      if (processedPath == null) {
        _log('Processing returned null (error). Returning original.');
        return input;
      }

      _log('TOTAL SUCCESS in ${stopwatch.elapsedMilliseconds}ms');
      return File(processedPath);
    } catch (e, stack) {
      _log('CRITICAL ERROR in processImageForSharing: $e');
      print(stack);
      return input;
    }
  }

  Future<String?> _processImage(File inputFile, FaceRect detectedBox) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(tempDir.path, 'privacy_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // STEP 1: Get original dimensions
      _log('Getting original dimensions...');
      final originalBytes = await inputFile.readAsBytes();
      _log('Read original bytes: ${originalBytes.length}');
      
      // Fast decode just dimensions if possible? method decodeImage is slow for big files.
      // But we need it. Let's assume this is one bottleneck.
      // Optimization: use decodeImageFrame (header only) if available? 
      // image package 'decodeInfo' is what we want usually, but currently decodeImage reads it all.
      // Let's rely on isolate for this if it's too slow.
      // actually, let's just use FlutterImageCompress to resize FIRST, that's fast.
      // But we need ORIG dims for mapping.
      
      final originalInfo = await img.decodeImage(originalBytes); 
      if (originalInfo == null) {
          _log('Failed to decode original image header');
          return null;
      }
      _log('Original dimensions: ${originalInfo.width}x${originalInfo.height}');

      // STEP 2: Native Compress
      _log('Compressing/Resizing with native library...');
      final compressStart = DateTime.now();
      
      // User requested ORIGINAL resolution.
      // We still use compressWithFile to fix rotation (autoCorrectionAngle),
      // but we match minWidth/minHeight to original dimensions to prevent downscaling.
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        inputFile.path,
        minWidth: originalInfo.width,
        minHeight: originalInfo.height,
        quality: 90, // Higher quality for "original" feel
        autoCorrectionAngle: true, 
      );
      _log('Compression done in ${DateTime.now().difference(compressStart).inMilliseconds}ms');

      if (compressedBytes == null) {
          _log('Native compression returned null');
          return null;
      }
      _log('Compressed bytes size: ${compressedBytes.length}');

      // STEP 3: Pixelate in Isolate
      _log('Spawning Isolate for pixelation...');
      final isolateStart = DateTime.now();
      
      final result = await Isolate.run(() async {
        return _pixelateInIsolate(
          compressedBytes,
          originalInfo.width,
          originalInfo.height,
          detectedBox,
          targetPath,
        );
      });
      
      _log('Isolate finished in ${DateTime.now().difference(isolateStart).inMilliseconds}ms');
      return result;
      
    } catch (e, stack) {
      _log('Error in _processImage: $e');
      print(stack);
      return null;
    }
  }

  static void _logIsolate(String message) {
     final now = DateTime.now();
     print('[PrivacyService ISOLATE ${now.hour}:${now.minute}:${now.second}.${now.millisecond}] $message');
  }

  /// Heavy pixelation logic in Isolate
  static Future<String?> _pixelateInIsolate(
    Uint8List compressedBytes,
    int originalWidth,
    int originalHeight,
    FaceRect detectedBox,
    String targetPath,
  ) async {
    try {
      _logIsolate('Isolate started.');
      _logIsolate('Decoding compressed image...');
      final image = img.decodeImage(compressedBytes);
      if (image == null) {
          _logIsolate('Failed to decode compressed image');
          return null;
      }

      _logIsolate('Image decoded: ${image.width}x${image.height}');
      
      // COORDINATE MAPPING
      // FaceDetectorService "Hack" Check:
      bool detectorRotated = false;
      // Dimensions used by detector for calculation
      int detSpaceW = originalWidth;
      int detSpaceH = originalHeight;

      if ((originalWidth > 1000 || originalHeight > 1000) && originalHeight > originalWidth) {
        detectorRotated = true;
        detSpaceW = originalHeight;
        detSpaceH = originalWidth;
        _logIsolate('Detector rotation hack detected (Portrait->Landscape)');
      }

      FaceRect finalBox;
      if (detectorRotated) {
        // Rotated Mapping
        final xOrig = detectedBox.y;
        final yOrig = originalHeight - detectedBox.x - detectedBox.width;
        final wOrig = detectedBox.height;
        final hOrig = detectedBox.width;
        
        final double sX = image.width / originalWidth;
        final double sY = image.height / originalHeight;
        
        finalBox = FaceRect(
          x: (xOrig * sX).round(),
          y: (yOrig * sY).round(),
          width: (wOrig * sX).round(),
          height: (hOrig * sY).round(),
        );
      } else {
        // Simple Scaling
        final double sX = image.width / detSpaceW;
        final double sY = image.height / detSpaceH;
        
        finalBox = FaceRect(
          x: (detectedBox.x * sX).round(),
          y: (detectedBox.y * sY).round(),
          width: (detectedBox.width * sX).round(),
          height: (detectedBox.height * sY).round(),
        );
      }
      _logIsolate('Mapped box: $finalBox');

      // manual pixelation (Mosaic effect)
      // This is much faster than convolution filters.
      // Logic: Downscale the crop to tiny size, then upscale it back with NEAREST NEIGHBOR interpolation.
      
      // Decrease factor to make blocks BIGGER (fewer blocks across face)
      // 15 was too detailed. 8 creates 8x8 blocks across the face.
      final pixelFactor = 8; // How chunky the pixels are
      
      final px = finalBox.x.clamp(0, image.width - 1);
      final py = finalBox.y.clamp(0, image.height - 1);
      final pw = finalBox.width.clamp(0, image.width - px);
      final ph = finalBox.height.clamp(0, image.height - py);

      if (pw > 0 && ph > 0) {
        _logIsolate('Cropping face...');
        final faceCrop = img.copyCrop(image, x: px, y: py, width: pw, height: ph);
        
        _logIsolate('Pixelating using downscale/upscale...');
        // Fixed target width in "pixels" (blocks) for the face.
        // Determines how recognizable the face is. 
        // 12 blocks wide = very blocky/unrecognizable.
        // 20 blocks wide = slightly recognizable features.
        const mosaicBlockCount = 12; 
        
        final smallWidth = mosaicBlockCount;
        final smallHeight = (mosaicBlockCount * (ph / pw)).round(); // Preserve aspect ratio
        
        _logIsolate('Downscaling crop ${pw}x${ph} -> ${smallWidth}x${smallHeight}');

        final smallFace = img.copyResize(
          faceCrop, 
          width: smallWidth, 
          height: smallHeight, 
          interpolation: img.Interpolation.average
        );
        
        // 2. Upscale
        final pixelatedFace = img.copyResize(
          smallFace,
          width: pw,
          height: ph,
          interpolation: img.Interpolation.nearest, // Critical for blocky look
        );
        
        _logIsolate('Compositing...');
        img.compositeImage(image, pixelatedFace, dstX: px, dstY: py);
      } else {
        _logIsolate('Face box outside bounds, skipping pixelation');
      }

      // SAVE
      _logIsolate('Encoding JPG...');
      final outputBytes = img.encodeJpg(image, quality: 80);
      _logIsolate('Writing to file...');
      await File(targetPath).writeAsBytes(outputBytes);

      
      _logIsolate('Done.');
      return targetPath;
    } catch (e, stack) {
      _logIsolate('Error: $e');
      print(stack);
      return null;
    }
  }

  /// Clean up temporary files
  Future<void> cleanUpTempFiles() async {
     try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      for (final file in files) {
        if (file is File && 
           (path.basename(file.path).startsWith('shared_privacy_') || 
            path.basename(file.path).startsWith('privacy_temp_'))) {
          try {
            await file.delete();
          } catch (e) {}
        }
      }
    } catch (e) {
      print('[PrivacyService] Cleanup error: $e');
    }
  }
}
