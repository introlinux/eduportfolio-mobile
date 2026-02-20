import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:eduportfolio/core/utils/logger.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Service for detecting faces in images
///
/// This service is responsible for:
/// 1. Detecting if a face exists in an image
/// 2. Extracting face bounding box coordinates
/// 3. Aligning the face based on eye landmarks (rotation)
/// 4. Cropping the face region for further processing
class FaceDetectorService {
  /// TFLite interpreter for BlazeFace face detection model
  Interpreter? _interpreter;

  /// Precomputed anchors for BlazeFace Short-Range (896 anchors)
  List<List<double>>? _anchors;

  /// Generate anchors for BlazeFace Short-Range model
  /// Based on MediaPipe SsdAnchorsCalculator
  void _generateAnchors() {
    _anchors = [];

    // BlazeFace Short-Range configuration
    const strides = [8, 16, 16, 16];
    const inputSize = 128;
    const minScale = 0.1484375;
    const maxScale = 0.75;
    const anchorOffsetX = 0.5;
    const anchorOffsetY = 0.5;

    int layerIndex = 0;
    for (final stride in strides) {
      // Calculate feature map dimensions
      final featureMapHeight = (inputSize / stride).ceil();
      final featureMapWidth = (inputSize / stride).ceil();

      // Calculate scale for this layer
      final scale = minScale + (maxScale - minScale) * layerIndex / (strides.length - 1);

      // Generate anchors for each position in feature map
      // BlazeFace uses 2 anchors per location
      for (int y = 0; y < featureMapHeight; y++) {
        for (int x = 0; x < featureMapWidth; x++) {
          // Calculate normalized center coordinates
          final xCenter = (x + anchorOffsetX) / featureMapWidth;
          final yCenter = (y + anchorOffsetY) / featureMapHeight;

          // Add 2 anchors per location (BlazeFace architecture)
          for (int a = 0; a < 2; a++) {
            // Add anchor [x_center, y_center, width, height]
            // Note: width and height are fixed at 1.0 for BlazeFace
            _anchors!.add([xCenter, yCenter, 1.0, 1.0]);
          }
        }
      }

      layerIndex++;
    }

    Logger.debug('Generated ${_anchors!.length} anchors for BlazeFace Short-Range');
  }

  /// Initialize the face detection model
  Future<void> initialize() async {
    Logger.info('Initializing FaceDetectorService...');
    try {
      Logger.debug('Loading BlazeFace Short-Range model from assets...');

      // Configure interpreter options with GPU acceleration
      final options = InterpreterOptions();

      // Enable GPU acceleration for better performance
      try {
        if (Platform.isAndroid) {
          final gpuDelegate = GpuDelegateV2(
            options: GpuDelegateOptionsV2(),
          );
          options.addDelegate(gpuDelegate);
          Logger.debug('GPU delegate configured for Android');
        } else if (Platform.isIOS) {
          final gpuDelegate = GpuDelegate();
          options.addDelegate(gpuDelegate);
          Logger.debug('GPU delegate configured for iOS');
        }
      } catch (e) {
        Logger.warning('GPU delegate setup failed, falling back to CPU', e);
      }

      // Set number of threads for CPU fallback
      options.threads = 4;

      _interpreter = await Interpreter.fromAsset(
        'assets/models/blaze_face_short_range.tflite',
        options: options,
      );

      // Generate anchors for box decoding
      _generateAnchors();

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape0 = _interpreter!.getOutputTensor(0).shape;
      final outputShape1 = _interpreter!.getOutputTensor(1).shape;

      Logger.info('FaceDetectorService ready — input: $inputShape, boxes: $outputShape0, scores: $outputShape1');
    } catch (e, stackTrace) {
      Logger.error('Failed to load BlazeFace model — face detection will not work', e, stackTrace);
      // Don't rethrow - allow graceful degradation
    }
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    Logger.debug('Face detector disposed');
  }

