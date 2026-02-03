import 'dart:io';
import 'dart:math';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/services/face_recognition/face_detector_service.dart';
import 'package:eduportfolio/core/services/face_recognition/face_embedding_service.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Main face recognition service
///
/// Coordinates face detection, embedding extraction, and comparison
/// to recognize students from photos
class FaceRecognitionService {
  final FaceDetectorService _faceDetector;
  final FaceEmbeddingService _embeddingService;

  /// Similarity threshold for face matching (0.0 to 1.0)
  /// Higher = more strict matching
  /// 0.70 allows recognition with normal variations (lighting, angle, expression)
  /// while maintaining reasonable accuracy
  static const double similarityThreshold = 0.70;

  FaceRecognitionService(this._faceDetector, this._embeddingService);

  /// Initialize the service
  Future<void> initialize() async {
    print('');
    print('╔════════════════════════════════════════╗');
    print('║  FACE RECOGNITION SERVICE STARTUP     ║');
    print('╚════════════════════════════════════════╝');
    print('Initializing face recognition models...');
    print('');

    await _faceDetector.initialize();
    await _embeddingService.initialize();

    print('');
    print('╔════════════════════════════════════════╗');
    print('║  FACE RECOGNITION SERVICE READY        ║');
    print('╚════════════════════════════════════════╝');
    print('');
  }

