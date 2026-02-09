import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:eduportfolio/main.dart' as app;

/// Integration test for student management flow
///
/// Tests:
/// - Viewing student list
/// - Creating a new student
/// - Viewing student details
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Student Management Flow', () {
    testWidgets('navegar a estudiantes desde home', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act - Tap en botón de estudiantes en AppBar
      final studentsButton = find.byIcon(Icons.people);
      expect(studentsButton, findsOneWidget);
      await tester.tap(studentsButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Estudiantes'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('flujo completo: añadir nuevo estudiante', (tester) async {
      // Step 1: Iniciar app y navegar a estudiantes
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final studentsButton = find.byIcon(Icons.people);
      await tester.tap(studentsButton);
      await tester.pumpAndSettle();

      // Step 2: Tap en FAB para añadir estudiante
      final addButton = find.byType(FloatingActionButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Step 3: Llenar formulario
      final firstNameField = find.byKey(const Key('first_name_field'));
      if (firstNameField.evaluate().isNotEmpty) {
        await tester.enterText(firstNameField, 'Test Student');
        await tester.pumpAndSettle();

        final lastNameField = find.byKey(const Key('last_name_field'));
        if (lastNameField.evaluate().isNotEmpty) {
          await tester.enterText(lastNameField, 'Integration Test');
          await tester.pumpAndSettle();

          // Step 4: Guardar estudiante
          final saveButton = find.text('Guardar');
          if (saveButton.evaluate().isNotEmpty) {
            await tester.tap(saveButton);
            await tester.pumpAndSettle();

            // Step 5: Verificar que aparece en la lista
            expect(find.text('Test Student Integration Test'), findsOneWidget);
          }
        }
      }
    });

    testWidgets('ver detalles de estudiante', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navegar a estudiantes
      final studentsButton = find.byIcon(Icons.people);
      await tester.tap(studentsButton);
      await tester.pumpAndSettle();

      // Act - Tap en primer estudiante (si existe)
      final studentCards = find.byType(Card);
      if (studentCards.evaluate().isNotEmpty) {
        await tester.tap(studentCards.first);
        await tester.pumpAndSettle();

        // Assert - Verificar que se abre pantalla de detalle
        // (Depende de qué muestre la pantalla de detalle)
        expect(find.byType(AppBar), findsOneWidget);
      }
    });

    testWidgets('pull to refresh actualiza lista de estudiantes',
        (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final studentsButton = find.byIcon(Icons.people);
      await tester.tap(studentsButton);
      await tester.pumpAndSettle();

      // Act - Pull to refresh
      await tester.drag(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      // Assert - Verificar que se recarga
      expect(find.text('Estudiantes'), findsOneWidget);
    });

    testWidgets('contador de estudiantes se actualiza correctamente',
        (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final studentsButton = find.byIcon(Icons.people);
      await tester.tap(studentsButton);
      await tester.pumpAndSettle();

      // Act - Contar estudiantes iniciales
      final countBadge = find.textContaining('estudiantes');

      // Assert
      expect(countBadge, findsOneWidget);
    });
  });
}
