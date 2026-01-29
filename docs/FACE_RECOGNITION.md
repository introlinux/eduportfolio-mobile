# Face Recognition System

## Overview

The face recognition system is the flagship feature of Eduportfolio, enabling automatic student identification during evidence capture. This document describes the architecture, implementation, and usage of the face recognition functionality.

## Architecture

### Services

The face recognition system consists of three core services working together:

#### 1. FaceDetectorService
**Location:** `lib/core/services/face_recognition/face_detector_service.dart`

**Responsibilities:**
- Detect faces in images
- Crop and normalize face regions to 112x112 pixels (MobileFaceNet input size)
- Handle multiple faces (returns first detected face)

**Key Methods:**
```dart
Future<void> initialize()
Future<img.Image?> detectAndCropFace(File imageFile)
```

#### 2. FaceEmbeddingService
**Location:** `lib/core/services/face_recognition/face_embedding_service.dart`

**Responsibilities:**
- Extract 128-dimensional face embeddings using MobileFaceNet
- Average multiple embeddings (for training from 5 photos)
- Normalize embeddings to unit length
- Convert embeddings to/from bytes for database storage

**Key Methods:**
```dart
Future<void> initialize()
Future<List<double>?> extractEmbedding(File imageFile)
List<double> averageEmbeddings(List<List<double>> embeddings)
List<double> normalizeEmbedding(List<double> embedding)
Uint8List embeddingToBytes(List<double> embedding)
List<double> bytesToEmbedding(Uint8List bytes)
```

#### 3. FaceRecognitionService
**Location:** `lib/core/services/face_recognition/face_recognition_service.dart`

**Responsibilities:**
- Coordinate face detection and embedding extraction
- Process training photos (5 photos → 1 averaged embedding)
- Recognize students by comparing embeddings
- Calculate similarity scores using cosine similarity

**Key Methods:**
```dart
Future<void> initialize()
Future<TrainingResult> processTrainingPhotos(List<File> photos)
Future<RecognitionResult> recognizeStudent(File image, List<Student> students)
double calculateSimilarity(List<double> embedding1, List<double> embedding2)
```

### Data Models

#### TrainingResult
```dart
class TrainingResult {
  final bool success;
  final int totalPhotos;
  final int successfulPhotos;
  final List<double>? averageEmbedding;
  final String? error;
}
```

#### RecognitionResult
```dart
class RecognitionResult {
  final bool faceDetected;
  final Student? student;
  final double confidence;
  final String? error;
}
```

### Providers

**Location:** `lib/core/services/face_recognition/face_recognition_providers.dart`

```dart
// Service providers
final faceDetectorServiceProvider
final faceEmbeddingServiceProvider
final faceRecognitionServiceProvider

// Initialization provider
final faceRecognitionInitializedProvider
```

## User Flows

### 1. Training a Student (Face Enrollment)

**Entry Point:** Student Detail Screen → "Capturar fotos de entrenamiento"

**Flow:**
1. Navigate to `FaceTrainingScreen` with student parameter
2. Request camera permission
3. Initialize front-facing camera
4. Capture 5 photos with different poses:
   - Photo 1: Face forward, centered
   - Photo 2: Turn slightly left
   - Photo 3: Turn slightly right
   - Photo 4: Tilt head up
   - Photo 5: Face forward again
5. Process photos automatically:
   - Detect and crop faces
   - Extract 128D embeddings
   - Average embeddings
   - Normalize to unit length
6. Update student record with face embeddings
7. Return to Student Detail Screen

**Visual Feedback:**
- Progress bar showing N/5 photos
- Instructions for each pose
- Undo button to remove last photo
- Processing screen during embedding extraction

**Code Reference:**
- Screen: `lib/features/students/presentation/screens/face_training_screen.dart`
- Integration: `lib/features/students/presentation/screens/student_detail_screen.dart:232-262`

### 2. Automatic Recognition During Capture

**Entry Point:** Home Screen → Quick Capture (Subject Card)

**Flow:**
1. Navigate to `QuickCaptureScreen` with subject
2. Initialize back-facing camera
3. Capture photo
4. Perform face recognition:
   - Get active course
   - Filter students with face data from active course
   - Detect face in captured image
   - Extract embedding
   - Compare with all students' embeddings
   - Return match if confidence > 0.6 (60% similarity)
5. Show preview with recognition result:
   - Green border + student name if recognized
   - Orange border if no match
6. Auto-save evidence (2 second delay)
7. Auto-assign to recognized student if match found

**Visual Feedback:**
- Recognition banner showing student name (green)
- Colored border (green = recognized, orange = no match)
- Success message with student name
- Running count of captured evidences

**Code Reference:**
- Screen: `lib/features/capture/presentation/screens/quick_capture_screen.dart`
- Recognition method: `_performFaceRecognition()` (line 155)
- Preview UI: `_buildPreview()` (line 427)

## Technical Details

### Face Embedding Model

**Model:** MobileFaceNet
- **Input:** 112x112x3 RGB images
- **Output:** 128-dimensional embeddings
- **Format:** TensorFlow Lite (.tflite)
- **Size:** ~3.8 MB

**Why MobileFaceNet?**
- Optimized for mobile devices
- Good accuracy/speed tradeoff
- Small model size
- Low memory footprint

### Similarity Calculation

**Algorithm:** Cosine similarity converted to [0, 1] range

