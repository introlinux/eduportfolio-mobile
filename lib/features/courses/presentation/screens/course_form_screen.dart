import 'package:eduportfolio/features/courses/presentation/providers/course_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Course form screen - Create or edit a course
class CourseFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/course-form';

  final int? courseId;

  const CourseFormScreen({
    this.courseId,
    super.key,
  });

  @override
  ConsumerState<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends ConsumerState<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _startDate;
  bool _setAsActive = true;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.courseId != null) {
      _loadCourse();
    } else {
      // Default start date for new course
      _startDate = DateTime.now();
    }
  }

  Future<void> _loadCourse() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(courseRepositoryProvider);
      final course = await repository.getCourseById(widget.courseId!);

      if (course != null && mounted) {
        _nameController.text = course.name;
        _startDate = course.startDate;
        _setAsActive = course.isActive;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar curso: $e'),
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

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una fecha de inicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();

      if (widget.courseId == null) {
        // Create new course
        await ref.read(createCourseUseCaseProvider).call(
              name: name,
              startDate: _startDate!,
              setAsActive: _setAsActive,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Curso creado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing course
        final repository = ref.read(courseRepositoryProvider);
        final course = await repository.getCourseById(widget.courseId!);

        if (course == null) {
          throw Exception('Curso no encontrado');
        }

        await ref.read(updateCourseUseCaseProvider).call(
              id: widget.courseId!,
              name: name,
              startDate: _startDate!,
              createdAt: course.createdAt,
              endDate: course.endDate,
              isActive: _setAsActive,
            );

        // If we changed the active status, update it properly
        if (_setAsActive && !course.isActive) {
          await ref.read(setActiveCourseUseCaseProvider).call(widget.courseId!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Curso actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Invalidate providers to refresh lists
      ref.invalidate(allCoursesProvider);
      ref.invalidate(activeCourseProvider);

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

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && mounted) {
      setState(() => _startDate = picked);
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
    final isEditing = widget.courseId != null;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar curso' : 'Nuevo curso'),
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
                                    ? 'Actualiza la información del curso escolar'
                                    : 'Crea un nuevo curso escolar (ej: "Curso 2024-25")',
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
                        labelText: 'Nombre del curso',
                        hintText: 'Curso 2024-25',
                        prefixIcon: Icon(Icons.school),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        if (value.trim().length < 4) {
                          return 'El nombre debe tener al menos 4 caracteres';
                        }
                        return null;
                      },
                      autofocus: !isEditing,
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 16),
                    // Start date field
                    InkWell(
                      onTap: _isSaving ? null : _selectStartDate,
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de inicio',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startDate != null
                              ? dateFormat.format(_startDate!)
                              : 'Selecciona una fecha',
                          style: _startDate != null
                              ? theme.textTheme.bodyLarge
                              : theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Active checkbox
                    CheckboxListTile(
                      value: _setAsActive,
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() => _setAsActive = value ?? true);
                            },
                      title: const Text('Establecer como curso activo'),
                      subtitle: const Text(
                        'Los nuevos estudiantes se añadirán a este curso',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 32),
                    // Save button
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveCourse,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(isEditing ? 'Guardar cambios' : 'Crear curso'),
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