  /// Detect face and return both processed image and detection (OPTIMIZED for training)
  ///
  /// Returns image in memory to avoid re-reading from disk later.
  /// This eliminates duplicate I/O during training workflow.
  Future<({img.Image processedImage, FaceDetectionResult detection})?> detectFaceFromFile(
    File imageFile,
  ) async {
    try {
      final readStart = DateTime.now();

      // Run heavy image decoding in Isolate
      final image = await Isolate.run(() async {
        final bytes = await imageFile.readAsBytes();
        var decoded = img.decodeImage(bytes);
        if (decoded == null) return null;
        decoded = img.bakeOrientation(decoded);

        // Android camera workaround
        if ((decoded.width > 1000 || decoded.height > 1000) && decoded.height > decoded.width) {
          decoded = img.copyRotate(decoded, angle: 90);
        }

        return decoded;
      });

      if (image == null) {
        return null;
      }

      final readDuration = DateTime.now().difference(readStart);
      Logger.debug('Image decoded in ${readDuration.inMilliseconds}ms');

      final detections = await _detectFacesWithBlazeFace(image);
      final detection = detections.isNotEmpty ? detections.first : null;

      if (detection == null) {
        return null;
      }

      // Return both image and detection
      return (processedImage: image, detection: detection);
    } catch (e) {
      Logger.error('Error detecting face from file', e);
      return null;
    }
  }

  /// Detect face in image and return detection result (box + landmarks)
  ///
  /// Returns null if no face is detected
  Future<FaceDetectionResult?> detectFace(File imageFile) async {
    try {
      // Run heavy image decoding in Isolate
      final image = await Isolate.run(() async {
        final bytes = await imageFile.readAsBytes();
        var decoded = img.decodeImage(bytes);
        if (decoded == null) return null;
        decoded = img.bakeOrientation(decoded);

        if ((decoded.width > 1000 || decoded.height > 1000) && decoded.height > decoded.width) {
          decoded = img.copyRotate(decoded, angle: 90);
        }

        return decoded;
      });

      if (image == null) return null;

      // Use BlazeFace for detection (no debug image for performance)
      final detections = await _detectFacesWithBlazeFace(image, generateDebugImage: false);
      return detections.isNotEmpty ? detections.first : null;
    } catch (e) {
      Logger.error('Error detecting face', e);
      return null;
    }
  }

  /// Detect face from already loaded image (e.g. from camera stream).
  /// [generateDebugImage] controls whether a debug visualization is produced;
  /// set to false when only the bounding box is needed (e.g. privacy pixelation).
  Future<FaceDetectionResult?> detectFaceFromImage(img.Image image,
      {bool generateDebugImage = true}) async {
    final faces = await detectFacesFromImage(image, generateDebugImage: generateDebugImage);
    return faces.isNotEmpty ? faces.first : null;
  }

  /// Detect ALL faces from already loaded image.
  /// Returns a list of detected faces, sorted by confidence.
  Future<List<FaceDetectionResult>> detectFacesFromImage(img.Image image,
      {bool generateDebugImage = true}) async {
    try {
      return await _detectFacesWithBlazeFace(image, generateDebugImage: generateDebugImage);
    } catch (e) {
      Logger.error('Error detecting face from image', e);
      return []; // Return empty list on error
    }
  }

  /// Detect face in image and return cropped face
  ///
  /// Returns null if no face is detected
  /// Returns cropped (and aligned/rotated) face image if face is found
  Future<img.Image?> detectAndCropFace(File imageFile) async {
    try {
      // Run heavy image decoding in Isolate
      final image = await Isolate.run(() async {
        final bytes = await imageFile.readAsBytes();
        var decoded = img.decodeImage(bytes);
        if (decoded == null) return null;
        // Fix orientation based on EXIF metadata (expensive)
        decoded = img.bakeOrientation(decoded);
        
        // Android camera workaround:
        // Even after bakeOrientation, Android camera images often have the
        // CONTENT rotated 90° from what it should be. The image dimensions
        // may be correct (portrait 2160x3840) but the face is sideways.
        // We rotate +90° to fix the content orientation.
        // Only apply to large images (likely from camera, not thumbnails)
        // AND only if the image is portrait (height > width).
        // If it's landscape (width > height), the sensor alignment is usually correct.
        if ((decoded.width > 1000 || decoded.height > 1000) && decoded.height > decoded.width) {
          // Rotate content +90° (CW) to correct the Android camera rotation regarding Portrait
          decoded = img.copyRotate(decoded, angle: 90);
        }
        
        return decoded;
      });

      if (image == null) {
        return null;
      }

      // Use BlazeFace for real face detection
      final detections = await _detectFacesWithBlazeFace(image);
      final detection = detections.isNotEmpty ? detections.first : null;

      if (detection == null) {
        return null;
      }

      // Perform heavy cropping and optional rotation in Isolate
      final croppedFace = await Isolate.run(() {
        return _alignAndCropFace(image, detection);
      });

      return croppedFace;
    } catch (e) {
      Logger.error('Error in detectAndCropFace', e);
      return null;
    }
  }