```dart
double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
  double dotProduct = 0.0;
  for (int i = 0; i < embedding1.length; i++) {
    dotProduct += embedding1[i] * embedding2[i];
  }
  // Convert cosine similarity [-1, 1] to [0, 1]
  return (dotProduct + 1.0) / 2.0;
}
```

**Threshold:** 0.6 (60% similarity)
- Above 0.6: Match considered valid
- Below 0.6: No match, evidence not auto-assigned

### Database Schema

**Student Table Extension:**
```sql
CREATE TABLE students (
  id INTEGER PRIMARY KEY,
  course_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  face_embeddings BLOB,  -- 128 floats × 4 bytes = 512 bytes
  has_face_data INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (course_id) REFERENCES courses (id)
);
```

**Storage:**
- Embeddings stored as BLOB (binary large object)
- 128 double values × 4 bytes = 512 bytes per student
- Converted using Float32List for efficient storage

## Placeholder Mode

**Current Status:** The system is implemented with placeholder embeddings for testing.

**Placeholder Behavior:**
- Face detection: Returns center crop of image
- Embedding extraction: Returns random normalized 128D vectors
- Similarity: Always returns high similarity (0.75) for first student
- Training: Successfully processes photos without real model

**Purpose:**
- Test complete infrastructure without TFLite model
- Verify UI flows and user experience
- Validate database schema and data flow
- Enable development without model dependency

**Next Steps:**
1. Add real MobileFaceNet .tflite model to assets
2. Update FaceDetectorService to use Google ML Kit
3. Update FaceEmbeddingService to use TFLite interpreter
4. Adjust similarity threshold based on real model performance
5. Add face quality validation (blur, lighting, angle)

## Error Handling

### Training Errors

**No camera permission:**
- Show error screen with "Open Settings" button
- Retry button to reinitialize camera

**No camera found:**
- Show error message
- Suggest checking device hardware

**Photo capture failed:**
- Show error snackbar
- Allow retry without losing progress
- Photos already captured are preserved

**Processing failed:**
- Show error message with details
- Clean up temporary files
- Return to Student Detail Screen
- Student face data not modified

### Recognition Errors

**No active course:**
- Skip recognition silently
- Evidence saved without student assignment
- No error shown to user

**No students with face data:**
- Skip recognition silently
- Evidence saved normally

**Face detection failed:**
- Log error with debugPrint
- Continue with capture
- Evidence saved without assignment

**Service initialization failed:**
- Recognition skipped
- User can still capture evidences manually

## Performance Considerations

### Initialization
- Services initialized once on first use
- Lazy initialization via providers
- ~100-200ms for model loading (placeholder mode)

### Training (5 photos)
- **Current (placeholder):** ~500ms total
- **Expected (real model):** ~2-3 seconds total
- Processing screen shown during operation
- Background processing, UI remains responsive

### Recognition (per capture)
- **Current (placeholder):** ~200ms
- **Expected (real model):** ~500-800ms
- Does not block capture flow
- Preview shows immediately, recognition in background
- 2-second delay before auto-save allows recognition to complete

### Memory Usage
- **Model in memory:** ~5 MB (loaded once)
- **Per image processing:** ~2-3 MB temporary
- **Stored per student:** 512 bytes (embeddings)
- Temporary files cleaned up immediately after processing

## Privacy & Security

### Data Storage
- Face embeddings stored as binary data (not images)
- Cannot reconstruct original photos from embeddings
- Training photos deleted immediately after processing
- No face photos stored permanently

### Scope
- Only students from active course are searched
- Recognition limited to enrolled students
- No external API calls or cloud processing
- All processing done locally on device

### User Control
- Face recognition is optional per student
- Can be disabled by not capturing training photos
- Students can be deleted, removing all face data
- Training can be redone anytime (replaces old data)

## Testing

**Test Suite:** `test/unit/core/services/face_recognition/face_recognition_services_test.dart`

**Coverage:**
- Service initialization
- Embedding normalization
- Embedding averaging
- Byte conversion
- Similarity calculation
- Training photo processing
- Student recognition
- Edge cases (empty lists, missing data)
- Integration test (full workflow)

**Run tests:**
```bash
flutter test test/unit/core/services/face_recognition/
```

## Future Enhancements

### Short Term
1. Add real MobileFaceNet model
2. Implement face quality checks
3. Add confidence indicator in UI
4. Allow manual student selection override
5. Add training photo preview before processing

### Medium Term
1. Multiple faces detection (group photos)
2. Face tracking for better capture guidance
3. Training photo count recommendations
4. Recognition history/logs
5. Confidence threshold configuration

### Long Term
1. Live face detection during training
2. Anti-spoofing (liveness detection)
3. Expression-invariant recognition
4. Age-invariant recognition (same student, different years)
5. Similarity-based duplicate detection

## Dependencies

```yaml
dependencies:
  # Image processing
  image: ^4.3.0

  # Machine learning (ready for real model)
  tflite_flutter: ^0.11.0

  # Camera
  camera: ^0.11.0+2

  # Utilities
  path_provider: ^2.1.5
```

## References

- **MobileFaceNet Paper:** "MobileFaceNets: Efficient CNNs for Accurate Real-time Face Verification on Mobile Devices"
- **TFLite Flutter:** https://pub.dev/packages/tflite_flutter
- **Face Recognition Best Practices:** Use minimum 3-5 photos for training, varied poses and lighting

## Support

For issues or questions about face recognition:
1. Check this documentation
2. Review test suite for examples
3. Check placeholder mode implementation
4. Verify camera permissions
5. Ensure active course is set
