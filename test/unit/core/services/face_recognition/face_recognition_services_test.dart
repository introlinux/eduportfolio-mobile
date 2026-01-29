import 'dart:io';

import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/services/face_recognition/face_detector_service.dart';
import 'package:eduportfolio/core/services/face_recognition/face_embedding_service.dart';
import 'package:eduportfolio/core/services/face_recognition/face_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FaceDetectorService', () {
    late FaceDetectorService service;

    setUp(() {
      service = FaceDetectorService();
    });

    test('should be initialized', () {
      expect(service, isNotNull);
    });

    test('initialize should complete without error', () async {
      await expectLater(service.initialize(), completes);
    });

    // Note: Actual face detection tests require real images
    // These tests verify the service structure in placeholder mode
  });

  group('FaceEmbeddingService', () {
    late FaceDetectorService detector;
    late FaceEmbeddingService service;

    setUp(() {
      detector = FaceDetectorService();
      service = FaceEmbeddingService(detector);
    });

    test('should be initialized', () {
      expect(service, isNotNull);
    });

    test('initialize should complete without error', () async {
      await detector.initialize();
      await expectLater(service.initialize(), completes);
    });

    test('should normalize embeddings to unit length', () {
      final embedding = [3.0, 4.0]; // Length = 5.0
      final normalized = service.normalizeEmbedding(embedding);

      // Check unit length (length should be 1.0)
      final length = normalized.fold(
        0.0,
        (sum, val) => sum + (val * val),
      );
      expect(length, closeTo(1.0, 0.0001));
    });

    test('should average multiple embeddings correctly', () {
      final embeddings = [
        [1.0, 2.0, 3.0],
        [3.0, 4.0, 5.0],
        [5.0, 6.0, 7.0],
      ];

      final averaged = service.averageEmbeddings(embeddings);

      expect(averaged.length, equals(3));
      expect(averaged[0], equals(3.0)); // (1+3+5)/3
      expect(averaged[1], equals(4.0)); // (2+4+6)/3
      expect(averaged[2], equals(5.0)); // (3+5+7)/3
    });

    test('should convert embeddings to bytes and back', () {
      final originalEmbedding = [0.5, -0.3, 0.8, -0.1];

      final bytes = service.embeddingToBytes(originalEmbedding);
      expect(bytes, isNotNull);
      expect(bytes.length, equals(originalEmbedding.length * 4)); // 4 bytes per float

      final recovered = service.bytesToEmbedding(bytes);
      expect(recovered.length, equals(originalEmbedding.length));

      // Check values are approximately equal (floating point precision)
      for (int i = 0; i < originalEmbedding.length; i++) {
        expect(recovered[i], closeTo(originalEmbedding[i], 0.0001));
      }
    });

    test('should handle empty embeddings list gracefully', () {
      expect(
        () => service.averageEmbeddings([]),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('FaceRecognitionService', () {
    late FaceDetectorService detector;
    late FaceEmbeddingService embedding;
    late FaceRecognitionService service;

    setUp(() {
      detector = FaceDetectorService();
      embedding = FaceEmbeddingService(detector);
      service = FaceRecognitionService(detector, embedding);
    });

    test('should be initialized', () {
      expect(service, isNotNull);
    });

    test('initialize should complete without error', () async {
      await expectLater(service.initialize(), completes);
    });

    test('should calculate similarity correctly', () {
      // Identical embeddings should have similarity = 1.0
      final embedding1 = [1.0, 0.0, 0.0];
      final identicalScore = service.calculateSimilarity(embedding1, embedding1);
      expect(identicalScore, closeTo(1.0, 0.0001));

      // Orthogonal embeddings should have similarity = 0.5 (cosine = 0)
      final embedding2 = [1.0, 0.0, 0.0];
      final embedding3 = [0.0, 1.0, 0.0];
      final orthogonalScore = service.calculateSimilarity(embedding2, embedding3);
      expect(orthogonalScore, closeTo(0.5, 0.0001));

      // Opposite embeddings should have similarity = 0.0 (cosine = -1)
      final embedding4 = [1.0, 0.0, 0.0];
      final embedding5 = [-1.0, 0.0, 0.0];
      final oppositeScore = service.calculateSimilarity(embedding4, embedding5);
      expect(oppositeScore, closeTo(0.0, 0.0001));
    });

    test('should process training photos and return result', () async {
      // Create mock training photos (empty files for testing structure)
      final tempDir = Directory.systemTemp.createTempSync('face_test_');
      final photos = List.generate(
        5,
        (i) => File('${tempDir.path}/photo_$i.jpg')..createSync(),
      );

      try {
        final result = await service.processTrainingPhotos(photos);

        expect(result, isNotNull);
        expect(result.success, isA<bool>());
        expect(result.totalPhotos, equals(5));
        expect(result.successfulPhotos, greaterThanOrEqualTo(0));

        // In placeholder mode, we expect success with placeholder embeddings
        expect(result.success, isTrue);
        expect(result.averageEmbedding, isNotNull);
        expect(result.averageEmbedding!.length, equals(128));
      } finally {
        // Cleanup
        for (final photo in photos) {
          if (photo.existsSync()) photo.deleteSync();
        }
        tempDir.deleteSync();
      }
    });

    test('should recognize student from list', () async {
      // Create a mock image file
      final tempDir = Directory.systemTemp.createTempSync('face_test_');
      final imageFile = File('${tempDir.path}/test.jpg')..createSync();

      try {
        // Create mock students with placeholder embeddings
        final students = [
          Student(
            id: 1,
            courseId: 1,
            name: 'Student 1',
            hasFaceData: true,
            faceEmbeddings: List.generate(128, (i) => 0.5),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Student(
            id: 2,
            courseId: 1,
            name: 'Student 2',
            hasFaceData: true,
            faceEmbeddings: List.generate(128, (i) => -0.5),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final result = await service.recognizeStudent(imageFile, students);

        expect(result, isNotNull);
        expect(result.faceDetected, isA<bool>());

        // In placeholder mode, we expect a match (placeholder always matches first)
        expect(result.student, isNotNull);
        expect(result.confidence, greaterThanOrEqualTo(0.0));
        expect(result.confidence, lessThanOrEqualTo(1.0));
      } finally {
        // Cleanup
        if (imageFile.existsSync()) imageFile.deleteSync();
        tempDir.deleteSync();
      }
    });

    test('should handle empty student list', () async {
      final tempDir = Directory.systemTemp.createTempSync('face_test_');
      final imageFile = File('${tempDir.path}/test.jpg')..createSync();

      try {
        final result = await service.recognizeStudent(imageFile, []);

        expect(result, isNotNull);
        expect(result.student, isNull);
      } finally {
        // Cleanup
        if (imageFile.existsSync()) imageFile.deleteSync();
        tempDir.deleteSync();
      }
    });

    test('should handle students without face data', () async {
      final tempDir = Directory.systemTemp.createTempSync('face_test_');
      final imageFile = File('${tempDir.path}/test.jpg')..createSync();

      try {
        final students = [
          Student(
            id: 1,
            courseId: 1,
            name: 'Student 1',
            hasFaceData: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final result = await service.recognizeStudent(imageFile, students);

        expect(result, isNotNull);
        expect(result.student, isNull);
      } finally {
        // Cleanup
        if (imageFile.existsSync()) imageFile.deleteSync();
        tempDir.deleteSync();
      }
    });
  });

  group('Integration Tests', () {
    late FaceDetectorService detector;
    late FaceEmbeddingService embedding;
    late FaceRecognitionService recognition;

    setUp(() async {
      detector = FaceDetectorService();
      embedding = FaceEmbeddingService(detector);
      recognition = FaceRecognitionService(detector, embedding);

      await detector.initialize();
      await embedding.initialize();
      await recognition.initialize();
    });

    test('full workflow: train and recognize', () async {
      final tempDir = Directory.systemTemp.createTempSync('face_test_');

      try {
        // Step 1: Create training photos
        final trainingPhotos = List.generate(
          5,
          (i) => File('${tempDir.path}/training_$i.jpg')..createSync(),
        );

        // Step 2: Process training photos
        final trainingResult = await recognition.processTrainingPhotos(
          trainingPhotos,
        );

        expect(trainingResult.success, isTrue);
        expect(trainingResult.averageEmbedding, isNotNull);

        // Step 3: Create student with embeddings
        final student = Student(
          id: 1,
          courseId: 1,
          name: 'Test Student',
          hasFaceData: true,
          faceEmbeddings: trainingResult.averageEmbedding,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Step 4: Create test image for recognition
        final testImage = File('${tempDir.path}/test.jpg')..createSync();

        // Step 5: Recognize student
        final recognitionResult = await recognition.recognizeStudent(
          testImage,
          [student],
        );

        expect(recognitionResult.faceDetected, isTrue);
        expect(recognitionResult.student, isNotNull);
        expect(recognitionResult.student!.id, equals(1));
        expect(recognitionResult.confidence, greaterThan(0.0));
      } finally {
        // Cleanup
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
