import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:eduportfolio/core/services/face_recognition/face_detector_service.dart';

/// Service for extracting face embeddings
///
/// This service converts face images into 192-dimensional vectors (embeddings)
/// that represent the unique characteristics of each face.
///
/// Uses MobileFaceNet model (or similar) via TFLite
/// NOTE: This model outputs 192D embeddings (not the standard 128D)
class FaceEmbeddingService {
  final FaceDetectorService _faceDetector;

  /// TFLite interpreter for MobileFaceNet model
  Interpreter? _interpreter;

  FaceEmbeddingService(this._faceDetector);

  /// Initialize the TFLite model
  ///
  /// Loads MobileFaceNet model from assets
  Future<void> initialize() async {
    print('========================================');
    print('Initializing FaceEmbeddingService...');
    print('========================================');
    try {
      print('Loading MobileFaceNet model from assets...');

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
        'assets/models/mobilefacenet.tflite',
        options: options,
      );

      print('✓ MobileFaceNet model loaded successfully');

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      print('✓ Model shapes verified:');
      print('  - Input: $inputShape (expected: [1, 112, 112, 3])');
      print('  - Output: $outputShape (expected: [1, 192])');

      // Verify correct dimensions
      if (inputShape[1] != 112 || inputShape[2] != 112) {
        throw Exception('Invalid model: Expected 112x112 input, got ${inputShape[1]}x${inputShape[2]}');
      }
      if (outputShape[1] != 192) {
        throw Exception('Invalid model: Expected 192D output, got ${outputShape[1]}D');
      }

      print('✓ MobileFaceNet ready for embedding extraction');
      print('✓ GPU acceleration: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Not available"}');
      print('========================================');
    } catch (e, stackTrace) {
      print('========================================');
      print('✗ ERROR loading MobileFaceNet model');
      print('✗ Error type: ${e.runtimeType}');
      print('✗ Error details: $e');
      print('✗ Stack trace (first 5 lines):');
      final stackLines = stackTrace.toString().split('\n').take(5);
      for (final line in stackLines) {
        print('  $line');
      }
      print('✗ Embedding extraction will FAIL (returns null)');
      print('✗ Please verify:');
      print('  1. File exists: assets/models/mobilefacenet.tflite');
      print('  2. pubspec.yaml includes: assets/models/');
      print('  3. Run: flutter clean && flutter pub get');
      print('  4. Check if tflite_flutter plugin installed correctly');
      print('========================================');
      // Don't rethrow - allow graceful degradation
    }
  }

  /// Extract embedding from face image
  ///
  /// Returns a 192-dimensional vector representing the face
  /// Returns null if extraction fails
  Future<List<double>?> extractEmbedding(img.Image faceImage) async {
    if (_interpreter == null) {
      print('MobileFaceNet not initialized, using placeholder');
      return _generatePlaceholderEmbedding();
    }

    try {
      // Normalize face for model input (already 112x112 from detector)
      final normalizedFace = _faceDetector.normalizeFaceForModel(faceImage);

      // Convert to input tensor [1, 112, 112, 3]
      // _preprocessImage() is already correctly implemented
      final input = _preprocessImage(normalizedFace);

      // Prepare output tensor [1, 192] (this model outputs 192D embeddings)
      var output = List.generate(1, (_) => List.filled(192, 0.0));

      // Run inference
      _interpreter!.run(input, output);

      // Extract embedding
      final embedding = output[0];

      // Verify that embedding is not all zeros
      final sum = embedding.fold(0.0, (a, b) => a + b.abs());
      if (sum == 0.0) {
        print('Warning: Extracted all-zero embedding');
        return null;
      }

      print('Extracted embedding: first 5 values = [${embedding.take(5).map((v) => v.toStringAsFixed(3)).join(", ")}]');

      return embedding;
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
    return List.generate(192, (i) => (seed + i) / 1000.0);
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
    _interpreter?.close();
    _interpreter = null;
    print('Face embedding service disposed');
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
