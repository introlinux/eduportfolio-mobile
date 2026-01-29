import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Service for detecting faces in images
///
/// This service is responsible for:
/// 1. Detecting if a face exists in an image
/// 2. Extracting face bounding box coordinates
/// 3. Cropping the face region for further processing
class FaceDetectorService {
  /// Detect face in image and return cropped face
  ///
  /// Returns null if no face is detected
  /// Returns cropped face image if face is found
  Future<img.Image?> detectAndCropFace(File imageFile) async {
    try {
      // Read image file
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return null;
      }

      // TODO: Integrate real face detection model
      // For now, use a simple center crop as placeholder
      // In production, this should use ML Kit or TFLite face detection
      final faceRect = _detectFacePlaceholder(image);

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
      final image = img.decodeImage(bytes);

      if (image == null) {
        return null;
      }

      final faceRect = _detectFacePlaceholder(image);

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

  /// PLACEHOLDER: Simple face detection using center crop
  ///
  /// TODO: Replace with real face detection:
  /// - Option 1: Google ML Kit Face Detection
  /// - Option 2: TFLite face detection model (MTCNN, RetinaFace)
  /// - Option 3: OpenCV face detection
  ///
  /// Real implementation should:
  /// - Detect face landmarks (eyes, nose, mouth)
  /// - Return accurate bounding box
  /// - Handle multiple faces (return largest/closest)
  /// - Handle edge cases (side profiles, occlusions)
  FaceRect? _detectFacePlaceholder(img.Image image) {
    // Simple center crop: assume face is in center 60% of image
    final width = image.width;
    final height = image.height;

    final faceSize = (width * 0.6).toInt();
    final x = (width - faceSize) ~/ 2;
    final y = (height - faceSize) ~/ 2;

    return FaceRect(
      x: x,
      y: y,
      width: faceSize,
      height: faceSize,
    );
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
