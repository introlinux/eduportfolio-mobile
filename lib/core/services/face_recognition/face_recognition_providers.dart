import 'package:eduportfolio/core/services/face_recognition/face_detector_service.dart';
import 'package:eduportfolio/core/services/face_recognition/face_embedding_service.dart';
import 'package:eduportfolio/core/services/face_recognition/face_recognition_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// FACE RECOGNITION SERVICE PROVIDERS
// ============================================================================

/// Provider for FaceDetectorService
final faceDetectorServiceProvider = Provider<FaceDetectorService>((ref) {
  return FaceDetectorService();
});

/// Provider for FaceEmbeddingService
final faceEmbeddingServiceProvider = Provider<FaceEmbeddingService>((ref) {
  final detector = ref.watch(faceDetectorServiceProvider);
  return FaceEmbeddingService(detector);
});

/// Provider for FaceRecognitionService (main service)
final faceRecognitionServiceProvider =
    Provider<FaceRecognitionService>((ref) {
  final detector = ref.watch(faceDetectorServiceProvider);
  final embedding = ref.watch(faceEmbeddingServiceProvider);
  return FaceRecognitionService(detector, embedding);
});

/// Provider to initialize face recognition service
final faceRecognitionInitializedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(faceRecognitionServiceProvider);
  await service.initialize();
  return true;
});
