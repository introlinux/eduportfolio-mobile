import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:flutter/material.dart';

/// Bottom action bar for batch operations on selected evidences
///
/// Shows when evidences are selected in review screen
class BatchActionBar extends StatefulWidget {
  final int selectedCount;
  final List<Student> students;
  final ValueChanged<int> onAssign;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const BatchActionBar({
    required this.selectedCount,
    required this.students,
    required this.onAssign,
    required this.onDelete,
    required this.onCancel,
    super.key,
  });

  @override
  State<BatchActionBar> createState() => _BatchActionBarState();
}

class _BatchActionBarState extends State<BatchActionBar> {
  int? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selected count
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.selectedCount} seleccionada${widget.selectedCount != 1 ? 's' : ''}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Actions row
              Row(
                children: [
                  // Student dropdown
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedStudentId,
                      decoration: const InputDecoration(
                        labelText: 'Asignar a estudiante',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: widget.students
                          .map((student) => DropdownMenuItem<int>(
                                value: student.id,
                                child: Text(student.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStudentId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Assign button
                  FilledButton.icon(
                    onPressed: _selectedStudentId == null
                        ? null
                        : () => widget.onAssign(_selectedStudentId!),
                    icon: const Icon(Icons.check),
                    label: const Text('Asignar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Delete button (full width)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    'Eliminar ${widget.selectedCount} evidencia${widget.selectedCount != 1 ? 's' : ''}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
