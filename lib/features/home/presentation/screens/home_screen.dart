import 'package:eduportfolio/features/courses/presentation/widgets/active_course_indicator.dart';
import 'package:eduportfolio/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:eduportfolio/features/gallery/presentation/screens/gallery_screen.dart';
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:eduportfolio/features/home/presentation/widgets/pending_badge.dart';
import 'package:eduportfolio/features/home/presentation/widgets/storage_indicator.dart';
import 'package:eduportfolio/features/home/presentation/widgets/subject_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home screen - Main screen of the application
///
/// Shows:
/// - Grid of default subjects
/// - Pending evidences count
/// - Storage information
/// - FAB for quick capture
class HomeScreen extends ConsumerWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(defaultSubjectsProvider);
    final pendingCountAsync = ref.watch(pendingEvidencesCountProvider);
    final storageInfoAsync = ref.watch(storageInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eduportfolio'),
        actions: [
          // Pending badge (tappable - navigates to gallery with pending filter)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: pendingCountAsync.when(
                data: (count) => PendingBadge(
                  count: count,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GalleryScreen(
                          initialReviewFilter: ReviewStatusFilter.pending,
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
          // Students button
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.of(context).pushNamed('/students');
            },
            tooltip: 'Ver estudiantes',
          ),
          // Gallery button
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              Navigator.of(context).pushNamed('/gallery');
            },
            tooltip: 'Ver galería',
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/config');
            },
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: Column(
        children: [
          // Active course indicator
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ActiveCourseIndicator(),
          ),
          // Storage indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: storageInfoAsync.when(
              data: (info) => Align(
                alignment: Alignment.centerLeft,
                child: StorageIndicator(info: info),
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          // Subjects grid
          Expanded(
            child: subjectsAsync.when(
              data: (subjects) {
                if (subjects.isEmpty) {
                  return const Center(
                    child: Text('No hay asignaturas disponibles'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return SubjectCard(
                      subject: subject,
                      onTap: () {
                        // Navigate to quick capture screen with preselected subject
                        Navigator.of(context).pushNamed(
                          '/quick-capture',
                          arguments: {
                            'subject': subject,
                            'subjectId': subject.id,
                          },
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar asignaturas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(defaultSubjectsProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
