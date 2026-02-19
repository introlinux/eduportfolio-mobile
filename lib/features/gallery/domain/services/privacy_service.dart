import 'dart:io';
import 'dart:isolate';
import 'package:eduportfolio/core/services/face_recognition/face_detector_service.dart';
import 'package:eduportfolio/core/utils/logger.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service to handle privacy protection (face pixelation) for shared images
class PrivacyService {
  final FaceDetectorService _faceDetectorService;

  PrivacyService(this._faceDetectorService);

  /// Process an image for sharing, optionally applying privacy protection (pixelation).
  ///
  /// Pipeline:
  ///   1. [Isolate]  read + decode + bakeOrientation   (correct output orientation)
  ///   2. [Main]     optional 90° rotation copy        (BlazeFace needs landscape for large portraits)
  ///   3. [Main]     BlazeFace detection               (TFLite runs on the main thread)
  ///   4. [Main]     map coordinates back if rotated + pixelate face region
  ///   5. [Isolate]  JPEG encode + file write
  Future<File> processImageForSharing(File input, bool privacyEnabled) async {
    if (!privacyEnabled) {
      return input;
    }

    final stopwatch = Stopwatch()..start();
    Logger.debug('START processing ${input.path}');

    try {
      // 1. Read + decode + bakeOrientation in isolate.
      //    bakeOrientation produces the correctly-oriented image that will be saved.
      //    The 90° rotation hack used by detectFace() is NOT applied here — that is
      //    only needed temporarily for BlazeFace detection (step 2).
      Logger.debug('Step 1: Decoding image...');
      final image = await Isolate.run(() async {
        final bytes = await input.readAsBytes();
        var decoded = img.decodeImage(bytes);
        if (decoded == null) return null;
        decoded = img.bakeOrientation(decoded);
        return decoded;
      });
      Logger.debug('Image decoded in ${stopwatch.elapsedMilliseconds}ms');

      if (image == null) {
        Logger.debug('Failed to decode image. Returning original.');
        return input;
      }
      Logger.debug('Decoded dimensions: ${image.width}x${image.height}');

      // 2. BlazeFace fails to detect faces in large portrait images due to aspect
      //    ratio distortion when resizing to 128×128.  detectFace() works around this
      //    by rotating portrait images 90° before inference.  We do the same here, but
      //    on a separate copy so the output image stays correctly oriented.
      final needsRotation = (image.width > 1000 || image.height > 1000) &&
          image.height > image.width;
      final detectionImage =
          needsRotation ? img.copyRotate(image, angle: 90) : image;
      Logger.debug('Detection image: ${detectionImage.width}x${detectionImage.height}' +
          (needsRotation ? ' (rotated copy)' : ''));

      // 3. Detect face (main thread — TFLite constraint).
      Logger.debug('Step 2: Detecting face...');
      final detection = await _faceDetectorService.detectFaceFromImage(
        detectionImage,
        generateDebugImage: false,
      );
      Logger.debug('Face detection finished in ${stopwatch.elapsedMilliseconds}ms');

      if (detection == null) {
        Logger.debug('No face detected. Returning original.');
        return input;
      }
      Logger.debug('Face detected at ${detection.box}');

      // 4. If we rotated for detection, map the bounding box back to the original
      //    image space.  copyRotate(angle: 90) is a 90° CW rotation; for a source
      //    image of width W and height H the inverse mapping for a box is:
      //      x_orig  = box.y
      //      y_orig  = H - box.x - box.width
      //      w_orig  = box.height
      //      h_orig  = box.width
      final box = needsRotation
          ? FaceRect(
              x: detection.box.y,
              y: image.height - detection.box.x - detection.box.width,
              width: detection.box.height,
              height: detection.box.width,
            )
          : detection.box;
      Logger.debug('Mapped box (output space): $box');

      // 5. Pixelate the face region in-place on the correctly-oriented image.
      Logger.debug('Step 3: Pixelating...');
      _pixelateImage(image, box);
      Logger.debug('Pixelation done in ${stopwatch.elapsedMilliseconds}ms');

      // 6. Encode + write in isolate (JPEG encoding is CPU-heavy).
      Logger.debug('Step 4: Encoding and saving...');
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'privacy_temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await Isolate.run(() async {
        final outputBytes = img.encodeJpg(image, quality: 80);
        await File(targetPath).writeAsBytes(outputBytes);
      });

      Logger.debug('TOTAL SUCCESS in ${stopwatch.elapsedMilliseconds}ms');
      return File(targetPath);
    } catch (e, stack) {
      Logger.error('Critical error in processImageForSharing', e, stack);
      return input;
    }
  }

  /// Apply mosaic pixelation to the face region directly on [image].
  /// Downscales the face crop to [mosaicBlockCount] blocks wide, then upscales
  /// with nearest-neighbor interpolation to produce the blocky mosaic effect.
  static void _pixelateImage(img.Image image, FaceRect box) {
    final px = box.x.clamp(0, image.width - 1);
    final py = box.y.clamp(0, image.height - 1);
    final pw = box.width.clamp(0, image.width - px);
    final ph = box.height.clamp(0, image.height - py);

    if (pw <= 0 || ph <= 0) return;

    // 12 blocks wide = very blocky / unrecognizable.
    // 20 blocks wide = slightly recognizable features.
    const mosaicBlockCount = 12;

    final smallWidth = mosaicBlockCount;
    final smallHeight = (mosaicBlockCount * (ph / pw)).round().clamp(1, ph);

    final faceCrop = img.copyCrop(image, x: px, y: py, width: pw, height: ph);

    final smallFace = img.copyResize(
      faceCrop,
      width: smallWidth,
      height: smallHeight,
      interpolation: img.Interpolation.average,
    );

    final pixelatedFace = img.copyResize(
      smallFace,
      width: pw,
      height: ph,
      interpolation: img.Interpolation.nearest,
    );

    img.compositeImage(image, pixelatedFace, dstX: px, dstY: py);
  }

  /// Clean up temporary files created during privacy processing
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
      Logger.warning('PrivacyService cleanup error', e);
    }
  }
}
