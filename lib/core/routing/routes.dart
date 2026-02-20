import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/features/capture/presentation/screens/capture_screen.dart';
import 'package:eduportfolio/features/capture/presentation/screens/quick_capture_screen.dart';
import 'package:eduportfolio/features/courses/presentation/screens/archived_courses_screen.dart';
import 'package:eduportfolio/features/courses/presentation/screens/course_form_screen.dart';
import 'package:eduportfolio/features/courses/presentation/screens/courses_screen.dart';
import 'package:eduportfolio/features/gallery/presentation/screens/evidence_detail_screen.dart';
import 'package:eduportfolio/features/gallery/presentation/screens/gallery_screen.dart';
import 'package:eduportfolio/features/home/presentation/screens/home_screen.dart';
import 'package:eduportfolio/features/review/presentation/screens/review_screen.dart';
import 'package:eduportfolio/features/settings/presentation/screens/settings_screen.dart';
import 'package:eduportfolio/features/students/presentation/screens/face_training_screen.dart';
import 'package:eduportfolio/features/students/presentation/screens/student_detail_screen.dart';
import 'package:eduportfolio/features/students/presentation/screens/student_form_screen.dart';
import 'package:eduportfolio/features/students/presentation/screens/students_screen.dart';
import 'package:eduportfolio/features/subjects/presentation/screens/subjects_management_screen.dart';
import 'package:eduportfolio/features/sync/presentation/screens/sync_screen.dart';
import 'package:eduportfolio/features/sync/presentation/screens/sync_settings_screen.dart';
import 'package:flutter/material.dart';

/// App routes configuration
class AppRoutes {
  AppRoutes._(); // Private constructor to prevent instantiation

  // Route names
  static const String home = '/';
  static const String capture = '/capture';
  static const String quickCapture = '/quick-capture';
  static const String gallery = '/gallery';
  static const String evidenceDetail = '/evidence-detail';
  static const String students = '/students';
  static const String studentForm = '/student-form';
  static const String studentDetail = '/student-detail';
  static const String faceTraining = '/face-training';
  static const String courses = '/courses';
  static const String courseForm = '/course-form';
  static const String archivedCourses = '/archived-courses';
  static const String review = '/review';
  static const String config = '/config';
  static const String subjectsManagement = '/subjects-management';
  static const String syncSettings = '/sync-settings';
  static const String sync = '/sync';

  /// Generate routes for the app
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case capture:
        // Extract optional preselected subject ID from arguments
        final args = settings.arguments as Map<String, dynamic>?;
        final preselectedSubjectId = args?['subjectId'] as int?;

        return MaterialPageRoute<void>(
          builder: (_) => CaptureScreen(
            preselectedSubjectId: preselectedSubjectId,
          ),
          settings: settings,
        );

      case quickCapture:
        // Extract required subject and subject ID from arguments
        final args = settings.arguments as Map<String, dynamic>?;
        final subject = args?['subject'] as Subject?;
        final subjectId = args?['subjectId'] as int?;

        if (subject == null || subjectId == null) {
          return _errorRoute(settings);
        }

        return MaterialPageRoute<void>(
          builder: (_) => QuickCaptureScreen(
            subject: subject,
            subjectId: subjectId,
          ),
          settings: settings,
        );

      case gallery:
        // Extract optional preselected subject ID for filtering
        final args = settings.arguments as Map<String, dynamic>?;
        final preselectedSubjectId = args?['subjectId'] as int?;

        return MaterialPageRoute<void>(
          builder: (_) => GalleryScreen(
            preselectedSubjectId: preselectedSubjectId,
          ),
          settings: settings,
        );

      case evidenceDetail:
        // Extract required evidences list and initial index
        final args = settings.arguments as Map<String, dynamic>?;
        final evidences = args?['evidences'] as List<Evidence>?;
        final initialIndex = args?['initialIndex'] as int?;

        if (evidences == null || initialIndex == null) {
          return _errorRoute(settings);
        }

        return MaterialPageRoute<void>(
          builder: (_) => EvidenceDetailScreen(
            evidences: evidences,
            initialIndex: initialIndex,
          ),
          settings: settings,
        );

      case students:
        // Extract optional preselected course ID for filtering
        final args = settings.arguments as Map<String, dynamic>?;
        final preselectedCourseId = args?['courseId'] as int?;

        return MaterialPageRoute<void>(
          builder: (_) => StudentsScreen(
            preselectedCourseId: preselectedCourseId,
          ),
          settings: settings,
        );

      case studentForm:
        // Extract optional student ID for editing
        final args = settings.arguments as Map<String, dynamic>?;
        final studentId = args?['studentId'] as int?;

        return MaterialPageRoute<void>(
          builder: (_) => StudentFormScreen(
            studentId: studentId,
          ),
          settings: settings,
        );

      case studentDetail:
        // Extract required student ID
        final args = settings.arguments as Map<String, dynamic>?;
        final studentId = args?['studentId'] as int?;

        if (studentId == null) {
          return _errorRoute(settings);
        }

        return MaterialPageRoute<void>(
          builder: (_) => StudentDetailScreen(
            studentId: studentId,
          ),
          settings: settings,
        );

      case faceTraining:
        // Extract required student for training
        final args = settings.arguments as Map<String, dynamic>?;
        final student = args?['student'] as Student?;

        if (student == null) {
          return _errorRoute(settings);
        }

        return MaterialPageRoute<bool>(
          builder: (_) => FaceTrainingScreen(
            student: student,
          ),
          settings: settings,
        );

      case courses:
        return MaterialPageRoute<void>(
          builder: (_) => const CoursesScreen(),
          settings: settings,
        );

      case courseForm:
        // Extract optional course ID for editing
        final args = settings.arguments as Map<String, dynamic>?;
        final courseId = args?['courseId'] as int?;

        return MaterialPageRoute<void>(
          builder: (_) => CourseFormScreen(
            courseId: courseId,
          ),
          settings: settings,
        );

      case archivedCourses:
        return MaterialPageRoute<void>(
          builder: (_) => const ArchivedCoursesScreen(),
          settings: settings,
        );

      case review:
        return MaterialPageRoute<void>(
          builder: (_) => const ReviewScreen(),
          settings: settings,
        );

      case config:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      case subjectsManagement:
        return MaterialPageRoute<void>(
          builder: (_) => const SubjectsManagementScreen(),
          settings: settings,
        );

      case syncSettings:
        return MaterialPageRoute<void>(
          builder: (_) => const SyncSettingsScreen(),
          settings: settings,
        );

      case sync:
        return MaterialPageRoute<void>(
          builder: (_) => const SyncScreen(),
          settings: settings,
        );

      default:
        return _errorRoute(settings);
    }
  }

  /// Error route for unknown paths
  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Ruta no encontrada',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                settings.name ?? 'Desconocida',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      settings: settings,
    );
  }
}
