import 'dart:io';

import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/features/capture/presentation/providers/capture_providers.dart';
import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:eduportfolio/features/home/presentation/providers/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Capture screen - For capturing and saving evidence
class CaptureScreen extends ConsumerStatefulWidget {
  static const routeName = '/capture';

  final int? preselectedSubjectId;

  const CaptureScreen({
    this.preselectedSubjectId,
    super.key,
  });

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  @override
  void initState() {
    super.initState();
    // Set preselected subject if provided
    if (widget.preselectedSubjectId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedSubjectIdProvider.notifier).state =
            widget.preselectedSubjectId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(defaultSubjectsProvider);
    final selectedImagePath = ref.watch(selectedImagePathProvider);
    final selectedSubjectId = ref.watch(selectedSubjectIdProvider);
    final isSaving = ref.watch(isSavingProvider);

    final canSave = selectedImagePath != null &&
        selectedSubjectId != null &&
        !isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capturar evidencia'),
        actions: [
          if (isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subject selector
            subjectsAsync.when(
              data: (subjects) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asignatura',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: selectedSubjectId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecciona una asignatura',
                      ),
                      items: subjects
                          .map(
                            (subject) => DropdownMenuItem(
                              value: subject.id,
                              child: Text(subject.name),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              ref.read(selectedSubjectIdProvider.notifier).state =
                                  value;
                            },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Text(
                'Error al cargar asignaturas: $error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),

            const SizedBox(height: 24),

            // Image preview
            Text(
              'Imagen',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: selectedImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(selectedImagePath),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sin imagen seleccionada',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : _captureFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: canSave ? _saveEvidence : null,
              icon: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(isSaving ? 'Guardando...' : 'Guardar evidencia'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    final imageCaptureDataSource = ref.read(imageCaptureDataSourceProvider);
    final imagePath = await imageCaptureDataSource.captureFromCamera();

    if (imagePath != null && mounted) {
      ref.read(selectedImagePathProvider.notifier).state = imagePath;
    }
  }

  Future<void> _pickFromGallery() async {
    final imageCaptureDataSource = ref.read(imageCaptureDataSourceProvider);
    final imagePath = await imageCaptureDataSource.pickFromGallery();

    if (imagePath != null && mounted) {
      ref.read(selectedImagePathProvider.notifier).state = imagePath;
    }
  }

  Future<void> _saveEvidence() async {
    final imagePath = ref.read(selectedImagePathProvider);
    final subjectId = ref.read(selectedSubjectIdProvider);

    if (imagePath == null || subjectId == null) return;

    // Set loading state
    ref.read(isSavingProvider.notifier).state = true;

    try {
      final saveEvidenceUseCase = ref.read(saveEvidenceUseCaseProvider);
      final activeCourse = await ref.read(activeCourseProvider.future);

      // Save evidence
      await saveEvidenceUseCase(
        tempImagePath: imagePath,
        subjectId: subjectId,
        courseId: activeCourse?.id,
      );

      // Invalidate home providers to refresh counts
      ref.invalidate(pendingEvidencesCountProvider);
      ref.invalidate(storageInfoProvider);

      if (mounted) {
        // Reset state
        ref.read(selectedImagePathProvider.notifier).state = null;
        ref.read(selectedSubjectIdProvider.notifier).state = null;
        ref.read(isSavingProvider.notifier).state = false;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidencia guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ref.read(isSavingProvider.notifier).state = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Reset state when leaving screen
    ref.read(selectedImagePathProvider.notifier).state = null;
    ref.read(selectedSubjectIdProvider.notifier).state = null;
    ref.read(isSavingProvider.notifier).state = false;
    super.dispose();
  }
}