  /// Crop face using pre-computed detection result (optimized for training)
  ///
  /// Accepts image already in memory to eliminate disk I/O.
  /// This method skips face detection and directly crops using known coordinates.
  Future<img.Image?> cropFaceWithDetection(
    img.Image image,
    FaceDetectionResult detection,
  ) async {
    try {
      // Perform cropping in Isolate (image already processed, just crop!)
      return await Isolate.run(() {
        return _alignAndCropFace(image, detection);
      });
    } catch (e) {
      Logger.error('Error cropping face with detection', e);
      return null;
    }
  }

  /// Detect face in memory (from Uint8List)
  Future<img.Image?> detectAndCropFaceFromBytes(Uint8List bytes) async {
    try {
      // Run heavy image decoding in Isolate
      final image = await Isolate.run(() {
        var decoded = img.decodeImage(bytes);
        if (decoded == null) return null;
        decoded = img.bakeOrientation(decoded);
        
        // Android camera workaround: rotate large images +90° only if portrait
        if ((decoded.width > 1000 || decoded.height > 1000) && decoded.height > decoded.width) {
          decoded = img.copyRotate(decoded, angle: 90);
        }
        
        return decoded;
      });

      if (image == null) {
        return null;
      }

      final detections = await _detectFacesWithBlazeFace(image);
      final detection = detections.isNotEmpty ? detections.first : null;

      if (detection == null) {
        return null;
      }

      final croppedFace = await Isolate.run(() {
        return _alignAndCropFace(image, detection);
      });

      return croppedFace;
    } catch (e) {
      Logger.error('Error detecting face from bytes', e);
      return null;
    }
  }

  /// Helper to align (rotate) and crop the face based on landmarks
  static img.Image _alignAndCropFace(img.Image image, FaceDetectionResult detection) {
    var srcImage = image;
    final faceRect = detection.box;

    // Calculate rotation angle if landmarks are available
    if (detection.rightEye != null && detection.leftEye != null) {
      final rightEye = detection.rightEye!;
      final leftEye = detection.leftEye!;

      // Calculate angle between eyes
      // For a normal upright face: leftEye.x < rightEye.x (left eye is on the left side of image)
      // Use (leftEye - rightEye) to get vector pointing from right to left
      final dy = leftEye.y - rightEye.y;
      final dx = leftEye.x - rightEye.x;

      // Calculate angle in degrees
      final angleRad = atan2(dy, dx);
      var angleDeg = angleRad * 180 / pi;

      // Only apply rotation if angle is reasonable (between -30 and +30 degrees)
      // Larger values indicate incorrect landmark detection
      if (angleDeg.abs() > 5.0 && angleDeg.abs() <= 30.0) {
        
        // Strategy: Crop a larger area, rotate it, then crop the core face.
        // This avoids rotating the full multi-megapixel image.
        
        final expandedPadding = 0.5; // 50% extra padding
        final cx = faceRect.x + faceRect.width / 2;
        final cy = faceRect.y + faceRect.height / 2;
        // Size of the loose crop (enough to cover rotation without losing corners)
        final size = max(faceRect.width, faceRect.height) * (1 + expandedPadding);
        
        final ex = (cx - size / 2).toInt();
        final ey = (cy - size / 2).toInt();
        final es = size.toInt();
        
        // Crop loose box (clamp to bounds)
        // copyCrop handles out of bounds by clamping? No, we must clamp.
        final safeX = ex.clamp(0, image.width - 1);
        final safeY = ey.clamp(0, image.height - 1);
        // Ensure width/height don't go out of bounds
        final safeW = (safeX + es > image.width) ? image.width - safeX : es;
        final safeH = (safeY + es > image.height) ? image.height - safeY : es;
        
        if (safeW <= 0 || safeH <= 0) {
          // Should not happen if face is inside image
          return img.copyCrop(srcImage, x: faceRect.x, y: faceRect.y, width: faceRect.width, height: faceRect.height);
        }

        var looseCrop = img.copyCrop(
          image, 
          x: safeX, 
          y: safeY, 
          width: safeW, 
          height: safeH
        );
        
        // Rotate the loose crop
        // We want to rotate so eyes become horizontal.
        // Use NEGATIVE angle to counter the detected tilt.
        looseCrop = img.copyRotate(looseCrop, angle: -angleDeg);
        
        // Now crop the center of the rotated loose crop to get final face
        // Final size should be roughly original face size
        final finalSize = max(faceRect.width, faceRect.height);
        
        // Center of the rotated image
        final looseCx = looseCrop.width / 2;
        final looseCy = looseCrop.height / 2;
        
        final startX = (looseCx - finalSize / 2).toInt().clamp(0, looseCrop.width - 1);
        final startY = (looseCy - finalSize / 2).toInt().clamp(0, looseCrop.height - 1);
        final finalW = (startX + finalSize > looseCrop.width) ? looseCrop.width - startX : finalSize;
        final finalH = (startY + finalSize > looseCrop.height) ? looseCrop.height - startY : finalSize;

        return img.copyCrop(
          looseCrop, 
          x: startX, 
          y: startY, 
          width: finalW, 
          height: finalH
        );
      }
    }

    // Default: just crop directly if no rotation needed
    return img.copyCrop(
      srcImage,
      x: faceRect.x,
      y: faceRect.y,
      width: faceRect.width,
      height: faceRect.height,
    );
  }

