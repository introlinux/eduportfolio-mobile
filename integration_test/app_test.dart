import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:eduportfolio/main.dart' as app;

/// Basic integration test for the app
///
/// Tests the main flow of the application
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('app inicia correctamente y muestra pantalla home',
        (tester) async {
      // Arrange & Act
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Assert
      expect(find.text('Eduportfolio'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('navegación a pantalla de estudiantes funciona',
        (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act - Tap en botón de estudiantes
      final studentsButton = find.byIcon(Icons.people);
      expect(studentsButton, findsOneWidget);
      await tester.tap(studentsButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Estudiantes'), findsOneWidget);
    });

    testWidgets('navegación a pantalla de galería funciona', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act - Tap en botón de galería
      final galleryButton = find.byIcon(Icons.photo_library);
      expect(galleryButton, findsOneWidget);
      await tester.tap(galleryButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Galería'), findsOneWidget);
    });

    testWidgets('navegación a configuración funciona', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act - Tap en botón de configuración
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Configuración'), findsOneWidget);
    });
  });
}
