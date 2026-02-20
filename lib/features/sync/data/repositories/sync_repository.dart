import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/core/domain/repositories/course_repository.dart';
import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';
import 'package:eduportfolio/core/domain/repositories/student_repository.dart';
import 'package:eduportfolio/core/domain/repositories/subject_repository.dart';
import 'package:eduportfolio/core/services/sync_service.dart';
import 'package:eduportfolio/core/services/sync_password_storage.dart';
import 'package:eduportfolio/core/utils/logger.dart';
import 'package:eduportfolio/features/sync/domain/entities/sync_models.dart';
import 'package:path_provider/path_provider.dart';

/// Repository for synchronization operations
///
/// Coordinates between local repositories and remote sync service
/// to perform bidirectional synchronization.
class SyncRepository {
  final SyncService _syncService;
  final SyncPasswordStorage _passwordStorage;
  final StudentRepository _studentRepository;
  final CourseRepository _courseRepository;
  final SubjectRepository _subjectRepository;
  final EvidenceRepository _evidenceRepository;

  SyncRepository({
    required SyncService syncService,
    SyncPasswordStorage? passwordStorage,
    required StudentRepository studentRepository,
    required CourseRepository courseRepository,
    required SubjectRepository subjectRepository,
    required EvidenceRepository evidenceRepository,
  })  : _syncService = syncService,
        _passwordStorage = passwordStorage ?? SyncPasswordStorage(),
        _studentRepository = studentRepository,
        _courseRepository = courseRepository,
        _subjectRepository = subjectRepository,
        _evidenceRepository = evidenceRepository;