  /// Detect face using BlazeFace TFLite model
  ///
  /// Set [generateDebugImage] to false to skip debug image generation (improves performance)
  /// Detect faces using BlazeFace TFLite model
  ///
  /// Set [generateDebugImage] to false to skip debug image generation (improves performance)
  Future<List<FaceDetectionResult>> _detectFacesWithBlazeFace(
    img.Image image, {
    bool generateDebugImage = false,
  }) async {
    // Fallback if model not initialized
    if (_interpreter == null) {
      Logger.warning('BlazeFace not initialized — model failed to load');
      return [];
    }

    try {
      // Aspect Ratio Preservation (Same as before)
      final double imgW = image.width.toDouble();
      final double imgH = image.height.toDouble();
      final double maxDim = max(imgW, imgH);
      
      final double padX = (maxDim - imgW) / 2.0;
      final double padY = (maxDim - imgH) / 2.0;
      
      // Process image in isolate
      final tensor = await Isolate.run(() {
        final square = img.Image(
          width: maxDim.toInt(),
          height: maxDim.toInt(),
          backgroundColor: img.ColorRgb8(0, 0, 0)
        );

        img.compositeImage(square, image, dstX: padX.toInt(), dstY: padY.toInt());

        final resized = img.copyResize(
          square,
          width: 128,
          height: 128,
          interpolation: img.Interpolation.linear,
        );

        return _imageToInputTensor(resized);
      });

      final input = tensor;
      Uint8List? debugImageBytes;
      
      if (generateDebugImage) {
        // ... debug image generation same as before ...
         final square = img.Image(
          width: maxDim.toInt(),
          height: maxDim.toInt(),
          backgroundColor: img.ColorRgb8(0, 0, 0)
        );
        img.compositeImage(square, image, dstX: padX.toInt(), dstY: padY.toInt());
        final resized = img.copyResize(square, width: 128, height: 128, interpolation: img.Interpolation.linear);
        debugImageBytes = img.encodeJpg(resized);
      }

      var outputBoxes = List.generate(
        1,
        (_) => List.generate(896, (_) => List.filled(16, 0.0)),
      );
      var outputScores = List.generate(
        1,
        (_) => List.generate(896, (_) => [0.0]),
      );

      _interpreter!.runForMultipleInputs(
        [input],
        {
          0: outputBoxes,
          1: outputScores,
        },
      );

      // Collect all valid detections above threshold
      const confidenceThreshold = 0.70;
      const modelInputSize = 128.0;
      const modelInputSize128 = 128.0;
      final scale = maxDim / modelInputSize128;

      final scores = outputScores[0];
      final boxes = outputBoxes[0];
      
      List<FaceDetectionResult> detections = [];

      for (int i = 0; i < scores.length; i++) {
        final score = scores[i][0];
        if (score < confidenceThreshold) continue;

        final rawData = boxes[i];
        final anchor = _anchors![i];

        // Decode Box
        final yCenterNorm = (rawData[0] / modelInputSize) + anchor[1];
        final xCenterNorm = (rawData[1] / modelInputSize) + anchor[0];
        final heightNorm = rawData[2] / modelInputSize;
        final widthNorm = rawData[3] / modelInputSize;

        // Map to Pixel Space
        final yCenterPx = (yCenterNorm * modelInputSize128) * scale;
        final xCenterPx = (xCenterNorm * modelInputSize128) * scale;
        final heightPx = (heightNorm * modelInputSize128) * scale;
        final widthPx = (widthNorm * modelInputSize128) * scale;

        // Map to Original Image
        final yCenter = yCenterPx - padY;
        final xCenter = xCenterPx - padX;
        final height = heightPx;
        final width = widthPx;

        // Calculate Corners
        final ymin = yCenter - height / 2;
        final xmin = xCenter - width / 2;
        final ymax = yCenter + height / 2;
        final xmax = xCenter + width / 2;

        // Landmarks Helper
        Point<double> getLandmark(int index) {
          final lyNorm = (rawData[4 + index * 2] / modelInputSize) + anchor[1];
          final lxNorm = (rawData[4 + index * 2 + 1] / modelInputSize) + anchor[0];
          final lyPx = lyNorm * maxDim;
          final lxPx = lxNorm * maxDim;
          return Point(lxPx - padX, lyPx - padY);
        }

        final rightEye = getLandmark(0);
        final leftEye = getLandmark(1);

        // Integer Rect with Clamping
        int x = xmin.toInt();
        int y = ymin.toInt();
        int w = (xmax - xmin).toInt();
        int h = (ymax - ymin).toInt();

        // Padding
        final paddingX = (w * 0.2).toInt();
        final paddingY = (h * 0.2).toInt();

        x = (x - paddingX).clamp(0, imgW.toInt() - 1);
        y = (y - paddingY).clamp(0, imgH.toInt() - 1);
        w = (w + 2 * paddingX).clamp(1, imgW.toInt() - x);
        h = (h + 2 * paddingY).clamp(1, imgH.toInt() - y);

        detections.add(FaceDetectionResult(
          box: FaceRect(x: x, y: y, width: w, height: h),
          rightEye: rightEye,
          leftEye: leftEye,
          debugImage: debugImageBytes,
          score: score,
        ));
      }

      // Perform Non-Maximum Suppression (NMS)
      return _nonMaxSuppression(detections, 0.3);

    } catch (e) {
      Logger.error('Error in BlazeFace detection', e);
      return [];
    }
  }

