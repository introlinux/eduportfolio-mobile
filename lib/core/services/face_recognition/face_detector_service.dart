import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service for detecting faces in images
///
/// This service is responsible for:
/// 1. Detecting if a face exists in an image
/// 2. Extracting face bounding box coordinates
/// 3. Cropping the face region for further processing
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
      for (int y = 0; y < featureMapHeight; y++) {
        for (int x = 0; x < featureMapWidth; x++) {
          // Calculate normalized center coordinates
          final xCenter = (x + anchorOffsetX) / featureMapWidth;
          final yCenter = (y + anchorOffsetY) / featureMapHeight;

          // Add anchor [x_center, y_center, width, height]
          // Note: width and height are fixed at 1.0 for BlazeFace
          _anchors!.add([xCenter, yCenter, 1.0, 1.0]);
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
      print('✗ Please verify:');
      print('  1. File exists: assets/models/blaze_face_full_range.tflite');
      print('  2. pubspec.yaml includes: assets/models/');
      print('  3. Run: flutter clean && flutter pub get');
      print('  4. Check if tflite_flutter plugin installed correctly');
      print('  5. GPU delegates may not be available on all devices');
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

  /// Detect face in image and return cropped face
  ///
  /// Returns null if no face is detected
  /// Returns cropped face image if face is found
  Future<img.Image?> detectAndCropFace(File imageFile) async {
    try {
      // Read image file
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) {
        return null;
      }

      // Fix orientation based on EXIF metadata
      // This corrects images captured in landscape/portrait modes
      image = img.bakeOrientation(image);

      // Use BlazeFace for real face detection
      final faceRect = await _detectFaceWithBlazeFace(image);

      if (faceRect == null) {
        return null;
      }

      // Crop the face region
      final croppedFace = img.copyCrop(
        image,
        x: faceRect.x,
        y: faceRect.y,
        width: faceRect.width,
        height: faceRect.height,
      );

      return croppedFace;
    } catch (e) {
      print('Error detecting face: $e');
      return null;
    }
  }

  /// Detect face in memory (from Uint8List)
  Future<img.Image?> detectAndCropFaceFromBytes(Uint8List bytes) async {
    try {
      var image = img.decodeImage(bytes);

      if (image == null) {
        return null;
      }

      // Fix orientation based on EXIF metadata
      image = img.bakeOrientation(image);

      final faceRect = await _detectFaceWithBlazeFace(image);

      if (faceRect == null) {
        return null;
      }

      final croppedFace = img.copyCrop(
        image,
        x: faceRect.x,
        y: faceRect.y,
        width: faceRect.width,
        height: faceRect.height,
      );

      return croppedFace;
    } catch (e) {
      print('Error detecting face from bytes: $e');
      return null;
    }
  }

  /// Detect face using BlazeFace TFLite model
  ///
  /// Returns FaceRect with bounding box coordinates
  /// Falls back to placeholder if model not initialized or detection fails
  Future<FaceRect?> _detectFaceWithBlazeFace(img.Image image) async {
    // Fallback to placeholder if model not initialized
    if (_interpreter == null) {
      print('⚠️  BlazeFace not initialized - model failed to load');
      return _detectFacePlaceholder(image);
    }

    print('🔍 Detecting face with BlazeFace...');

    try {
      // Resize image to model input size (128x128)
      final resized = img.copyResize(
        image,
        width: 128,
        height: 128,
        interpolation: img.Interpolation.linear,
      );

      // Convert image to input tensor [1, 128, 128, 3] normalized to [-1, 1]
      final input = _imageToInputTensor(resized);

      // Prepare output tensors
      // Output 0: Detection boxes [1, 896, 16] (coords + landmarks)
      // Output 1: Detection scores [1, 896, 1] (note: extra dimension)
      var outputBoxes = List.generate(
        1,
        (_) => List.generate(896, (_) => List.filled(16, 0.0)),
      );
      // BlazeFace returns [1, 896, 1] not [1, 896]
      var outputScores = List.generate(
        1,
        (_) => List.generate(896, (_) => [0.0]),
      );

      // Run inference
      _interpreter!.runForMultipleInputs(
        [input],
        {
          0: outputBoxes,
          1: outputScores,
        },
      );

      // Find detection with highest confidence
      double maxScore = 0.0;
      int maxIndex = -1;
      final scores = outputScores[0];

      for (int i = 0; i < scores.length; i++) {
        // Extract score from [score] array (shape is [1, 896, 1])
        final score = scores[i][0];
        if (score > maxScore) {
          maxScore = score;
          maxIndex = i;
        }
      }

      // Check if confidence is above threshold
      // Note: Full-Range model may have different confidence distribution than Short-Range
      // Adjust this value (0.60-0.80) if getting too many false positives/negatives
      const confidenceThreshold = 0.70;
      if (maxScore < confidenceThreshold) {
        print('No face detected (max confidence: ${maxScore.toStringAsFixed(2)})');
        return null;
      }

      // Decode bounding box using anchors
      // BlazeFace outputs offsets relative to anchors, not absolute coordinates
      final boxes = outputBoxes[0][maxIndex];
      final anchor = _anchors![maxIndex];

      // Scale factor for BlazeFace Short-Range (input size 128)
      const scale = 128.0;

      // Decode center coordinates (boxes[0]=y_center, boxes[1]=x_center)
      final yCenterOffset = boxes[0] / scale;
      final xCenterOffset = boxes[1] / scale;
      final yCenter = yCenterOffset + anchor[1]; // anchor[1] is y_center
      final xCenter = xCenterOffset + anchor[0]; // anchor[0] is x_center

      // Decode size (boxes[2]=height, boxes[3]=width)
      final heightOffset = boxes[2] / scale;
      final widthOffset = boxes[3] / scale;
      final boxHeight = heightOffset;
      final boxWidth = widthOffset;

      // Convert from center format to corner format
      final ymin = (yCenter - boxHeight / 2).clamp(0.0, 1.0);
      final xmin = (xCenter - boxWidth / 2).clamp(0.0, 1.0);
      final ymax = (yCenter + boxHeight / 2).clamp(0.0, 1.0);
      final xmax = (xCenter + boxWidth / 2).clamp(0.0, 1.0);

      print('Face detected with confidence: ${maxScore.toStringAsFixed(2)}');
      print('  Decoded box: [${ymin.toStringAsFixed(3)}, ${xmin.toStringAsFixed(3)}, ${ymax.toStringAsFixed(3)}, ${xmax.toStringAsFixed(3)}]');

      // Denormalize to pixel coordinates
      final imgWidth = image.width;
      final imgHeight = image.height;

      int x = (xmin * imgWidth).toInt();
      int y = (ymin * imgHeight).toInt();
      int width = ((xmax - xmin) * imgWidth).toInt();
      int height = ((ymax - ymin) * imgHeight).toInt();

      // Add 20% padding for better face crop
      final paddingX = (width * 0.2).toInt();
      final paddingY = (height * 0.2).toInt();

      x = (x - paddingX).clamp(0, imgWidth - 1);
      y = (y - paddingY).clamp(0, imgHeight - 1);
      width = (width + 2 * paddingX).clamp(1, imgWidth - x);
      height = (height + 2 * paddingY).clamp(1, imgHeight - y);

      return FaceRect(
        x: x,
        y: y,
        width: width,
        height: height,
      );
    } catch (e) {
      print('Error in BlazeFace detection: $e');
      print('Falling back to placeholder detection');
      return _detectFacePlaceholder(image);
    }
  }

  /// Convert image to input tensor for BlazeFace
  ///
  /// Returns [1, 128, 128, 3] tensor with pixels normalized to [-1, 1]
  List<List<List<List<double>>>> _imageToInputTensor(img.Image image) {
    // Create tensor [1, 128, 128, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        128,
        (y) => List.generate(
          128,
          (x) {
            final pixel = image.getPixel(x, y);
            // Extract RGB channels and normalize to [-1, 1]
            final r = (pixel.r / 127.5) - 1.0;
            final g = (pixel.g / 127.5) - 1.0;
            final b = (pixel.b / 127.5) - 1.0;
            return [r, g, b];
          },
        ),
      ),
    );

    return input;
  }

  /// PLACEHOLDER: Simple face detection using center crop
  ///
  /// Used as fallback when BlazeFace model is not available
  /// IMPORTANT: This should NOT be used in production - always returns null
  /// to prevent false positives (detecting faces where there are none)
  FaceRect? _detectFacePlaceholder(img.Image image) {
    print('WARNING: Using placeholder face detection - BlazeFace not available');
    print('  Returning NULL to prevent false positives');

    // Always return null to prevent false positives
    // In production, we need real face detection
    return null;

    // OLD PLACEHOLDER CODE (disabled):
    // This always detected a "face" in the center, causing false positives
    // final width = image.width;
    // final height = image.height;
    // final faceSize = (width * 0.6).toInt();
    // final x = (width - faceSize) ~/ 2;
    // final y = (height - faceSize) ~/ 2;
    // return FaceRect(x: x, y: y, width: faceSize, height: faceSize);
  }

  /// Check if image likely contains a face
  ///
  /// TODO: Use real face detection to validate
  Future<bool> hasFace(File imageFile) async {
    final face = await detectAndCropFace(imageFile);
    return face != null;
  }

  /// Normalize face image for model input
  ///
  /// Resize to 112x112 (MobileFaceNet input size)
  /// Normalize pixel values to [-1, 1]
  img.Image normalizeFaceForModel(img.Image face) {
    // Resize to model input size (112x112 for MobileFaceNet)
    final resized = img.copyResize(
      face,
      width: 112,
      height: 112,
      interpolation: img.Interpolation.linear,
    );

    return resized;
  }
}

/// Face bounding box
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
