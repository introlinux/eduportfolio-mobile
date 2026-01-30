import 'package:eduportfolio/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:eduportfolio/features/gallery/presentation/widgets/evidence_card.dart';
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:eduportfolio/features/students/presentation/providers/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gallery screen - Display all captured evidences with multi-select support
class GalleryScreen extends ConsumerStatefulWidget {
  static const routeName = '/gallery';

  final int? preselectedSubjectId;
  final ReviewStatusFilter? initialReviewFilter;

  const GalleryScreen({
    this.preselectedSubjectId,
    this.initialReviewFilter,
    super.key,
  });

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  // Multi-selection state
  final Set<int> _selectedEvidenceIds = {};
  bool get _isSelectionMode => _selectedEvidenceIds.isNotEmpty;

  // Track if initial filters have been set (to avoid resetting them)
  bool _hasSetInitialFilters = false;

  void _toggleSelection(int evidenceId) {
    setState(() {
      if (_selectedEvidenceIds.contains(evidenceId)) {
        _selectedEvidenceIds.remove(evidenceId);
      } else {
        _selectedEvidenceIds.add(evidenceId);
      }
    });
  }

  void _enterSelectionMode(int evidenceId) {
    setState(() {
      _selectedEvidenceIds.add(evidenceId);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedEvidenceIds.clear();
    });
  }