  /// Load and configure password before sync operations
  Future<void> _ensurePasswordConfigured() async {
    final password = await _passwordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw SyncException(
        'Password not configured. Please set up sync password in settings.',
      );
    }
    _syncService.setPassword(password);
  }

  /// Test connection to server
  Future<bool> testConnection(String baseUrl) async {
    return await _syncService.testConnection(baseUrl);
  }

  /// Get system info from server
  Future<SystemInfo> getSystemInfo(String baseUrl) async {
    return await _syncService.getSystemInfo(baseUrl);
  }

  /// Perform full bidirectional synchronization
  ///
  /// Returns [SyncResult] with statistics about synced items.
  Future<SyncResult> syncAll(String baseUrl) async {
    Logger.info('Starting full synchronization');

    // Ensure password is configured
    await _ensurePasswordConfigured();

    final result = SyncResult.empty();
    final errors = <String>[];

    try {
      // 1. Get remote metadata
      Logger.info('Fetching remote metadata...');
      final remoteMetadata = await _syncService.getMetadata(baseUrl);

      // 2. Get local metadata
      Logger.info('Fetching local metadata...');
      final localMetadata = await _getLocalMetadata();

      // 3. Sync courses (must be first due to foreign keys)
      Logger.info('🔄 Sincronizando CURSOS...');
      final courseResult = await _syncCourses(
        localMetadata.courses,
        remoteMetadata.courses,
      );

      // 4. Sync subjects
      Logger.info('🔄 Sincronizando ASIGNATURAS...');
      final subjectResult = await _syncSubjects(
        localMetadata.subjects,
        remoteMetadata.subjects,
      );

      // 5. Sync students
      Logger.info('🔄 Sincronizando ESTUDIANTES...');
      final studentResult = await _syncStudents(
        localMetadata.students,
        remoteMetadata.students,
      );

      // 6. Download remote files FIRST (before creating evidence records)
      Logger.info('🔄 Sincronizando ARCHIVOS REMOTOS...');
      final filesDownloaded = await _downloadRemoteFiles(
        baseUrl,
        remoteMetadata.evidences,
      );

      // 7. Sync evidences metadata (now that files are downloaded)
      Logger.info('🔄 Sincronizando EVIDENCIAS (Metadatos)...');
      final evidenceResult = await _syncEvidences(
        localMetadata.evidences,
        remoteMetadata.evidences,
      );

      // 8. Push local data to server
      Logger.info('🔄 Enviando cambios locales al servidor...');
      await _syncService.pushMetadata(baseUrl, localMetadata);

      // 9. Upload local files to server
      Logger.info('🔄 Subiendo archivos locales...');
      final filesUploaded = await _uploadLocalFiles(
        baseUrl,
        localMetadata.evidences,
        remoteMetadata.evidences,
      );

      final filesTransferred = filesDownloaded + filesUploaded;

      Logger.info('✅ Sincronización completada con éxito');
      return result.copyWith(
        coursesAdded: courseResult.added,
        coursesUpdated: courseResult.updated,
        subjectsAdded: subjectResult.added,
        subjectsUpdated: subjectResult.updated,
        studentsAdded: studentResult.added,
        studentsUpdated: studentResult.updated,
        evidencesAdded: evidenceResult.added,
        evidencesUpdated: evidenceResult.updated,
        filesTransferred: filesTransferred,
        errors: errors,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      Logger.error('Sync failed', e);
      errors.add(e.toString());
      return result.copyWith(errors: errors, timestamp: DateTime.now());
    }
  }

  /// Get local metadata
  Future<SyncMetadata> _getLocalMetadata() async {
    final students = await _studentRepository.getAllStudents();
    final courses = await _courseRepository.getAllCourses();
    final subjects = await _subjectRepository.getAllSubjects();
    final evidences = await _evidenceRepository.getAllEvidences();

    return SyncMetadata(
      students: students
          .map((s) => StudentSync.fromEntity(
                s.id,
                s.courseId,
                s.name,
                s.faceEmbeddings,
                s.isActive,
                s.createdAt,
                s.updatedAt,
              ))
          .toList(),
      courses: courses
          .map((c) => CourseSync(
                id: c.id,
                name: c.name,
                startDate: c.startDate.toIso8601String(),
                endDate: c.endDate?.toIso8601String(),
                isActive: c.isActive,
                createdAt: c.createdAt.toIso8601String(),
              ))
          .toList(),
      subjects: subjects
          .map((s) => SubjectSync(
                id: s.id,
                name: s.name,
                color: s.color,
                icon: s.icon,
                isDefault: s.isDefault,
                createdAt: s.createdAt.toIso8601String(),
              ))
          .toList(),
      evidences: evidences
          .map((e) {
            // Normalize thumbnailPath: send only the filename (not the absolute local path)
            // Desktop will prepend 'evidences/' when storing it
            String? normalizedThumbnailPath;
            if (e.thumbnailPath != null) {
              final thumbFilename = e.thumbnailPath!.split('/').last;
              if (thumbFilename.isNotEmpty) {
                normalizedThumbnailPath = thumbFilename;
              }
            }
            return EvidenceSync(
              id: e.id,
              studentId: e.studentId,
              courseId: e.courseId,
              subjectId: e.subjectId,
              type: e.type.toDbString(),
              filePath: 'evidences/${e.filePath.split('/').last}', // Normalize to relative path
              thumbnailPath: normalizedThumbnailPath,
              fileSize: e.fileSize,
              duration: e.duration,
              captureDate: e.captureDate.toIso8601String(),
              isReviewed: e.isReviewed,
              notes: e.notes,
              createdAt: e.createdAt.toIso8601String(),
            );
          })
          .toList(),
    );
  }

  /// Sync courses
  Future<_SyncItemResult> _syncCourses(
    List<CourseSync> local,
    List<CourseSync> remote,
  ) async {
    int added = 0;
    int updated = 0;

    for (final remoteCourse in remote) {
      final localCourse = local.firstWhere(
        (c) => c.name == remoteCourse.name,
        orElse: () => CourseSync(
          name: '',
          startDate: '',
          isActive: false,
          createdAt: '',
        ),
      );

      // Check if course exists by ID (primary match) or by name (fallback)
      final localCourseById = local.firstWhere(
        (c) => c.id == remoteCourse.id,
        orElse: () => CourseSync(
          name: '',
          startDate: '',
          isActive: false,
          createdAt: '',
        ),
      );

      if (localCourseById.name.isEmpty && localCourse.name.isEmpty) {
        // New course from remote - use server's ID
        final course = Course(
          id: remoteCourse.id, // ✅ Use server ID
          name: remoteCourse.name,
          startDate: DateTime.parse(remoteCourse.startDate),
          endDate: remoteCourse.endDate != null
              ? DateTime.parse(remoteCourse.endDate!)
              : null,
          isActive: remoteCourse.isActive,
          createdAt: DateTime.parse(remoteCourse.createdAt),
        );
        await _courseRepository.createCourse(course);
        added++;
        Logger.info('Added course: ${course.name} (ID: ${course.id})');
      } else if (localCourseById.name.isEmpty && localCourse.name.isNotEmpty) {
        // Course exists by name but with different ID - update to use server ID
        final oldId = localCourse.id;
        final newId = remoteCourse.id;

        Logger.warning(
          'Course "${remoteCourse.name}" exists with different ID. Local: $oldId, Remote: $newId. Consolidating to server ID.',
        );

        // Preserve local isActive status - if user set this course as active, keep it active
        final bool shouldBeActive = localCourse.isActive || remoteCourse.isActive;

        // Update students and evidences to use new course ID
        if (oldId != null && newId != null && oldId != newId) {
          // Update students
          final students = await _studentRepository.getAllStudents();
          for (final student in students.where((s) => s.courseId == oldId)) {
            final updatedStudent = student.copyWith(courseId: newId);
            await _studentRepository.updateStudent(updatedStudent);
          }

          // Update evidences
          final evidences = await _evidenceRepository.getAllEvidences();
          for (final evidence in evidences.where((e) => e.courseId == oldId)) {
            final updatedEvidence = evidence.copyWith(courseId: newId);
            await _evidenceRepository.updateEvidence(updatedEvidence);
          }

          Logger.info('Updated students and evidences for course "${remoteCourse.name}" from ID $oldId to $newId');

          // Delete old course entry
          try {
            await _courseRepository.deleteCourse(oldId);
            Logger.info('Deleted duplicate course with old ID: $oldId');
          } catch (e) {
            Logger.warning('Could not delete old course ID $oldId: $e');
          }
        }

        // Create course with server ID, preserving active status if local was active
        final course = Course(
          id: newId, // ✅ Use server ID
          name: remoteCourse.name,
          startDate: DateTime.parse(remoteCourse.startDate),
          endDate: remoteCourse.endDate != null
              ? DateTime.parse(remoteCourse.endDate!)
              : null,
          isActive: shouldBeActive, // ✅ Preserve active status from local if it was active
          createdAt: DateTime.parse(remoteCourse.createdAt),
        );
        await _courseRepository.createCourse(course);
        updated++;
        Logger.info('Consolidated course: ${course.name} (ID: ${course.id}, isActive: $shouldBeActive)');
      } else {
        // Course exists with correct ID - check if remote is newer
        final remoteUpdated = DateTime.parse(remoteCourse.createdAt);
        final localUpdated = DateTime.parse(localCourseById.createdAt);

        if (remoteUpdated.isAfter(localUpdated)) {
          // Update from remote
          final course = Course(
            id: remoteCourse.id, // ✅ Keep server ID
            name: remoteCourse.name,
            startDate: DateTime.parse(remoteCourse.startDate),
            endDate: remoteCourse.endDate != null
                ? DateTime.parse(remoteCourse.endDate!)
                : null,
            isActive: remoteCourse.isActive,
            createdAt: DateTime.parse(remoteCourse.createdAt),
          );
          await _courseRepository.updateCourse(course);
          updated++;
          Logger.info('Updated course: ${course.name} (ID: ${course.id})');
        }
      }
    }

    return _SyncItemResult(added: added, updated: updated);
  }

  /// Sync subjects
  Future<_SyncItemResult> _syncSubjects(
    List<SubjectSync> local,
    List<SubjectSync> remote,
  ) async {
    int added = 0;
    int updated = 0;

    for (final remoteSubject in remote) {
      // Check if subject already exists locally by ID (primary match)
      // or by name (fallback for first-time sync)
      final localSubjectById = local.firstWhere(
        (s) => s.id == remoteSubject.id,
        orElse: () => SubjectSync(
          name: '',
          isDefault: false,
          createdAt: '',
        ),
      );

      final localSubjectByName = local.firstWhere(
        (s) => s.name == remoteSubject.name,
        orElse: () => SubjectSync(
          name: '',
          isDefault: false,
          createdAt: '',
        ),
      );

      if (localSubjectById.name.isEmpty && localSubjectByName.name.isEmpty) {
        // New subject from remote - use server's ID to maintain consistency
        final subject = Subject(
          id: remoteSubject.id, // ✅ FIX: Use remote ID to avoid duplicates
          name: remoteSubject.name,
          color: remoteSubject.color,
          icon: remoteSubject.icon,
          isDefault: remoteSubject.isDefault,
          createdAt: DateTime.parse(remoteSubject.createdAt),
        );
        await _subjectRepository.createSubject(subject);
        added++;
        Logger.info('Added subject: ${subject.name} (ID: ${subject.id})');
      } else if (localSubjectById.name.isEmpty && localSubjectByName.name.isNotEmpty) {
        // Subject exists by name but with different ID - update to match server ID
        final subject = Subject(
          id: remoteSubject.id, // ✅ FIX: Override local ID with server ID
          name: remoteSubject.name,
          color: remoteSubject.color ?? localSubjectByName.color,
          icon: remoteSubject.icon ?? localSubjectByName.icon,
          isDefault: remoteSubject.isDefault,
          createdAt: DateTime.parse(remoteSubject.createdAt),
        );

        // Delete old entry with wrong ID if it exists
        if (localSubjectByName.id != null && localSubjectByName.id != remoteSubject.id) {
          try {
            await _subjectRepository.deleteSubject(localSubjectByName.id!);
            Logger.info('Deleted duplicate subject with ID: ${localSubjectByName.id}');
          } catch (e) {
            Logger.warning('Could not delete old subject ID ${localSubjectByName.id}: $e');
          }
        }

        await _subjectRepository.createSubject(subject);
        updated++;
        Logger.info('Updated subject: ${subject.name} (ID: ${subject.id})');
      } else {
        // Subject already synced correctly
        Logger.debug('Subject already synced: ${remoteSubject.name} (ID: ${remoteSubject.id})');
      }
    }

    return _SyncItemResult(added: added, updated: updated);
  }

  /// Sync students
  Future<_SyncItemResult> _syncStudents(
    List<StudentSync> local,
    List<StudentSync> remote,
  ) async {
    int added = 0;
    int updated = 0;

    for (final remoteStudent in remote) {
      // Check if student exists locally by ID (primary match) or by name (duplicate detection)
      final localStudentById = local.firstWhere(
        (s) => s.id == remoteStudent.id,
        orElse: () => StudentSync(
          courseId: 1,
          name: '',
          isActive: true,
          createdAt: '',
          updatedAt: '',
        ),
      );

      final localStudentByName = local.firstWhere(
        (s) => s.name == remoteStudent.name,
        orElse: () => StudentSync(
          courseId: 1,
          name: '',
          isActive: true,
          createdAt: '',
          updatedAt: '',
        ),
      );

      if (localStudentById.name.isEmpty && localStudentByName.name.isEmpty) {
        // New student from remote - use server's ID
        final student = Student(
          id: remoteStudent.id, // ✅ Use server ID
          courseId: remoteStudent.courseId,
          name: remoteStudent.name,
          faceEmbeddings: remoteStudent.faceEmbeddings192 != null
              ? base64Decode(remoteStudent.faceEmbeddings192!)
              : null,
          isActive: remoteStudent.isActive,
          createdAt: DateTime.parse(remoteStudent.createdAt),
          updatedAt: DateTime.parse(remoteStudent.updatedAt),
        );
        await _studentRepository.createStudent(student);
        added++;
        Logger.info('   ➕ Estudiante nuevo del servidor: ${student.name} (ID: ${student.id})');
      } else if (localStudentById.name.isEmpty && localStudentByName.name.isNotEmpty) {
        // Student exists by name but with different ID - consolidate to server ID
        final oldId = localStudentByName.id;
        final newId = remoteStudent.id;

        Logger.warning(
          '   ⚠️ Conflicto de ID en "${remoteStudent.name}". Local: $oldId, Remoto: $newId. Consolidando al ID del servidor.',
        );

        // Update all evidences that reference the old ID to use the new ID
        if (oldId != null && newId != null && oldId != newId) {
          final evidences = await _evidenceRepository.getAllEvidences();
          for (final evidence in evidences.where((e) => e.studentId == oldId)) {
            final updatedEvidence = evidence.copyWith(studentId: newId);
            await _evidenceRepository.updateEvidence(updatedEvidence);
          }
          Logger.info('      ✏️ Evidencias migradas de ID $oldId a $newId');

          // Delete old student entry
          try {
            await _studentRepository.deleteStudent(oldId);
            Logger.info('      🗑️ Estudiante local duplicado eliminado (ID: $oldId)');
          } catch (e) {
            Logger.warning('      ❌ No se pudo borrar el estudiante antiguo ID $oldId: $e');
          }
        }

        // Insert/update student with server ID
        final student = Student(
          id: newId, // ✅ Use server ID
          courseId: remoteStudent.courseId,
          name: remoteStudent.name,
          faceEmbeddings: remoteStudent.faceEmbeddings192 != null
              ? base64Decode(remoteStudent.faceEmbeddings192!)
              : null,
          isActive: remoteStudent.isActive,
          createdAt: DateTime.parse(remoteStudent.createdAt),
          updatedAt: DateTime.parse(remoteStudent.updatedAt),
        );
        await _studentRepository.createStudent(student);
        updated++;
        Logger.info('      ✅ Estudiante consolidad: ${student.name} (Nuevo ID: ${student.id})');
      } else {
        // Student exists with correct ID - check if remote is newer
        final remoteUpdated = DateTime.parse(remoteStudent.updatedAt);
        final localUpdated = DateTime.parse(localStudentById.updatedAt);

        if (remoteUpdated.isAfter(localUpdated)) {
          // Update from remote
          final student = Student(
            id: remoteStudent.id, // ✅ Keep server ID
            courseId: remoteStudent.courseId,
            name: remoteStudent.name,
            faceEmbeddings: remoteStudent.faceEmbeddings192 != null
                ? base64Decode(remoteStudent.faceEmbeddings192!)
                : null,
            isActive: remoteStudent.isActive,
            createdAt: DateTime.parse(remoteStudent.createdAt),
            updatedAt: DateTime.parse(remoteStudent.updatedAt),
          );
          await _studentRepository.updateStudent(student);
          updated++;
          Logger.info('   ✏️ Estudiante actualizado: ${student.name} (ID: ${student.id})');
        } else {
           // Logger.debug('   ⏭️ Estudiante al día: ${remoteStudent.name}');
        }
      }
    }

    return _SyncItemResult(added: added, updated: updated);
  }

  /// Sync evidences metadata
  Future<_SyncItemResult> _syncEvidences(
    List<EvidenceSync> local,
    List<EvidenceSync> remote,
  ) async {
    int added = 0;
    int updated = 0;

    final appDir = await getApplicationDocumentsDirectory();
    final evidencesDir = Directory('${appDir.path}/evidences');
    if (!await evidencesDir.exists()) {
      await evidencesDir.create(recursive: true);
    }

    for (final remoteEvidence in remote) {
      // ✅ FIX: Compare by ID first (primary match), then by filename (fallback for orphaned evidence)
      final localEvidenceById = remoteEvidence.id != null
          ? local.firstWhere(
              (e) => e.id == remoteEvidence.id,
              orElse: () => EvidenceSync(
                subjectId: 0,
                type: '',
                filePath: '',
                captureDate: '',
                isReviewed: true,
                createdAt: '',
              ),
            )
          : EvidenceSync(
              subjectId: 0,
              type: '',
              filePath: '',
              captureDate: '',
              isReviewed: true,
              createdAt: '',
            );

      // ✅ FIX: Fallback to filename comparison (normalized without .enc)
      final remoteFilename = remoteEvidence.filename.replaceAll(RegExp(r'\.enc$', caseSensitive: false), '');
      final localEvidenceByFilename = local.firstWhere(
        (e) => e.filename.replaceAll(RegExp(r'\.enc$', caseSensitive: false), '') == remoteFilename,
        orElse: () => EvidenceSync(
          subjectId: 0,
          type: '',
          filePath: '',
          captureDate: '',
          isReviewed: true,
          createdAt: '',
        ),
      );

      // Check if evidence exists locally (by ID or by filename)
      final evidenceExists = localEvidenceById.filePath.isNotEmpty || localEvidenceByFilename.filePath.isNotEmpty;

      if (!evidenceExists) {
        // New evidence from remote (file will be downloaded separately)
        // Remove .enc extension from filename since server sends decrypted files
        final cleanFilename = remoteEvidence.filename.replaceAll(RegExp(r'\.enc$', caseSensitive: false), '');

        // Resolve thumbnail path: server sends just the filename, we point to local thumbnails dir
        String? localThumbnailPath;
        if (remoteEvidence.thumbnailPath != null) {
          final thumbFilename = remoteEvidence.thumbnailPath!.split('/').last;
          if (thumbFilename.isNotEmpty) {
            localThumbnailPath = '${appDir.path}/evidences/thumbnails/$thumbFilename';
          }
        }

        final evidence = Evidence(
          id: remoteEvidence.id, // ✅ Use server ID to maintain consistency
          studentId: remoteEvidence.studentId,
          courseId: remoteEvidence.courseId,
          subjectId: remoteEvidence.subjectId,
          type: EvidenceType.fromString(remoteEvidence.type),
          filePath: '${evidencesDir.path}/$cleanFilename', // Use local absolute path without .enc
          thumbnailPath: localThumbnailPath,
          fileSize: remoteEvidence.fileSize,
          duration: remoteEvidence.duration,
          captureDate: DateTime.parse(remoteEvidence.captureDate),
          isReviewed: remoteEvidence.isReviewed,
          notes: remoteEvidence.notes,
          createdAt: DateTime.parse(remoteEvidence.createdAt),
        );
        await _evidenceRepository.createEvidence(evidence);
        added++;
        Logger.info('   ➕ Nueva evidencia del servidor: $cleanFilename (ID: ${evidence.id})');
      } else {
        Logger.debug('   ⏭️ Evidencia ya existe: $remoteFilename');
      }
    }

    return _SyncItemResult(added: added, updated: updated);
  }

  /// Download remote files that don't exist locally
  Future<int> _downloadRemoteFiles(
    String baseUrl,
    List<EvidenceSync> remote,
  ) async {
    int filesDownloaded = 0;
    final appDir = await getApplicationDocumentsDirectory();
    final evidencesDir = Directory('${appDir.path}/evidences');
    final thumbnailsDir = Directory('${appDir.path}/evidences/thumbnails');

    if (!await evidencesDir.exists()) {
      await evidencesDir.create(recursive: true);
    }
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }

    Logger.info('Downloading ${remote.length} remote files...');

    for (final remoteEvidence in remote) {
      // Remove .enc extension from filename since server sends decrypted files
      final cleanFilename = remoteEvidence.filename.replaceAll(RegExp(r'\.enc$', caseSensitive: false), '');
      final localFile = File('${evidencesDir.path}/$cleanFilename');

      if (!await localFile.exists()) {
        try {
          // Download using the original filename (with .enc) from server
          // but save to local path without .enc (decrypted)
          await _syncService.downloadFile(
            baseUrl,
            remoteEvidence.filename, // Server expects filename with .enc
            localFile.path,          // But we save without .enc (decrypted)
          );
          filesDownloaded++;
          Logger.info('Downloaded and saved decrypted file: $cleanFilename');
        } catch (e) {
          Logger.error('Failed to download file: ${remoteEvidence.filename}', e);
          // Continue with next file even if this one fails
        }
      } else {
        Logger.debug('File already exists locally: $cleanFilename');
      }

      // Download thumbnail/cover for audio evidences if available and missing locally
      if (remoteEvidence.thumbnailPath != null) {
        final thumbFilename = remoteEvidence.thumbnailPath!.split('/').last;
        if (thumbFilename.isNotEmpty) {
          final localThumb = File('${thumbnailsDir.path}/$thumbFilename');
          if (!await localThumb.exists()) {
            try {
              await _syncService.downloadFile(
                baseUrl,
                thumbFilename, // filename on server (in evidences/ flat)
                localThumb.path,
              );
              filesDownloaded++;
              Logger.info('Downloaded thumbnail: $thumbFilename');
            } catch (e) {
              Logger.warning('Could not download thumbnail (non-critical): $thumbFilename');
            }
          }
        }
      }
    }

    Logger.info('Downloaded $filesDownloaded files from server');
    return filesDownloaded;
  }

  /// Upload local files that don't exist on remote
  Future<int> _uploadLocalFiles(
    String baseUrl,
    List<EvidenceSync> local,
    List<EvidenceSync> remote,
  ) async {
    int filesUploaded = 0;
    final appDir = await getApplicationDocumentsDirectory();
    final evidencesDir = Directory('${appDir.path}/evidences');
    final thumbnailsDir = Directory('${appDir.path}/evidences/thumbnails');

    Logger.info('Uploading ${local.length} local files...');

    for (final localEvidence in local) {
      // Normalize filenames by removing .enc extension for comparison
      final localFilename = localEvidence.filename.replaceAll(RegExp(r'\.enc$', caseSensitive: false), '');

      final remoteHasFile = remote.any((e) {
        final remoteFilename = e.filename.replaceAll(RegExp(r'\.enc$', caseSensitive: false), '');
        return remoteFilename == localFilename;
      });

      if (!remoteHasFile) {
        final localFile = File('${evidencesDir.path}/${localEvidence.filename}');

        if (await localFile.exists()) {
          try {
            await _syncService.uploadFile(
              baseUrl,
              localFile,
              localEvidence.filename,
            );
            filesUploaded++;
            Logger.info('Uploaded file: ${localEvidence.filename}');
          } catch (e) {
            Logger.error('Failed to upload file: ${localEvidence.filename}', e);
            // Continue with next file even if this one fails
          }
        } else {
          Logger.warning('Local file not found, skipping upload: ${localEvidence.filename}');
        }
      } else {
        Logger.debug('File already exists on server (skipping): $localFilename');
      }

      // Upload thumbnail/cover image for audio evidences if it exists
      if (localEvidence.thumbnailPath != null) {
        final thumbFilename = localEvidence.thumbnailPath!.split('/').last;
        if (thumbFilename.isNotEmpty) {
          // Check if thumbnail already exists on remote
          final remoteHasThumb = remote.any((e) {
            final remoteThumb = e.thumbnailPath?.split('/').last ?? '';
            return remoteThumb == thumbFilename;
          });

          if (!remoteHasThumb) {
            // Look for thumbnail in thumbnails subdirectory
            final thumbFile = File('${thumbnailsDir.path}/$thumbFilename');
            if (await thumbFile.exists()) {
              try {
                await _syncService.uploadFile(
                  baseUrl,
                  thumbFile,
                  thumbFilename,
                );
                filesUploaded++;
                Logger.info('Uploaded thumbnail: $thumbFilename');
              } catch (e) {
                Logger.error('Failed to upload thumbnail: $thumbFilename', e);
              }
            }
          }
        }
      }
    }

    Logger.info('Uploaded $filesUploaded files to server');
    return filesUploaded;
  }
}

/// Helper class for sync item results
class _SyncItemResult {
  final int added;
  final int updated;

  _SyncItemResult({required this.added, required this.updated});
}
