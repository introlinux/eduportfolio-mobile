import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:eduportfolio/core/services/face_recognition/face_detector_service.dart';

/// Service for extracting face embeddings
///
/// This service converts face images into 128-dimensional vectors (embeddings)
/// that represent the unique characteristics of each face.
///
/// Uses MobileFaceNet model (or similar) via TFLite
class FaceEmbeddingService {
  final FaceDetectorService _faceDetector;

  // TODO: Add TFLite Interpreter
  // late Interpreter _interpreter;

  FaceEmbeddingService(this._faceDetector);

  /// Initialize the TFLite model
  ///
  /// TODO: Load MobileFaceNet model from assets
  /// assets/models/mobilefacenet.tflite
  Future<void> initialize() async {
    try {
      // TODO: Initialize TFLite interpreter
      // _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
      print('Face embedding service initialized (PLACEHOLDER MODE)');
    } catch (e) {
      print('Error initializing face embedding service: $e');
      rethrow;
    }
  }

  /// Extract embedding from face image
  ///
  /// Returns a 128-dimensional vector representing the face
  /// Returns null if extraction fails
  Future<List<double>?> extractEmbedding(img.Image faceImage) async {
    try {
      // Normalize face for model input
      final normalizedFace = _faceDetector.normalizeFaceForModel(faceImage);

      // Convert to input tensor format
      final input = _preprocessImage(normalizedFace);

      // TODO: Run inference with TFLite model
      // var output = List.filled(128, 0.0).reshape([1, 128]);
      // _interpreter.run(input, output);
      // return output[0];

      // PLACEHOLDER: Return random embedding for testing
      return _generatePlaceholderEmbedding();
    } catch (e) {
      print('Error extracting embedding: $e');
      return null;
    }
  }

  /// Preprocess image for model input
  ///
  /// MobileFaceNet expects:
  /// - Input shape: [1, 112, 112, 3]
  /// - Pixel values: normalized to [-1, 1]
  /// - Color format: RGB
  List<List<List<List<double>>>> _preprocessImage(img.Image face) {
    final input = List.generate(
      1,
      (_) => List.generate(
        112,
        (y) => List.generate(
          112,
          (x) {
            final pixel = face.getPixel(x, y);
            // Extract RGB values and normalize to [-1, 1]
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

  /// PLACEHOLDER: Generate random embedding for testing
  ///
  /// TODO: Remove when real model is integrated
  List<double> _generatePlaceholderEmbedding() {
    // Generate a consistent "embedding" based on timestamp
    // This is just for testing the infrastructure
    final seed = DateTime.now().millisecondsSinceEpoch % 1000;
    return List.generate(128, (i) => (seed + i) / 1000.0);
  }

  /// Average multiple embeddings into one
  ///
  /// Used to create a robust student profile from 5 training photos
  List<double> averageEmbeddings(List<List<double>> embeddings) {
    if (embeddings.isEmpty) {
      throw ArgumentError('Cannot average empty list of embeddings');
    }

    final embeddingSize = embeddings.first.length;
    final averaged = List<double>.filled(embeddingSize, 0.0);

    // Sum all embeddings
    for (final embedding in embeddings) {
      for (int i = 0; i < embeddingSize; i++) {
        averaged[i] += embedding[i];
      }
    }

    // Divide by count to get average
    final count = embeddings.length;
    for (int i = 0; i < embeddingSize; i++) {
      averaged[i] /= count;
    }

    return averaged;
  }

  /// Normalize embedding to unit length
  ///
  /// This improves comparison accuracy
  List<double> normalizeEmbedding(List<double> embedding) {
    // Calculate L2 norm
    double norm = 0.0;
    for (final value in embedding) {
      norm += value * value;
    }
    norm = norm.sqrt();

    // Avoid division by zero
    if (norm == 0.0) {
      return embedding;
    }

    // Normalize
    return embedding.map((value) => value / norm).toList();
  }

  /// Convert embedding to bytes for storage
  Uint8List embeddingToBytes(List<double> embedding) {
    final buffer = ByteData(embedding.length * 8); // 8 bytes per double

    for (int i = 0; i < embedding.length; i++) {
      buffer.setFloat64(i * 8, embedding[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  /// Convert bytes back to embedding
  List<double> bytesToEmbedding(Uint8List bytes) {
    final buffer = ByteData.sublistView(bytes);
    final length = bytes.length ~/ 8; // 8 bytes per double

    return List.generate(
      length,
      (i) => buffer.getFloat64(i * 8, Endian.little),
    );
  }

  /// Dispose resources
  void dispose() {
    // TODO: Close TFLite interpreter
    // _interpreter.close();
  }
}

/// Extension for sqrt on double
extension DoubleExtension on double {
  double sqrt() {
    return this < 0 ? 0 : this.toDouble().squareRoot();
  }
}

extension on double {
  double squareRoot() {
    double x = this;
    double root = this / 2;
    for (int i = 0; i < 10; i++) {
      root = (root + x / root) / 2;
    }
    return root;
  }
}
