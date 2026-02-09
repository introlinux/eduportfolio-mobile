import 'package:eduportfolio/core/domain/entities/course.dart';
import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:eduportfolio/features/courses/presentation/screens/courses_screen.dart';
import 'package:eduportfolio/features/courses/presentation/widgets/course_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../helpers/widget_test_helper.dart';

void main() {
  group('CoursesScreen Widget Tests', () {
    // Mock data
    final mockCourses = [
      Course(
        id: 1,
        name: '1º A - Curso 2023/24',
        startDate: DateTime(2023, 9, 1),
        createdAt: DateTime(2023, 9, 1),
        isActive: true,
      ),
      Course(
        id: 2,
        name: '2º B - Curso 2023/24',
        startDate: DateTime(2023, 9, 1),
        createdAt: DateTime(2023, 9, 1),
        isActive: false,
      ),
    ];

    final mockActiveCourse = Course(
      id: 1,
      name: '1º A - Curso 2023/24',
      startDate: DateTime(2023, 9, 1),
      createdAt: DateTime(2023, 9, 1),
      isActive: true,
    );

    testWidgets('muestra título "Gestión de Cursos"', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const CoursesScreen(),
        overrides: [
          activeCoursesProvider.overrideWith(
            (ref) => Future.value(mockCourses),
          ),
        ],
      );

      // Assert
      expect(find.text('Gestión de Cursos'), findsOneWidget);
    });

    testWidgets('muestra botón para ver cursos archivados', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const CoursesScreen(),
        overrides: [
          activeCoursesProvider.overrideWith(
            (ref) => Future.value(mockCourses),
          ),
        ],
      );

      // Assert
      expect(findIconButton(Icons.archive_outlined), findsOneWidget);
    });

    testWidgets('muestra lista de cursos cuando hay datos', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const CoursesScreen(),
        overrides: [
          activeCoursesProvider.overrideWith(
            (ref) => Future.value(mockCourses),
          ),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(CourseCard), findsNWidgets(2));
      expect(find.textContaining('1º A'), findsOneWidget);
      expect(find.textContaining('2º B'), findsOneWidget);
    });

    testWidgets('muestra mensaje cuando no hay cursos', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const CoursesScreen(),
        overrides: [
          activeCoursesProvider.overrideWith(
            (ref) => Future.value([]),
          ),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No hay cursos'), findsOneWidget);
      expect(find.text('Crea tu primer curso escolar'), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    });

    testWidgets('muestra indicador de carga', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const CoursesScreen(),
        overrides: [
          activeCoursesProvider.overrideWith(
            (ref) => Future(() async {
              await Future.delayed(const Duration(hours: 1));
              return [];
            }),
          ),
        ],
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra error cuando falla la carga', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const CoursesScreen(),
        overrides: [
          activeCoursesProvider.overrideWith(
            (ref) => Future.error(
              Exception('Error al cargar'),
            ),
          ),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error al cargar cursos'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('muestra FloatingActionButton para crear curso',
        (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const CoursesScreen(),
        overrides: [
          activeCoursesProvider.overrideWith(
            (ref) => Future.value(mockCourses),
          ),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Crear curso'), findsOneWidget);
    });

    testWidgets('tap en FAB intenta navegar a formulario', (tester) async {
      // Arrange
      var navigationCalled = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeCoursesProvider.overrideWith(
              (ref) => Future.value(mockCourses),
            ),
          ],
          child: MaterialApp(
            home: const CoursesScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/course-form') {
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

    testWidgets('pull to refresh invalida providers', (tester) async {
      // Arrange
      var invalidateCount = 0;
      final container = ProviderContainer(
        overrides: [
          activeCoursesProvider.overrideWith((ref) {
            ref.onDispose(() => invalidateCount++);
            return Future.value(mockCourses);
          }),
          allCoursesProvider.overrideWith((ref) {
            return Future.value(mockCourses);
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CoursesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Simulate pull to refresh
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Assert
      expect(invalidateCount, greaterThan(0));
    });

    testWidgets('tap en CourseCard intenta navegar a edición', (tester) async {
      // Arrange
      var navigationCalled = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeCoursesProvider.overrideWith(
              (ref) => Future.value(mockCourses),
            ),
          ],
          child: MaterialApp(
            home: const CoursesScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/course-form') {
                navigationCalled = true;
              }
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(CourseCard).first);
      await tester.pumpAndSettle();

      // Assert
      expect(navigationCalled, isTrue);
    });

    // Note: Test for archive dialog would require mocking CourseCard interactions
    // which is better done in CourseCard widget tests
  });
}
