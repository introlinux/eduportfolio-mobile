import 'package:eduportfolio/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:eduportfolio/features/gallery/presentation/widgets/evidence_card.dart';
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gallery screen - Display all captured evidences
class GalleryScreen extends ConsumerWidget {
  static const routeName = '/gallery';

  final int? preselectedSubjectId;

  const GalleryScreen({
    this.preselectedSubjectId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final evidencesAsync = ref.watch(filteredEvidencesProvider);
    final subjectsAsync = ref.watch(defaultSubjectsProvider);
    final selectedSubjectId = ref.watch(selectedSubjectFilterProvider);

    // Set preselected subject filter on first build
    if (preselectedSubjectId != null && selectedSubjectId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedSubjectFilterProvider.notifier).state =
            preselectedSubjectId;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería'),
        actions: [
          // Subject filter dropdown
          subjectsAsync.when(
            data: (subjects) {
              return PopupMenuButton<int?>(
                icon: Icon(
                  selectedSubjectId == null
                      ? Icons.filter_list
                      : Icons.filter_list_alt,
                ),
                tooltip: 'Filtrar por asignatura',
                onSelected: (subjectId) {
                  ref.read(selectedSubjectFilterProvider.notifier).state =
                      subjectId;
                },
                itemBuilder: (context) => [
                  PopupMenuItem<int?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(
                          selectedSubjectId == null
                              ? Icons.check
                              : Icons.check_box_outline_blank,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Todas las asignaturas'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  ...subjects.map(
                    (subject) => PopupMenuItem<int?>(
                      value: subject.id,
                      child: Row(
                        children: [
                          Icon(
                            selectedSubjectId == subject.id
                                ? Icons.check
                                : Icons.check_box_outline_blank,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(subject.name),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: evidencesAsync.when(
        data: (evidences) {
          if (evidences.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedSubjectId == null
                        ? 'No hay evidencias'
                        : 'No hay evidencias para esta asignatura',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Captura tu primera evidencia',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(filteredEvidencesProvider);
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: evidences.length,
              itemBuilder: (context, index) {
                final evidence = evidences[index];

                // Get subject for this evidence
                final subject = subjectsAsync.whenOrNull(
                  data: (subjects) => subjects.firstWhere(
                    (s) => s.id == evidence.subjectId,
                    orElse: () => subjects.first,
                  ),
                );

                return EvidenceCard(
                  evidence: evidence,
                  subject: subject,
                  onTap: () {
                    // Navigate to evidence detail
                    Navigator.of(context).pushNamed(
                      '/evidence-detail',
                      arguments: {'evidenceId': evidence.id},
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar evidencias',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(filteredEvidencesProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