  void _selectAll(List<int> evidenceIds) {
    setState(() {
      _selectedEvidenceIds.addAll(evidenceIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evidencesAsync = ref.watch(filteredEvidencesProvider);
    final subjectsAsync = ref.watch(defaultSubjectsProvider);
    final studentsAsync = ref.watch(filteredStudentsProvider);
    final selectedSubjectId = ref.watch(selectedSubjectFilterProvider);
    final selectedStudentId = ref.watch(selectedStudentFilterProvider);
    final reviewStatusFilter = ref.watch(reviewStatusFilterProvider);

    // Set initial filters only once (on first build)
    if (!_hasSetInitialFilters) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Set preselected subject filter if provided
        if (widget.preselectedSubjectId != null) {
          ref.read(selectedSubjectFilterProvider.notifier).state =
              widget.preselectedSubjectId;
        }

        // Set initial review filter if provided
        if (widget.initialReviewFilter != null) {
          ref.read(reviewStatusFilterProvider.notifier).state =
              widget.initialReviewFilter!;
        }

        // Mark that initial filters have been set
        setState(() {
          _hasSetInitialFilters = true;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        title: Text(
          _isSelectionMode
              ? '${_selectedEvidenceIds.length} seleccionadas'
              : 'Galería',
        ),
        actions: _isSelectionMode
            ? _buildSelectionActions(evidencesAsync.value)
            : _buildFilterActions(
                subjectsAsync,
                studentsAsync,
                selectedSubjectId,
                selectedStudentId,
                reviewStatusFilter,
              ),
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
                    _getEmptyStateMessage(
                      selectedSubjectId,
                      selectedStudentId,
                      reviewStatusFilter,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
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
                final isSelected = _selectedEvidenceIds.contains(evidence.id);

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
                  isSelected: isSelected,
                  isSelectionMode: _isSelectionMode,
                  onTap: () {
                    if (_isSelectionMode) {
                      // In selection mode, tap toggles selection
                      _toggleSelection(evidence.id!);
                    } else {
                      // Normal mode, navigate to detail
                      Navigator.of(context).pushNamed(
                        '/evidence-detail',
                        arguments: {
                          'evidences': evidences,
                          'initialIndex': index,
                        },
                      );
                    }
                  },
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      // Long press enters selection mode
                      _enterSelectionMode(evidence.id!);
                    }
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

  List<Widget> _buildFilterActions(
    AsyncValue subjectsAsync,
    AsyncValue studentsAsync,
    int? selectedSubjectId,
    int? selectedStudentId,
    ReviewStatusFilter reviewStatusFilter,
  ) {
    return [
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
      // Student filter dropdown
      studentsAsync.when(
        data: (students) {
          if (students.isEmpty) return const SizedBox.shrink();

          return PopupMenuButton<int?>(
            icon: Icon(
              selectedStudentId == null
                  ? Icons.person_outline
                  : Icons.person,
            ),
            tooltip: 'Filtrar por estudiante',
            onSelected: (studentId) {
              ref.read(selectedStudentFilterProvider.notifier).state =
                  studentId;
            },
            itemBuilder: (context) => [
              PopupMenuItem<int?>(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      selectedStudentId == null
                          ? Icons.check
                          : Icons.check_box_outline_blank,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Todos los estudiantes'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ...students.map(
                (student) => PopupMenuItem<int?>(
                  value: student.id,
                  child: Row(
                    children: [
                      Icon(
                        selectedStudentId == student.id
                            ? Icons.check
                            : Icons.check_box_outline_blank,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(student.name),
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
      // Review status filter toggle (pending/all)
      IconButton(
        icon: Icon(
          Icons.pending_actions,
          color: reviewStatusFilter == ReviewStatusFilter.pending
              ? Colors.red
              : null,
        ),
        tooltip: reviewStatusFilter == ReviewStatusFilter.pending
            ? 'Mostrando pendientes (toca para ver todas)'
            : 'Filtrar pendientes de revisar',
        onPressed: () {
          // Toggle between pending and all
          final newFilter = reviewStatusFilter == ReviewStatusFilter.pending
              ? ReviewStatusFilter.all
              : ReviewStatusFilter.pending;
          ref.read(reviewStatusFilterProvider.notifier).state = newFilter;
        },
      ),
    ];
  }

  List<Widget> _buildSelectionActions(List? evidences) {
    return [
      // Select all
      IconButton(
        icon: const Icon(Icons.select_all),
        tooltip: 'Seleccionar todas',
        onPressed: evidences != null
            ? () {
                final ids = evidences.map((e) => e.id as int).toList();
                _selectAll(ids);
              }
            : null,
      ),
      // More actions menu
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (action) async {
          switch (action) {
            case 'assign_subject':
              await _handleAssignSubject(context, ref);
              break;
            case 'assign_student':
              await _handleAssignStudent(context, ref);
              break;
            case 'delete':
              await _handleDeleteSelected(context, ref);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'assign_subject',
            child: Row(
              children: [
                Icon(Icons.book),
                SizedBox(width: 12),
                Text('Asignar asignatura'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'assign_student',
            child: Row(
              children: [
                Icon(Icons.person),
                SizedBox(width: 12),
                Text('Asignar estudiante'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 12),
                Text('Eliminar', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _handleAssignSubject(BuildContext context, WidgetRef ref) async {
    final subjectsAsync = ref.read(defaultSubjectsProvider);
    final subjects = subjectsAsync.value;

    if (subjects == null || subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay asignaturas disponibles')),
      );
      return;
    }

    final selectedSubjectId = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar asignatura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: subjects.map((subject) {
            return ListTile(
              title: Text(subject.name),
              onTap: () => Navigator.of(context).pop(subject.id),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selectedSubjectId == null || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final useCase = ref.read(updateEvidencesSubjectUseCaseProvider);
      final count = await useCase(_selectedEvidenceIds.toList(), selectedSubjectId);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count evidencias actualizadas'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh and clear selection
        ref.invalidate(filteredEvidencesProvider);
        _clearSelection();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleAssignStudent(BuildContext context, WidgetRef ref) async {
    final studentsAsync = ref.read(filteredStudentsProvider);
    final students = studentsAsync.value;

    if (students == null || students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay estudiantes disponibles')),
      );
      return;
    }

    final selectedStudentId = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar estudiante'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                title: Text(student.name),
                onTap: () => Navigator.of(context).pop(student.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selectedStudentId == null || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final useCase = ref.read(assignEvidencesToStudentUseCaseProvider);
      final count = await useCase(_selectedEvidenceIds.toList(), selectedStudentId);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count evidencias asignadas'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh and clear selection
        ref.invalidate(filteredEvidencesProvider);
        ref.invalidate(pendingEvidencesCountProvider);
        _clearSelection();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleDeleteSelected(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evidencias'),
        content: Text(
          '¿Estás seguro de que quieres eliminar ${_selectedEvidenceIds.length} evidencias?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final useCase = ref.read(deleteEvidencesUseCaseProvider);
      final count = await useCase(_selectedEvidenceIds.toList());

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count evidencias eliminadas'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh and clear selection
        ref.invalidate(filteredEvidencesProvider);
        ref.invalidate(pendingEvidencesCountProvider);
        ref.invalidate(storageInfoProvider);
        _clearSelection();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getEmptyStateMessage(
    int? subjectId,
    int? studentId,
    ReviewStatusFilter reviewFilter,
  ) {
    // Build base message
    String baseMessage = '';

    if (subjectId != null && studentId != null) {
      baseMessage = 'No hay evidencias para este estudiante y asignatura';
    } else if (subjectId != null) {
      baseMessage = 'No hay evidencias para esta asignatura';
    } else if (studentId != null) {
      baseMessage = 'No hay evidencias para este estudiante';
    } else {
      baseMessage = 'No hay evidencias';
    }

    // Add review filter context
    if (reviewFilter == ReviewStatusFilter.pending) {
      return baseMessage.replaceAll(
          'No hay evidencias', 'No hay evidencias pendientes de revisar');
    } else if (reviewFilter == ReviewStatusFilter.reviewed) {
      return baseMessage.replaceAll(
          'No hay evidencias', 'No hay evidencias revisadas');
    }

    return baseMessage;
  }
}
