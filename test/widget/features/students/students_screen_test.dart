import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/features/students/presentation/providers/student_providers.dart';
import 'package:eduportfolio/features/students/presentation/screens/students_screen.dart';
import 'package:eduportfolio/features/students/presentation/widgets/student_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../helpers/widget_test_helper.dart';

void main() {
  group('StudentsScreen Widget Tests', () {
    // Mock data
    final now = DateTime.now();
    final mockStudents = [
      Student(
        id: 1,
        name: 'Juan Pérez',
        courseId: 1,
        faceEmbeddings: null,
        createdAt: now,
        updatedAt: now,
      ),
      Student(
        id: 2,
        name: 'María García',
        courseId: 1,
        faceEmbeddings: null,
        createdAt: now,
        updatedAt: now,
      ),
      Student(
        id: 3,
        name: 'Pedro López',
        courseId: 1,
        faceEmbeddings: null,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    testWidgets('muestra título "Estudiantes"', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const StudentsScreen(),
        overrides: [
          filteredStudentsProvider.overrideWith(
            (ref) => Future.value(mockStudents),
          ),
          selectedCourseFilterProvider.overrideWith((ref) => null),
        ],
      );

      // Assert
      expect(find.text('Estudiantes'), findsOneWidget);
    });

    testWidgets('muestra contador de estudiantes', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const StudentsScreen(),
        overrides: [
          filteredStudentsProvider.overrideWith(
            (ref) => Future.value(mockStudents),
          ),
          selectedCourseFilterProvider.overrideWith((ref) => null),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('3 estudiantes'), findsOneWidget);
    });

    testWidgets('muestra lista de estudiantes cuando hay datos',
        (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const StudentsScreen(),
        overrides: [
          filteredStudentsProvider.overrideWith(
            (ref) => Future.value(mockStudents),
          ),
          selectedCourseFilterProvider.overrideWith((ref) => null),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(StudentCard), findsNWidgets(3));
      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(find.text('María García'), findsOneWidget);
      expect(find.text('Pedro López'), findsOneWidget);
    });

    testWidgets('muestra mensaje cuando no hay estudiantes', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const StudentsScreen(),
        overrides: [
          filteredStudentsProvider.overrideWith(
            (ref) => Future.value([]),
          ),
          selectedCourseFilterProvider.overrideWith((ref) => null),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No hay estudiantes'), findsOneWidget);
      expect(find.text('Añade tu primer estudiante'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('muestra indicador de carga', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const StudentsScreen(),
        overrides: [
          filteredStudentsProvider.overrideWith(
            (ref) => Future(() async {
              await Future.delayed(const Duration(hours: 1));
              return [];
            }),
          ),
          selectedCourseFilterProvider.overrideWith((ref) => null),
        ],
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra error cuando falla la carga', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const StudentsScreen(),
        overrides: [
          filteredStudentsProvider.overrideWith(
            (ref) => Future.error(
              Exception('Error de base de datos'),
            ),
          ),
          selectedCourseFilterProvider.overrideWith((ref) => null),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error al cargar estudiantes'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('muestra FloatingActionButton para añadir estudiante',
        (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const StudentsScreen(),
        overrides: [
          filteredStudentsProvider.overrideWith(
            (ref) => Future.value(mockStudents),
          ),
          selectedCourseFilterProvider.overrideWith((ref) => null),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Añadir estudiante'), findsOneWidget);
    });

    testWidgets('tap en FAB intenta navegar a formulario', (tester) async {
      // Arrange
      var navigationCalled = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredStudentsProvider.overrideWith(
              (ref) => Future.value(mockStudents),
            ),
            selectedCourseFilterProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            home: const StudentsScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/student-form') {
                navigationCalled = true;
              }
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      expect(navigationCalled, isTrue);
    });

    testWidgets('pull to refresh invalida provider', (tester) async {
      // Arrange
      var invalidateCount = 0;
      final container = ProviderContainer(
        overrides: [
          filteredStudentsProvider.overrideWith((ref) {
            ref.onDispose(() => invalidateCount++);
            return Future.value(mockStudents);
          }),
          selectedCourseFilterProvider.overrideWith((ref) => null),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: StudentsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Simulate pull to refresh
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Assert
      expect(invalidateCount, greaterThan(0));
    });

    testWidgets('tap en StudentCard intenta navegar a detalle', (tester) async {
      // Arrange
      var navigationCalled = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredStudentsProvider.overrideWith(
              (ref) => Future.value(mockStudents),
            ),
            selectedCourseFilterProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            home: const StudentsScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/student-detail') {
                navigationCalled = true;
              }
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(StudentCard).first);
      await tester.pumpAndSettle();

      // Assert
      expect(navigationCalled, isTrue);
    });

    testWidgets('establece filtro de curso preseleccionado', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          filteredStudentsProvider.overrideWith(
            (ref) => Future.value(mockStudents),
          ),
          selectedCourseFilterProvider.overrideWith((ref) => null),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: StudentsScreen(preselectedCourseId: 1),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      final filterValue =
          container.read(selectedCourseFilterProvider.notifier).state;
      expect(filterValue, equals(1));
    });

    testWidgets('botón reintentar invalida provider', (tester) async {
      // Arrange
      var invalidateCount = 0;
      final container = ProviderContainer(
        overrides: [
          filteredStudentsProvider.overrideWith((ref) {
            ref.onDispose(() => invalidateCount++);
            return Future.error(
              Exception('Error'),
            );
          }),
          selectedCourseFilterProvider.overrideWith((ref) => null),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: StudentsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      // Assert
      expect(invalidateCount, greaterThan(0));
    });
  });
}
