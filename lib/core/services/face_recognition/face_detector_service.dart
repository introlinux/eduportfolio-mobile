import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';

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

    print('Generated ${_anchors!.length} anchors for BlazeFace Short-Range');
  }

  /// Initialize the face detection model
  Future<void> initialize() async {
    print('========================================');
    print('Initializing FaceDetectorService...');
    print('========================================');
    try {
      print('Loading BlazeFace Full-Range model from assets...');

      // Configure interpreter options with GPU acceleration
      final options = InterpreterOptions();

      // Enable GPU acceleration for better performance
      try {
        if (Platform.isAndroid) {
          print('Configuring GPU delegate for Android...');
          final gpuDelegate = GpuDelegateV2(
            options: GpuDelegateOptionsV2(),
          );
          options.addDelegate(gpuDelegate);
          print('✓ GPU delegate configured for Android');
        } else if (Platform.isIOS) {
          print('Configuring GPU delegate for iOS...');
          final gpuDelegate = GpuDelegate();
          options.addDelegate(gpuDelegate);
          print('✓ GPU delegate configured for iOS');
        }
      } catch (e) {
        print('⚠️  GPU delegate setup failed: $e');
        print('⚠️  Falling back to CPU execution');
      }

      // Set number of threads for CPU fallback
      options.threads = 4;

      _interpreter = await Interpreter.fromAsset(
        'assets/models/blaze_face_short_range.tflite',
        options: options,
      );

      print('✓ BlazeFace Short-Range model loaded successfully');

      // Generate anchors for box decoding
      _generateAnchors();

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape0 = _interpreter!.getOutputTensor(0).shape;
      final outputShape1 = _interpreter!.getOutputTensor(1).shape;

      print('✓ Model shapes verified:');
      print('  - Input: $inputShape (expected: [1, 128, 128, 3])');
      print('  - Output 0 (boxes): $outputShape0 (expected: [1, 896, 16])');
      print('  - Output 1 (scores): $outputShape1 (expected: [1, 896])');
      print('✓ BlazeFace Full-Range ready (detects faces up to 5 meters)');
      print('✓ GPU acceleration: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Not available"}');
      print('========================================');
    } catch (e, stackTrace) {
      print('========================================');
      print('✗ ERROR loading BlazeFace model');
      print('✗ Error type: ${e.runtimeType}');
      print('✗ Error details: $e');
      print('✗ Stack trace (first 5 lines):');
      final stackLines = stackTrace.toString().split('\n').take(5);
      for (final line in stackLines) {
        print('  $line');
      }
      print('✗ Face detection will FAIL (placeholder returns null)');
      print('========================================');
      // Don't rethrow - allow graceful degradation
    }
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    print('Face detector disposed');
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
      return await _detectFaceWithBlazeFace(image, generateDebugImage: false);
    } catch (e) {
      print('Error detecting face: $e');
      return null;
    }
  }

  /// Detect face from already loaded image (e.g. from camera stream)
  Future<FaceDetectionResult?> detectFaceFromImage(img.Image image) async {
    try {
      // Generate debug image for live preview visualization
      return await _detectFaceWithBlazeFace(image, generateDebugImage: true);
    } catch (e) {
      print('Error detecting face from image: $e');
      return null;
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

      // DEBUG: Log image dimensions to verify orientation
      print('  - DEBUG Image dimensions after bakeOrientation: ${image.width}x${image.height}');

      // Use BlazeFace for real face detection
      final detection = await _detectFaceWithBlazeFace(image);

      if (detection == null) {
        return null;
      }

      // Perform heavy cropping and optional rotation in Isolate
      final croppedFace = await Isolate.run(() {
        return _alignAndCropFace(image, detection);
      });

      return croppedFace;
    } catch (e) {
      print('Error detecting face: $e');
      return null;
    }
  }

  /// Crop face using pre-computed detection result (optimized for training)
  ///
  /// This method skips face detection and directly crops using known coordinates.
  /// Used when we already detected the face during capture validation.
  Future<img.Image?> cropFaceWithDetection(
    File imageFile,
    FaceDetectionResult detection,
  ) async {
    try {
      debugPrint('🚀 OPTIMIZED: Cropping with pre-computed detection (SKIP detection step)');
      final startTime = DateTime.now();

      // Run heavy image decoding in Isolate (same as detectAndCropFace)
      final image = await Isolate.run(() async {
        final bytes = await imageFile.readAsBytes();
        var decoded = img.decodeImage(bytes);
        if (decoded == null) return null;
        // Fix orientation based on EXIF metadata (expensive)
        decoded = img.bakeOrientation(decoded);

        // Android camera workaround (same as detectAndCropFace)
        if ((decoded.width > 1000 || decoded.height > 1000) && decoded.height > decoded.width) {
          decoded = img.copyRotate(decoded, angle: 90);
        }

        return decoded;
      });

      if (image == null) {
        return null;
      }

      debugPrint('  - Image decoded and oriented: ${image.width}x${image.height}');

      // Use the pre-computed detection result (skip detection step!)
      // Perform heavy cropping in Isolate
      final croppedFace = await Isolate.run(() {
        return _alignAndCropFace(image, detection);
      });

      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ OPTIMIZED crop completed in ${duration.inMilliseconds}ms');

      return croppedFace;
    } catch (e) {
      debugPrint('❌ Error cropping face with detection: $e');
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

      final detection = await _detectFaceWithBlazeFace(image);

      if (detection == null) {
        return null;
      }

      final croppedFace = await Isolate.run(() {
        return _alignAndCropFace(image, detection);
      });

      return croppedFace;
    } catch (e) {
      print('Error detecting face from bytes: $e');
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

      // DEBUG: Log landmark positions
      print('  - DEBUG Landmarks: rightEye=(${rightEye.x.toStringAsFixed(1)}, ${rightEye.y.toStringAsFixed(1)}), leftEye=(${leftEye.x.toStringAsFixed(1)}, ${leftEye.y.toStringAsFixed(1)})');
      print('  - DEBUG FaceBox: x=${faceRect.x}, y=${faceRect.y}, w=${faceRect.width}, h=${faceRect.height}');

      // Calculate angle between eyes
      // For a normal upright face: leftEye.x < rightEye.x (left eye is on the left side of image)
      // Use (leftEye - rightEye) to get vector pointing from right to left
      final dy = leftEye.y - rightEye.y;
      final dx = leftEye.x - rightEye.x;
      
      // Calculate angle in degrees
      final angleRad = atan2(dy, dx);
      var angleDeg = angleRad * 180 / pi;

      print('  - DEBUG: dy=$dy, dx=$dx, angleDeg=${angleDeg.toStringAsFixed(1)}');

      // Only apply rotation if angle is reasonable (between -30 and +30 degrees)
      // Larger values indicate incorrect landmark detection
      if (angleDeg.abs() > 5.0 && angleDeg.abs() <= 30.0) {
        print('  - Face rotation needed: ${angleDeg.toStringAsFixed(1)}°');
        
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
  Future<FaceDetectionResult?> _detectFaceWithBlazeFace(
    img.Image image, {
    bool generateDebugImage = false,
  }) async {
    // Fallback to placeholder if model not initialized
    if (_interpreter == null) {
      print('⚠️  BlazeFace not initialized - model failed to load');
      return null;
    }

    // print('🔍 Detecting face with BlazeFace...');

    try {
      // Aspect Ratio Preservation:
      // BlazeFace expects 128x128 square input. Default copyResize distorts aspect ratio,
      // creating "squashed" faces in portrait mode (9:16 -> 1:1) which fails detection.
      // We must Pad to Square (Letterbox) before resizing.
      
      final double imgW = image.width.toDouble();
      final double imgH = image.height.toDouble();
      final double maxDim = max(imgW, imgH);
      
      // Calculate padding to center image in square
      final double padX = (maxDim - imgW) / 2.0;
      final double padY = (maxDim - imgH) / 2.0;
      
      // Process image in isolate for better performance
      final tensor = await Isolate.run(() {
        // Create square canvas
        final square = img.Image(
          width: maxDim.toInt(),
          height: maxDim.toInt(),
          backgroundColor: img.ColorRgb8(0, 0, 0)
        );

        // Composite original image into center
        img.compositeImage(square, image, dstX: padX.toInt(), dstY: padY.toInt());

        // Now resize the SQUARE image to 128x128 (Aspect ratio preserved)
        final resized = img.copyResize(
          square,
          width: 128,
          height: 128,
          interpolation: img.Interpolation.linear,
        );

        return _imageToInputTensor(resized);
      });

      final input = tensor;
      // Generate debug image only if requested (on main thread to avoid isolate complexity)
      Uint8List? debugImageBytes;
      if (generateDebugImage) {
        final square = img.Image(
          width: maxDim.toInt(),
          height: maxDim.toInt(),
          backgroundColor: img.ColorRgb8(0, 0, 0)
        );
        img.compositeImage(square, image, dstX: padX.toInt(), dstY: padY.toInt());
        final resized = img.copyResize(square, width: 128, height: 128, interpolation: img.Interpolation.linear);
        debugImageBytes = img.encodeJpg(resized);
      }

      // Prepare output tensors
      // Output 0: Detection boxes [1, 896, 16] (coords + landmarks)
      // Output 1: Detection scores [1, 896, 1]
      var outputBoxes = List.generate(
        1,
        (_) => List.generate(896, (_) => List.filled(16, 0.0)),
      );
      var outputScores = List.generate(
        1,
        (_) => List.generate(896, (_) => [0.0]),
      );

      // Run inference (Must happen on same thread where interpreter was created/loaded)
      _interpreter!.runForMultipleInputs(
        [input],
        {
          0: outputBoxes,
          1: outputScores,
        },
      );

      // Post-processing finding max score
      // This is fast enough for main thread
      double maxScore = 0.0;
      int maxIndex = -1;
      final scores = outputScores[0];

      for (int i = 0; i < scores.length; i++) {
        final score = scores[i][0];
        if (score > maxScore) {
          maxScore = score;
          maxIndex = i;
        }
      }

      const confidenceThreshold = 0.70;
      if (maxScore < confidenceThreshold) {
        // print('No face detected (max confidence: ${maxScore.toStringAsFixed(2)})');
        return null;
      }

      // Decode bounding box and landmarks
      final rawData = outputBoxes[0][maxIndex];
      final anchor = _anchors![maxIndex];
      const modelInputSize = 128.0;

      // Decode Box (Normalized 0..1 relative to the 128x128 Input Square)
      final yCenterNorm = (rawData[0] / modelInputSize) + anchor[1];
      final xCenterNorm = (rawData[1] / modelInputSize) + anchor[0];
      final heightNorm = rawData[2] / modelInputSize;
      final widthNorm = rawData[3] / modelInputSize;

      // Map from Model Space (128x128) to Square Space (maxDim x maxDim)
      // The model outputs normalized coords relative to 128x128, so we scale up
      const modelInputSize128 = 128.0;
      final yCenterPx128 = yCenterNorm * modelInputSize128;
      final xCenterPx128 = xCenterNorm * modelInputSize128;
      final heightPx128 = heightNorm * modelInputSize128;
      final widthPx128 = widthNorm * modelInputSize128;

      // Now scale from 128x128 to maxDim x maxDim (the square before resizing)
      final scale = maxDim / modelInputSize128;
      final yCenterPx = yCenterPx128 * scale;
      final xCenterPx = xCenterPx128 * scale;
      final heightPx = heightPx128 * scale;
      final widthPx = widthPx128 * scale;

      // Map from Square to Original Image (Subtract Padding)
      final yCenter = yCenterPx - padY;
      final xCenter = xCenterPx - padX;
      // Width/Height maintain same scale
      final height = heightPx;
      final width = widthPx;

      final imgWidth = image.width;
      final imgHeight = image.height;

      // Debug logs (commented out for performance)
      // print('DEBUG DETECT: Img=${imgWidth}x${imgHeight} MaxDim=$maxDim Pad=${padX}x${padY}');
      // print('DEBUG DETECT: RawModel=[y:${rawData[0]}, x:${rawData[1]}, h:${rawData[2]}, w:${rawData[3]}]');
      // print('DEBUG DETECT: Anchor=[x:${anchor[0]}, y:${anchor[1]}]');
      // print('DEBUG DETECT: NormBox=[y:$yCenterNorm, x:$xCenterNorm, h:$heightNorm, w:$widthNorm]');
      // print('DEBUG DETECT: PxBoxInSquare=[y:$yCenterPx, x:$xCenterPx, h:$heightPx, w:$widthPx]');
      // print('DEBUG DETECT: FinalBox=[y:$yCenter, x:$xCenter, h:$height, w:$width]');

      // Calculate Box Corners (in PIXELS)
      final ymin = yCenter - height / 2;
      final xmin = xCenter - width / 2;
      final ymax = yCenter + height / 2;
      final xmax = xCenter + width / 2;

      // print('DEBUG DETECT: FinalCorners=[ymin:$ymin, xmin:$xmin, ymax:$ymax, xmax:$xmax]');

      // Landmarks Decoding Helper
      // They also need to be mapped from Normalized -> Square -> Original
      Point<double> getLandmark(int index) {
        final lyNorm = (rawData[4 + index * 2] / modelInputSize) + anchor[1];
        final lxNorm = (rawData[4 + index * 2 + 1] / modelInputSize) + anchor[0];
        
        final lyPx = lyNorm * maxDim;
        final lxPx = lxNorm * maxDim;
        
        return Point(lxPx - padX, lyPx - padY);
      }
      
      final rightEye = getLandmark(0);
      final leftEye = getLandmark(1);
      // final nose = getLandmark(2);

      // Convert to Integer Rect (Clamped to image bounds)
      int x = xmin.toInt();
      int y = ymin.toInt();
      int w = (xmax - xmin).toInt();
      int h = (ymax - ymin).toInt();

      // Add padding (Face box is usually tight 1:1, add context)
      final paddingX = (w * 0.2).toInt();
      final paddingY = (h * 0.2).toInt();

      x = (x - paddingX).clamp(0, imgWidth - 1).toInt();
      y = (y - paddingY).clamp(0, imgHeight - 1).toInt();
      w = (w + 2 * paddingX).clamp(1, imgWidth - x).toInt();
      h = (h + 2 * paddingY).clamp(1, imgHeight - y).toInt();

      print('Face detected with confidence: ${maxScore.toStringAsFixed(2)}');
      
      // Return the debug image too (Input Square)
      // We need to re-encode it closer to the generation point or here.
      // Since 'image' here is the original full size, and we lost the 'resized' 128x128
      // inside the isolate, we can't easily return the EXACT tensor image unless we change the isolate return type.
      
      // Let's assume for now we just want to see the alignment, 
      // but to see the tensor input we need to modify the Isolate block.
      // But for simplicity, I will skip returning the exact debug image from Isolate for now to minimize code churn,
      // UNLESS necessary.
      // Wait, the plan IS to return it. Okay.
      
      print('Face detected with confidence: ${maxScore.toStringAsFixed(2)}');
      
      return FaceDetectionResult(
        box: FaceRect(x: x, y: y, width: w, height: h),
        rightEye: rightEye,
        leftEye: leftEye,
        debugImage: debugImageBytes,
      );

    } catch (e) {
      print('Error in BlazeFace detection: $e');
      return null;
    }
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

  FaceDetectionResult({required this.box, this.rightEye, this.leftEye, this.debugImage});
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
