import 'package:eduportfolio/core/providers/core_providers.dart';
import 'package:eduportfolio/features/students/presentation/providers/student_providers.dart';
import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Student form screen - Create or edit a student
class StudentFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/student-form';

  final int? studentId;

  const StudentFormScreen({
    this.studentId,
    super.key,
  });

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.studentId != null) {
      _loadStudent();
    }
  }

  Future<void> _loadStudent() async {
    setState(() => _isLoading = true);

    try {
      final student = await ref
          .read(getStudentByIdUseCaseProvider)
          .call(widget.studentId!);

      if (student != null && mounted) {
        _nameController.text = student.name;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estudiante: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Get active course
      final activeCourse =
          await ref.read(courseRepositoryProvider).getActiveCourse();

      if (activeCourse == null) {
        throw Exception('No hay un curso activo');
      }

      final name = _nameController.text.trim();

      if (widget.studentId == null) {
        // Create new student
        await ref.read(createStudentUseCaseProvider).call(
              courseId: activeCourse.id!,
              name: name,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estudiante creado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing student
        final student = await ref
            .read(getStudentByIdUseCaseProvider)
            .call(widget.studentId!);

        if (student == null) {
          throw Exception('Estudiante no encontrado');
        }

        await ref.read(updateStudentUseCaseProvider).call(
              id: widget.studentId!,
              courseId: student.courseId,
              name: name,
              createdAt: student.createdAt,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estudiante actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Invalidate providers to refresh lists
      ref.invalidate(filteredStudentsProvider);
      // Invalidate student count for the course
      if (activeCourse.id != null) {
        ref.invalidate(courseStudentCountProvider(activeCourse.id!));
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.studentId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar estudiante' : 'Nuevo estudiante'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info card
                    Card(
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isEditing
                                    ? 'Actualiza la información del estudiante'
                                    : 'El estudiante se añadirá al curso activo',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del estudiante',
                        hintText: 'Ejemplo: Juan Pérez',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        if (value.trim().length < 2) {
                          return 'El nombre debe tener al menos 2 caracteres';
                        }
                        return null;
                      },
                      autofocus: !isEditing,
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 32),
                    // Save button
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveStudent,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(isEditing ? 'Guardar cambios' : 'Crear estudiante'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cancel button
                    OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
