import 'package:flutter/material.dart';

import '../../features/home/presentation/screens/home_screen.dart';

/// App routes configuration
class AppRoutes {
  AppRoutes._(); // Private constructor to prevent instantiation

  // Route names
  static const String home = '/';
  static const String capture = '/capture';
  static const String gallery = '/gallery';
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

      // TODO: Add other routes when screens are implemented
      // case capture:
      //   return MaterialPageRoute<void>(
      //     builder: (_) => const CaptureScreen(),
      //     settings: settings,
      //   );

      default:
        return _errorRoute(settings);
    }
  }

  /// Error route for unknown paths
  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => Scaffold(
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
                style: Theme.of(_).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                settings.name ?? 'Desconocida',
                style: Theme.of(_).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      settings: settings,
    );
  }
}