  /// Calculate IoU (Intersection over Union)
  double _iou(FaceRect a, FaceRect b) {
    final areaA = a.width * a.height;
    final areaB = b.width * b.height;
    
    final intersectionX = max(a.x, b.x);
    final intersectionY = max(a.y, b.y);
    final intersectionW = max(0, min(a.x + a.width, b.x + b.width) - intersectionX);
    final intersectionH = max(0, min(a.y + a.height, b.y + b.height) - intersectionY);
    
    final intersectionArea = intersectionW * intersectionH;
    return intersectionArea / (areaA + areaB - intersectionArea);
  }

  /// Non-Maximum Suppression
  List<FaceDetectionResult> _nonMaxSuppression(List<FaceDetectionResult> detections, double iouThreshold) {
    if (detections.isEmpty) return [];

    // Sort by score descending
    detections.sort((a, b) => b.score.compareTo(a.score));

    List<FaceDetectionResult> picked = [];
    List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      picked.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        if (_iou(detections[i].box, detections[j].box) > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return picked;
  }

  /// Static helper for Isolate usage
  static List<List<List<List<double>>>> _imageToInputTensor(img.Image image) {
    return List.generate(
      1,
      (_) => List.generate(
        128,
        (y) => List.generate(
          128,
          (x) {
            final pixel = image.getPixel(x, y);
            final r = (pixel.r / 127.5) - 1.0;
            final g = (pixel.g / 127.5) - 1.0;
            final b = (pixel.b / 127.5) - 1.0;
            return [r, g, b];
          },
        ),
      ),
    );
  }

  /// Normalize face for model input (MobileFaceNet)
  /// Resize to 112x112
  Future<img.Image> normalizeFaceForModel(img.Image face) async {
    // Run in Isolate as resize is costly
    return await Isolate.run(() {
      return img.copyResize(
        face,
        width: 112,
        height: 112,
        interpolation: img.Interpolation.linear,
      );
    });
  }
}

class FaceDetectionResult {
  final FaceRect box;
  final Point<double>? rightEye;
  final Point<double>? leftEye;
  final Uint8List? debugImage;
  final double score;

  FaceDetectionResult({
    required this.box, 
    this.rightEye, 
    this.leftEye, 
    this.debugImage,
    this.score = 0.0,
  });
}

class FaceRect {
  final int x;
  final int y;
  final int width;
  final int height;

  FaceRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  String toString() => 'FaceRect(x: $x, y: $y, w: $width, h: $height)';
}
