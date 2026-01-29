import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/features/capture/presentation/screens/capture_screen.dart';
import 'package:eduportfolio/features/capture/presentation/screens/quick_capture_screen.dart';
import 'package:eduportfolio/features/gallery/presentation/screens/evidence_detail_screen.dart';
import 'package:eduportfolio/features/gallery/presentation/screens/gallery_screen.dart';
import 'package:eduportfolio/features/home/presentation/screens/home_screen.dart';
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
  static const String config = '/config';
  static const String review = '/review';

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
        // Extract required evidence ID
        final args = settings.arguments as Map<String, dynamic>?;
        final evidenceId = args?['evidenceId'] as int?;

        if (evidenceId == null) {
          return _errorRoute(settings);
        }

        return MaterialPageRoute<void>(
          builder: (_) => EvidenceDetailScreen(
            evidenceId: evidenceId,
          ),
          settings: settings,
        );

      // TODO: Add other routes when screens are implemented

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
