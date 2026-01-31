import 'package:eduportfolio/core/routing/routes.dart';
import 'package:eduportfolio/core/services/face_recognition/face_recognition_providers.dart';
import 'package:eduportfolio/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences before the app starts
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Override sharedPreferencesProvider with pre-initialized instance
        sharedPreferencesProvider.overrideWith((ref) => sharedPreferences),
      ],
      child: const EduportfolioApp(),
    ),
  );
}

class EduportfolioApp extends ConsumerWidget {
  const EduportfolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize face recognition service on app startup
    // This ensures models are loaded before user tries to use them
    ref.watch(faceRecognitionInitializedProvider);

    return MaterialApp(
      title: 'Eduportfolio',
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.home,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4), // Material 3 purple
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
        ),
      ),
    );
  }
}
