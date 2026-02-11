/// Synchronization models and DTOs for mobile-desktop sync
///
/// This file contains all the data models used for synchronization between
/// the mobile app and the desktop application.
library;

import 'dart:convert';
import 'dart:typed_data';

/// System information from desktop server
class SystemInfo {
  final String ip;
  final int port;
  final String status;

  const SystemInfo({
    required this.ip,
    required this.port,
    required this.status,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) {
    return SystemInfo(
      ip: json['ip'] as String,
      port: json['port'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'port': port,
      'status': status,
    };
  }
}

/// Synchronization status enum
enum SyncStatus {
  idle,
  connecting,
  syncing,
  completed,
  error;

  bool get isActive => this == SyncStatus.connecting || this == SyncStatus.syncing;
  bool get isCompleted => this == SyncStatus.completed;
  bool get hasError => this == SyncStatus.error;
}

/// Synchronization result
class SyncResult {
  final int studentsAdded;
  final int studentsUpdated;
  final int coursesAdded;
  final int coursesUpdated;
  final int subjectsAdded;
  final int subjectsUpdated;
  final int evidencesAdded;
  final int evidencesUpdated;
  final int filesTransferred;
  final List<String> errors;
  final DateTime timestamp;

  const SyncResult({
    required this.studentsAdded,
    required this.studentsUpdated,
    required this.coursesAdded,
    required this.coursesUpdated,
    required this.subjectsAdded,
    required this.subjectsUpdated,
    required this.evidencesAdded,
    required this.evidencesUpdated,
    required this.filesTransferred,
    required this.errors,
    required this.timestamp,
  });

  int get totalItemsSynced =>
      studentsAdded +
      studentsUpdated +
      coursesAdded +
      coursesUpdated +
      subjectsAdded +
      subjectsUpdated +
      evidencesAdded +
      evidencesUpdated;

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccessful => !hasErrors && totalItemsSynced > 0;

  factory SyncResult.empty() {
    return SyncResult(
      studentsAdded: 0,
      studentsUpdated: 0,
      coursesAdded: 0,
      coursesUpdated: 0,
      subjectsAdded: 0,
      subjectsUpdated: 0,
      evidencesAdded: 0,
      evidencesUpdated: 0,
      filesTransferred: 0,
      errors: [],
      timestamp: DateTime.now(),
    );
  }

  SyncResult copyWith({
    int? studentsAdded,
    int? studentsUpdated,
    int? coursesAdded,
    int? coursesUpdated,
    int? subjectsAdded,
    int? subjectsUpdated,
    int? evidencesAdded,
    int? evidencesUpdated,
    int? filesTransferred,
    List<String>? errors,
    DateTime? timestamp,
  }) {
    return SyncResult(
      studentsAdded: studentsAdded ?? this.studentsAdded,
      studentsUpdated: studentsUpdated ?? this.studentsUpdated,
      coursesAdded: coursesAdded ?? this.coursesAdded,
      coursesUpdated: coursesUpdated ?? this.coursesUpdated,
      subjectsAdded: subjectsAdded ?? this.subjectsAdded,
      subjectsUpdated: subjectsUpdated ?? this.subjectsUpdated,
      evidencesAdded: evidencesAdded ?? this.evidencesAdded,
      evidencesUpdated: evidencesUpdated ?? this.evidencesUpdated,
      filesTransferred: filesTransferred ?? this.filesTransferred,
      errors: errors ?? this.errors,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Student DTO for synchronization
class StudentSync {
  final int? id;
  final int courseId;
  final String name;
  final String? faceEmbeddings192; // Base64 encoded
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const StudentSync({
    this.id,
    required this.courseId,
    required this.name,
    this.faceEmbeddings192,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentSync.fromJson(Map<String, dynamic> json) {
    return StudentSync(
      id: json['id'] as int?,
      courseId: json['courseId'] as int? ?? json['course_id'] as int? ?? 1,
      name: json['name'] as String,
      faceEmbeddings192: json['faceEmbeddings192'] as String? ??
          json['face_embeddings_192'] as String?,
      isActive: (json['isActive'] as int? ?? json['is_active'] as int? ?? 1) == 1,
      createdAt: json['createdAt'] as String? ??
          json['created_at'] as String? ??
          DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String? ??
          json['updated_at'] as String? ??
          DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'courseId': courseId,
      'name': name,
      if (faceEmbeddings192 != null) 'faceEmbeddings192': faceEmbeddings192,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Convert from domain entity
  static StudentSync fromEntity(
    int? id,
    int courseId,
    String name,
    Uint8List? faceEmbeddings,
    bool isActive, // Added parameter
    DateTime createdAt,
    DateTime updatedAt,
  ) {
    return StudentSync(
      id: id,
      courseId: courseId,
      name: name,
      faceEmbeddings192:
          faceEmbeddings != null ? base64Encode(faceEmbeddings) : null,
      isActive: isActive,
      createdAt: createdAt.toIso8601String(),
      updatedAt: updatedAt.toIso8601String(),
    );
  }
}

/// Course DTO for synchronization
class CourseSync {
  final int? id;
  final String name;
  final String startDate;
  final String? endDate;
  final bool isActive;
  final String createdAt;

  const CourseSync({
    this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
  });

  factory CourseSync.fromJson(Map<String, dynamic> json) {
    return CourseSync(
      id: json['id'] as int?,
      name: json['name'] as String,
      startDate: json['startDate'] as String? ??
          json['start_date'] as String? ??
          DateTime.now().toIso8601String(),
      endDate: json['endDate'] as String? ?? json['end_date'] as String?,
      isActive: (json['isActive'] as int? ??
              json['is_active'] as int? ??
              1) ==
          1,
      createdAt: json['createdAt'] as String? ??
          json['created_at'] as String? ??
          DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
    };
  }
}

/// Subject DTO for synchronization
class SubjectSync {
  final int? id;
  final String name;
  final String? color;
  final String? icon;
  final bool isDefault;
  final String createdAt;

  const SubjectSync({
    this.id,
    required this.name,
    this.color,
    this.icon,
    required this.isDefault,
    required this.createdAt,
  });

  factory SubjectSync.fromJson(Map<String, dynamic> json) {
    return SubjectSync(
      id: json['id'] as int?,
      name: json['name'] as String,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      isDefault: (json['isDefault'] as int? ??
              json['is_default'] as int? ??
              0) ==
          1,
      createdAt: json['createdAt'] as String? ??
          json['created_at'] as String? ??
          DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt,
    };
  }
}

/// Evidence DTO for synchronization
class EvidenceSync {
  final int? id;
  final int? studentId;
  final int? courseId;
  final int subjectId;
  final String type; // IMG, VID, AUD
  final String filePath;
  final String? thumbnailPath;
  final int? fileSize;
  final int? duration;
  final String captureDate;
  final bool isReviewed;
  final String? notes;
  final String createdAt;

  const EvidenceSync({
    this.id,
    this.studentId,
    this.courseId,
    required this.subjectId,
    required this.type,
    required this.filePath,
    this.thumbnailPath,
    this.fileSize,
    this.duration,
    required this.captureDate,
    required this.isReviewed,
    this.notes,
    required this.createdAt,
  });

  factory EvidenceSync.fromJson(Map<String, dynamic> json) {
    return EvidenceSync(
      id: json['id'] as int?,
      studentId: json['studentId'] as int? ?? json['student_id'] as int?,
      courseId: json['courseId'] as int? ?? json['course_id'] as int?,
      subjectId: json['subjectId'] as int? ?? json['subject_id'] as int? ?? 0,
      type: json['type'] as String,
      filePath: json['filePath'] as String? ?? json['file_path'] as String,
      thumbnailPath: json['thumbnailPath'] as String? ??
          json['thumbnail_path'] as String?,
      fileSize: json['fileSize'] as int? ?? json['file_size'] as int?,
      duration: json['duration'] as int?,
      captureDate: json['captureDate'] as String? ??
          json['capture_date'] as String? ??
          DateTime.now().toIso8601String(),
      isReviewed: (json['isReviewed'] as int? ??
              json['is_reviewed'] as int? ??
              1) ==
          1,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String? ??
          json['created_at'] as String? ??
          DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (studentId != null) 'studentId': studentId,
      if (courseId != null) 'courseId': courseId,
      'subjectId': subjectId,
      'type': type,
      'filePath': filePath,
      if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
      if (fileSize != null) 'fileSize': fileSize,
      if (duration != null) 'duration': duration,
      'captureDate': captureDate,
      'isReviewed': isReviewed ? 1 : 0,
      if (notes != null) 'notes': notes,
      'createdAt': createdAt,
    };
  }

  /// Get filename from filePath
  String get filename => filePath.split('/').last;
}

/// Complete sync metadata from server
class SyncMetadata {
  final List<StudentSync> students;
  final List<CourseSync> courses;
  final List<SubjectSync> subjects;
  final List<EvidenceSync> evidences;

  const SyncMetadata({
    required this.students,
    required this.courses,
    required this.subjects,
    required this.evidences,
  });

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      students: (json['students'] as List<dynamic>?)
              ?.map((e) => StudentSync.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) => CourseSync.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((e) => SubjectSync.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      evidences: (json['evidences'] as List<dynamic>?)
              ?.map((e) => EvidenceSync.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'students': students.map((e) => e.toJson()).toList(),
      'courses': courses.map((e) => e.toJson()).toList(),
      'subjects': subjects.map((e) => e.toJson()).toList(),
      'evidences': evidences.map((e) => e.toJson()).toList(),
    };
  }

  factory SyncMetadata.empty() {
    return const SyncMetadata(
      students: [],
      courses: [],
      subjects: [],
      evidences: [],
    );
  }
}

/// Sync configuration
class SyncConfig {
  final String? serverUrl; // e.g., "192.168.1.100:3000"
  final DateTime? lastSyncTimestamp;
  final bool autoSync;

  const SyncConfig({
    this.serverUrl,
    this.lastSyncTimestamp,
    this.autoSync = false,
  });

  bool get isConfigured => serverUrl != null && serverUrl!.isNotEmpty;

  String? get baseUrl =>
      serverUrl != null ? 'http://$serverUrl' : null;

  SyncConfig copyWith({
    String? serverUrl,
    DateTime? lastSyncTimestamp,
    bool? autoSync,
  }) {
    return SyncConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      autoSync: autoSync ?? this.autoSync,
    );
  }
}
