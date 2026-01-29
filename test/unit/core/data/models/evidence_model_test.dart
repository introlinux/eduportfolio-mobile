import 'package:eduportfolio/core/data/models/evidence_model.dart';
import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EvidenceModel', () {
    final testCaptureDate = DateTime(2025, 1, 29, 14, 30);
    final testCreatedAt = DateTime(2025, 1, 29, 14, 31);

    final testEvidence = Evidence(
      id: 1,
      studentId: 5,
      subjectId: 3,
      type: EvidenceType.image,
      filePath: '/path/to/IMG_20250129_143025_MATEMATICAS.jpg',
      thumbnailPath: '/path/to/THUMB_20250129_143025_MATEMATICAS.jpg',
      fileSize: 2048000,
      captureDate: testCaptureDate,
      isReviewed: true,
      notes: 'Test note',
      createdAt: testCreatedAt,
    );

    test('should convert from entity to model', () {
      final model = EvidenceModel.fromEntity(testEvidence);

      expect(model.id, testEvidence.id);
      expect(model.studentId, testEvidence.studentId);
      expect(model.subjectId, testEvidence.subjectId);
      expect(model.type, testEvidence.type);
      expect(model.filePath, testEvidence.filePath);
      expect(model.thumbnailPath, testEvidence.thumbnailPath);
      expect(model.fileSize, testEvidence.fileSize);
      expect(model.captureDate, testEvidence.captureDate);
      expect(model.isReviewed, testEvidence.isReviewed);
      expect(model.notes, testEvidence.notes);
      expect(model.createdAt, testEvidence.createdAt);
    });

    test('should convert to map with correct EvidenceType string', () {
      final model = EvidenceModel.fromEntity(testEvidence);
      final map = model.toMap();

      expect(map['type'], 'IMG');
      expect(map['student_id'], 5);
      expect(map['subject_id'], 3);
      expect(map['file_path'], testEvidence.filePath);
      expect(map['is_reviewed'], 1);
    });

    test('should create from database map with EvidenceType conversion', () {
      final map = {
        'id': 1,
        'student_id': 5,
        'subject_id': 3,
        'type': 'VID',
        'file_path': '/path/to/video.mp4',
        'thumbnail_path': '/path/to/thumb.jpg',
        'file_size': 5000000,
        'duration': 120,
        'capture_date': testCaptureDate.toIso8601String(),
        'is_reviewed': 1,
        'notes': 'Video evidence',
        'created_at': testCreatedAt.toIso8601String(),
      };

      final model = EvidenceModel.fromMap(map);

      expect(model.type, EvidenceType.video);
      expect(model.duration, 120);
      expect(model.durationMinutes, 2.0);
    });

    test('should handle unassigned evidence (null studentId)', () {
      final unassignedEvidence = Evidence(
        id: 2,
        studentId: null,
        subjectId: 3,
        type: EvidenceType.image,
        filePath: '/path/to/unassigned.jpg',
        captureDate: testCaptureDate,
        isReviewed: false,
        createdAt: testCreatedAt,
      );

      final model = EvidenceModel.fromEntity(unassignedEvidence);
      final map = model.toMap();

      expect(map.containsKey('student_id'), false);
      expect(map['is_reviewed'], 0);
      expect(model.needsReview, true);
      expect(model.isAssigned, false);
    });

    test('should calculate file size in MB correctly', () {
      final evidence = Evidence(
        subjectId: 1,
        type: EvidenceType.image,
        filePath: '/path/file.jpg',
        fileSize: 3145728, // 3 MB
        captureDate: testCaptureDate,
        createdAt: testCreatedAt,
      );

      final model = EvidenceModel.fromEntity(evidence);

      expect(model.fileSizeMB, 3.0);
    });

    test('should parse different EvidenceType strings', () {
      expect(EvidenceType.fromString('IMG'), EvidenceType.image);
      expect(EvidenceType.fromString('VID'), EvidenceType.video);
      expect(EvidenceType.fromString('AUD'), EvidenceType.audio);
      expect(EvidenceType.fromString('IMAGE'), EvidenceType.image);
    });

    test('should throw on invalid EvidenceType string', () {
      expect(
        () => EvidenceType.fromString('INVALID'),
        throwsArgumentError,
      );
    });
  });
}