  /// Recognize student from image
  ///
  /// Compares the face in the image against all students with face data
  /// Returns the student if a match is found (similarity > threshold)
  /// Returns null if no match or no face detected
  Future<RecognitionResult?> recognizeStudent(
    File imageFile,
    List<Student> studentsWithFaceData,
  ) async {
    try {
      // Step 1: Detect and crop face
      final face = await _faceDetector.detectAndCropFace(imageFile);
      if (face == null) {
        return RecognitionResult.noFaceDetected();
      }

      // Step 2: Extract embedding
      final embedding = await _embeddingService.extractEmbedding(face);
      if (embedding == null) {
        return RecognitionResult.extractionFailed();
      }

      // Step 3: Normalize embedding
      final normalizedEmbedding =
          _embeddingService.normalizeEmbedding(embedding);

      // Step 4: Compare with all students
      Student? bestMatch;
      double bestSimilarity = 0.0;

      for (final student in studentsWithFaceData) {
        if (student.faceEmbeddings == null) continue;

        // Convert stored bytes to embedding
        final studentEmbedding =
            _embeddingService.bytesToEmbedding(student.faceEmbeddings!);

        // Calculate similarity
        final similarity = calculateSimilarity(
          normalizedEmbedding,
          studentEmbedding,
        );

        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
          bestMatch = student;
        }
      }

      // Step 5: Check if best match exceeds threshold
      if (bestMatch != null && bestSimilarity >= similarityThreshold) {
        return RecognitionResult.recognized(
          student: bestMatch,
          confidence: bestSimilarity,
        );
      }

      return RecognitionResult.noMatch(confidence: bestSimilarity);
    } catch (e) {
      print('Error recognizing student: $e');
      return RecognitionResult.error(e.toString());
    }
  }

  /// Recognize student from image already in memory (OPTIMIZED)
  ///
  /// This method is optimized for camera stream images that are already
  /// processed and rotated in memory. It avoids:
  /// - File I/O (no JPEG encoding/decoding)
  /// - Android orientation workaround (image already correctly oriented)
  ///
  /// Use this for live recognition from camera stream.
  /// Use recognizeStudent() for images loaded from disk.
  Future<RecognitionResult?> recognizeStudentFromImage(
    img.Image image,
    List<Student> studentsWithFaceData,
  ) async {
    try {
      debugPrint('');
      debugPrint('🔍 RECOGNITION FROM IMAGE STARTED');
      debugPrint('  - Image size: ${image.width}x${image.height}');
      debugPrint('  - Students to compare: ${studentsWithFaceData.length}');

      // Step 1: Detect face from image (no file I/O)
      debugPrint('  - Step 1: Detecting face...');
      final detection = await _faceDetector.detectFaceFromImage(image);
      if (detection == null) {
        debugPrint('  ❌ No face detected');
        return RecognitionResult.noFaceDetected();
      }
      debugPrint('  ✅ Face detected: ${detection.box}');

      // Step 2: Crop face using detection (no orientation workaround)
      debugPrint('  - Step 2: Cropping face...');
      final face = await _faceDetector.cropFaceWithDetection(image, detection);
      if (face == null) {
        debugPrint('  ❌ Face crop failed');
        return RecognitionResult.noFaceDetected();
      }
      debugPrint('  ✅ Face cropped: ${face.width}x${face.height}');

      // Step 3: Extract embedding
      debugPrint('  - Step 3: Extracting embedding...');
      final embedding = await _embeddingService.extractEmbedding(face);
      if (embedding == null) {
        debugPrint('  ❌ Embedding extraction failed');
        return RecognitionResult.extractionFailed();
      }
      debugPrint('  ✅ Embedding extracted: ${embedding.length} dimensions');
      debugPrint('  - First 5 values: ${embedding.take(5).toList()}');

      // Step 4: Normalize embedding
      debugPrint('  - Step 4: Normalizing embedding...');
      final normalizedEmbedding =
          _embeddingService.normalizeEmbedding(embedding);
      debugPrint('  ✅ Embedding normalized');
      debugPrint('  - First 5 normalized: ${normalizedEmbedding.take(5).toList()}');

      // Step 5: Compare with all students
      debugPrint('  - Step 5: Comparing with ${studentsWithFaceData.length} students...');
      Student? bestMatch;
      double bestSimilarity = 0.0;

      for (final student in studentsWithFaceData) {
        if (student.faceEmbeddings == null) continue;

        // Convert stored bytes to embedding
        final studentEmbedding =
            _embeddingService.bytesToEmbedding(student.faceEmbeddings!);

        // Calculate similarity
        final similarity = calculateSimilarity(
          normalizedEmbedding,
          studentEmbedding,
        );

        debugPrint('    - ${student.name}: similarity = ${similarity.toStringAsFixed(4)}');

        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
          bestMatch = student;
        }
      }

      debugPrint('');
      debugPrint('  📊 BEST MATCH: ${bestMatch?.name ?? "none"}');
      debugPrint('  📊 SIMILARITY: ${bestSimilarity.toStringAsFixed(4)}');
      debugPrint('  📊 THRESHOLD: ${similarityThreshold.toStringAsFixed(4)}');

      // Step 6: Check if best match exceeds threshold
      if (bestMatch != null && bestSimilarity >= similarityThreshold) {
        debugPrint('  ✅ RECOGNIZED: ${bestMatch.name}');
        debugPrint('');
        return RecognitionResult.recognized(
          student: bestMatch,
          confidence: bestSimilarity,
          debugCroppedFace: face,
        );
      }

      debugPrint('  ❌ NO MATCH (similarity too low)');
      debugPrint('');
      return RecognitionResult.noMatch(
        confidence: bestSimilarity,
        debugCroppedFace: face,
      );
    } catch (e) {
      debugPrint('  ❌ ERROR: $e');
      debugPrint('');
      return RecognitionResult.error(e.toString());
    }
  }

  /// Calculate similarity between two embeddings
  ///
  /// Uses cosine similarity (1.0 = identical, 0.0 = completely different)
  /// Alternative: Euclidean distance (lower = more similar)
  double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have same length');
    }

    // Cosine similarity: dot product of normalized vectors
    double dotProduct = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
    }

    // Cosine similarity is already in range [-1, 1]
    // Convert to [0, 1] for easier threshold comparison
    return (dotProduct + 1.0) / 2.0;
  }

  /// Alternative: Calculate Euclidean distance
  ///
  /// Lower distance = more similar
  /// Typical threshold: < 1.0 for match
  double calculateEuclideanDistance(
    List<double> embedding1,
    List<double> embedding2,
  ) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have same length');
    }

    double sum = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      final diff = embedding1[i] - embedding2[i];
      sum += diff * diff;
    }

    return sqrt(sum);
  }

  /// Process training photos and generate student embedding
  ///
  /// Takes 5 photos, extracts embeddings, averages them
  /// Returns the averaged embedding as bytes for storage
  Future<TrainingResult> processTrainingPhotos(List<File> photos) async {
    if (photos.length != 5) {
      return TrainingResult.error('Exactly 5 photos required');
    }

    final embeddings = <List<double>>[];
    final failedPhotos = <int>[];

    // Process each photo
    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];

      // Detect face
      final face = await _faceDetector.detectAndCropFace(photo);
      if (face == null) {
        failedPhotos.add(i + 1);
        continue;
      }

      // Extract embedding
      final embedding = await _embeddingService.extractEmbedding(face);
      if (embedding == null) {
        failedPhotos.add(i + 1);
        continue;
      }

      embeddings.add(embedding);
    }

    // Check if we have enough valid embeddings
    if (embeddings.length < 3) {
      return TrainingResult.error(
        'Too many failed photos. Failed: ${failedPhotos.join(", ")}',
      );
    }

    // Average embeddings
    debugPrint('📊 Averaging ${embeddings.length} embeddings...');
    final averagedEmbedding = _embeddingService.averageEmbeddings(embeddings);
    debugPrint('  - First 5 averaged values: ${averagedEmbedding.take(5).toList()}');

    // Normalize
    debugPrint('📊 Normalizing averaged embedding...');
    final normalizedEmbedding =
        _embeddingService.normalizeEmbedding(averagedEmbedding);
    debugPrint('  - First 5 normalized values: ${normalizedEmbedding.take(5).toList()}');

    // Convert to bytes for storage
    final embeddingBytes =
        _embeddingService.embeddingToBytes(normalizedEmbedding);
    debugPrint('📊 Embedding converted to ${embeddingBytes.length} bytes for storage');

    return TrainingResult.success(
      embeddingBytes: embeddingBytes,
      successfulPhotos: embeddings.length,
      failedPhotos: failedPhotos,
    );
  }

  /// Process training photos with pre-computed detections (OPTIMIZED)
  ///
  /// Takes 5 images in memory and their detection results, extracts embeddings, averages them
  /// Skips face re-detection AND disk I/O since images are already processed in memory
  /// Returns the averaged embedding as bytes for storage
  ///
  /// This is ~10x faster than processTrainingPhotos since it avoids redundant detection + I/O
  Future<TrainingResult> processTrainingPhotosWithDetections(
    List<img.Image> images,
    List<FaceDetectionResult> detections,
  ) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('🔥 OPTIMIZED TRAINING: Using images in memory (NO disk I/O)');
    debugPrint('═══════════════════════════════════════════════════');
    final startTime = DateTime.now();

    if (images.length != 5) {
      return TrainingResult.error('Exactly 5 photos required');
    }

    if (images.length != detections.length) {
      return TrainingResult.error('Photos and detections count mismatch');
    }

    final embeddings = <List<double>>[];
    final failedPhotos = <int>[];

    // Process each photo with its pre-computed detection
    for (int i = 0; i < images.length; i++) {
      debugPrint('');
      debugPrint('📷 Processing photo ${i + 1}/5...');
      final photoStartTime = DateTime.now();

      final image = images[i];
      final detection = detections[i];

      // Crop face using pre-computed detection (NO detection, NO I/O!)
      final face = await _faceDetector.cropFaceWithDetection(image, detection);
      if (face == null) {
        debugPrint('❌ Photo ${i + 1} failed to crop');
        failedPhotos.add(i + 1);
        continue;
      }

      // Extract embedding
      debugPrint('  - Extracting embedding...');
      final embeddingStartTime = DateTime.now();
      final embedding = await _embeddingService.extractEmbedding(face);
      final embeddingDuration = DateTime.now().difference(embeddingStartTime);
      debugPrint('  - Embedding extracted in ${embeddingDuration.inMilliseconds}ms');

      if (embedding == null) {
        debugPrint('❌ Photo ${i + 1} failed to extract embedding');
        failedPhotos.add(i + 1);
        continue;
      }

      embeddings.add(embedding);

      final photoDuration = DateTime.now().difference(photoStartTime);
      debugPrint('✅ Photo ${i + 1} completed in ${photoDuration.inMilliseconds}ms');
    }

    // Check if we have enough valid embeddings
    if (embeddings.length < 3) {
      return TrainingResult.error(
        'Too many failed photos. Failed: ${failedPhotos.join(", ")}',
      );
    }

    debugPrint('');
    debugPrint('📊 Averaging ${embeddings.length} embeddings...');
    // Average embeddings
    final averagedEmbedding = _embeddingService.averageEmbeddings(embeddings);

    // Normalize
    final normalizedEmbedding =
        _embeddingService.normalizeEmbedding(averagedEmbedding);

    // Convert to bytes for storage
    final embeddingBytes =
        _embeddingService.embeddingToBytes(normalizedEmbedding);

    final totalDuration = DateTime.now().difference(startTime);
    debugPrint('');
    debugPrint('✅ TRAINING COMPLETED in ${totalDuration.inSeconds}.${totalDuration.inMilliseconds % 1000}s');
    debugPrint('   - Successful: ${embeddings.length}/5 photos');
    debugPrint('   - Failed: ${failedPhotos.isEmpty ? "none" : failedPhotos.join(", ")}');
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('');

    return TrainingResult.success(
      embeddingBytes: embeddingBytes,
      successfulPhotos: embeddings.length,
      failedPhotos: failedPhotos,
    );
  }

  /// Dispose resources
  void dispose() {
    _faceDetector.dispose();
    _embeddingService.dispose();
  }
}

