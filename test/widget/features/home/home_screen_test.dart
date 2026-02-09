import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:eduportfolio/features/home/domain/usecases/get_storage_info_usecase.dart';
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:eduportfolio/features/home/presentation/screens/home_screen.dart';
import 'package:eduportfolio/features/home/presentation/widgets/storage_indicator.dart';
import 'package:eduportfolio/features/home/presentation/widgets/subject_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../helpers/widget_test_helper.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    // Mock data
    final mockSubjects = [
      Subject(
        id: 1,
        name: 'Matemáticas',
        color: Colors.blue.value.toString(),
        icon: Icons.calculate.codePoint.toString(),
        createdAt: DateTime(2024, 1, 1),
      ),
      Subject(
        id: 2,
        name: 'Lengua',
        color: Colors.red.value.toString(),
        icon: Icons.book.codePoint.toString(),
        createdAt: DateTime(2024, 1, 1),
      ),
      Subject(
        id: 3,
        name: 'Ciencias',
        color: Colors.green.value.toString(),
        icon: Icons.science.codePoint.toString(),
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

    final mockStorageInfo = StorageInfo(
      totalSizeBytes: 500000000, // 500MB
      evidenceCount: 10,
    );

    testWidgets('muestra el título "Eduportfolio" en AppBar', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const HomeScreen(),
        overrides: [
          defaultSubjectsProvider.overrideWith(
            (ref) => Future.value(mockSubjects),
          ),
          pendingEvidencesCountProvider.overrideWith(
            (ref) => Future.value(0),
          ),
          storageInfoProvider.overrideWith(
            (ref) => Future.value(mockStorageInfo),
          ),
        ],
      );

      // Assert
      expect(find.text('Eduportfolio'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('muestra botones de navegación en AppBar', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const HomeScreen(),
        overrides: [
          defaultSubjectsProvider.overrideWith(
            (ref) => Future.value(mockSubjects),
          ),
          pendingEvidencesCountProvider.overrideWith(
            (ref) => Future.value(0),
          ),
          storageInfoProvider.overrideWith(
            (ref) => Future.value(mockStorageInfo),
          ),
        ],
      );

      // Assert
      expect(findIconButton(Icons.people), findsOneWidget);
      expect(findIconButton(Icons.photo_library), findsOneWidget);
      expect(findIconButton(Icons.settings), findsOneWidget);
    });

    testWidgets('muestra grid de asignaturas cuando hay datos', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const HomeScreen(),
        overrides: [
          defaultSubjectsProvider.overrideWith(
            (ref) => Future.value(mockSubjects),
          ),
          pendingEvidencesCountProvider.overrideWith(
            (ref) => Future.value(0),
          ),
          storageInfoProvider.overrideWith(
            (ref) => Future.value(mockStorageInfo),
          ),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(SubjectCard), findsNWidgets(3));
      expect(find.text('Matemáticas'), findsOneWidget);
      expect(find.text('Lengua'), findsOneWidget);
      expect(find.text('Ciencias'), findsOneWidget);
    });

    testWidgets('muestra mensaje cuando no hay asignaturas', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const HomeScreen(),
        overrides: [
          defaultSubjectsProvider.overrideWith(
            (ref) => Future.value([]),
          ),
          pendingEvidencesCountProvider.overrideWith(
            (ref) => Future.value(0),
          ),
          storageInfoProvider.overrideWith(
            (ref) => Future.value(mockStorageInfo),
          ),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No hay asignaturas disponibles'), findsOneWidget);
      expect(find.byType(SubjectCard), findsNothing);
    });

    testWidgets('muestra indicador de carga mientras carga asignaturas',
        (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const HomeScreen(),
        overrides: [
          defaultSubjectsProvider.overrideWith(
            (ref) => Future<List<Subject>>(() async {
              await Future.delayed(const Duration(hours: 1));
              return [];
            }),
          ),
          pendingEvidencesCountProvider.overrideWith(
            (ref) => Future.value(0),
          ),
          storageInfoProvider.overrideWith(
            (ref) => Future.value(mockStorageInfo),
          ),
        ],
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra error cuando falla la carga de asignaturas',
        (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const HomeScreen(),
        overrides: [
          defaultSubjectsProvider.overrideWith(
            (ref) => Future<List<Subject>>.error(
              Exception('Error de red'),
            ),
          ),
          pendingEvidencesCountProvider.overrideWith(
            (ref) => Future.value(0),
          ),
          storageInfoProvider.overrideWith(
            (ref) => Future.value(mockStorageInfo),
          ),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error al cargar asignaturas'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('botón reintentar invalida provider', (tester) async {
      // Arrange
      var invalidateCount = 0;
      final container = ProviderContainer(
        overrides: [
          defaultSubjectsProvider.overrideWith((ref) {
            ref.onDispose(() => invalidateCount++);
            return Future<List<Subject>>.error(
              Exception('Error'),
            );
          }),
          pendingEvidencesCountProvider.overrideWith(
            (ref) => Future.value(0),
          ),
          storageInfoProvider.overrideWith(
            (ref) => Future.value(mockStorageInfo),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      // Assert
      expect(invalidateCount, greaterThan(0));
    });

    testWidgets('muestra información de almacenamiento', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const HomeScreen(),
        overrides: [
          defaultSubjectsProvider.overrideWith(
            (ref) => Future.value(mockSubjects),
          ),
          pendingEvidencesCountProvider.overrideWith(
            (ref) => Future.value(0),
          ),
          storageInfoProvider.overrideWith(
            (ref) => Future.value(mockStorageInfo),
          ),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(StorageIndicator), findsOneWidget);
    });

    testWidgets('muestra badge de evidencias pendientes', (tester) async {
      // Arrange
      await pumpTestWidget(
        tester,
        const HomeScreen(),
        overrides: [
          defaultSubjectsProvider.overrideWith(
            (ref) => Future.value(mockSubjects),
          ),
          pendingEvidencesCountProvider.overrideWith(
            (ref) => Future.value(5),
          ),
          storageInfoProvider.overrideWith(
            (ref) => Future.value(mockStorageInfo),
          ),
        ],
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('tap en SubjectCard intenta navegar a quick-capture',
        (tester) async {
      // Arrange
      var navigationCalled = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            defaultSubjectsProvider.overrideWith(
              (ref) => Future.value(mockSubjects),
            ),
            pendingEvidencesCountProvider.overrideWith(
              (ref) => Future.value(0),
            ),
            storageInfoProvider.overrideWith(
              (ref) => Future.value(mockStorageInfo),
            ),
          ],
          child: MaterialApp(
            home: const HomeScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/quick-capture') {
                navigationCalled = true;
              }
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(SubjectCard).first);
      await tester.pumpAndSettle();

      // Assert
      expect(navigationCalled, isTrue);
    });
  });
}