/// Result of face recognition attempt
class RecognitionResult {
  final RecognitionStatus status;
  final Student? student;
  final double confidence;
  final String? error;
  final img.Image? debugCroppedFace;

  RecognitionResult._({
    required this.status,
    this.student,
    this.confidence = 0.0,
    this.error,
    this.debugCroppedFace,
  });

  factory RecognitionResult.recognized({
    required Student student,
    required double confidence,
    img.Image? debugCroppedFace,
  }) {
    return RecognitionResult._(
      status: RecognitionStatus.recognized,
      student: student,
      confidence: confidence,
      debugCroppedFace: debugCroppedFace,
    );
  }

  factory RecognitionResult.noMatch({
    double confidence = 0.0,
    img.Image? debugCroppedFace,
  }) {
    return RecognitionResult._(
      status: RecognitionStatus.noMatch,
      confidence: confidence,
      debugCroppedFace: debugCroppedFace,
    );
  }

  factory RecognitionResult.noFaceDetected() {
    return RecognitionResult._(status: RecognitionStatus.noFaceDetected);
  }

  factory RecognitionResult.extractionFailed({img.Image? debugCroppedFace}) {
    return RecognitionResult._(
      status: RecognitionStatus.extractionFailed,
      debugCroppedFace: debugCroppedFace,
    );
  }

  factory RecognitionResult.error(String error) {
    return RecognitionResult._(
      status: RecognitionStatus.error,
      error: error,
    );
  }

  bool get isRecognized => status == RecognitionStatus.recognized;
  bool get hasError => status == RecognitionStatus.error;
}

enum RecognitionStatus {
  recognized,
  noMatch,
  noFaceDetected,
  extractionFailed,
  error,
}

/// Result of training photo processing
class TrainingResult {
  final bool success;
  final String? error;
  final List<int> embeddingBytes;
  final int successfulPhotos;
  final List<int> failedPhotos;

  TrainingResult._({
    required this.success,
    this.error,
    this.embeddingBytes = const [],
    this.successfulPhotos = 0,
    this.failedPhotos = const [],
  });

  factory TrainingResult.success({
    required List<int> embeddingBytes,
    required int successfulPhotos,
    required List<int> failedPhotos,
  }) {
    return TrainingResult._(
      success: true,
      embeddingBytes: embeddingBytes,
      successfulPhotos: successfulPhotos,
      failedPhotos: failedPhotos,
    );
  }

  factory TrainingResult.error(String error) {
    return TrainingResult._(
      success: false,
      error: error,
    );
  }
}
