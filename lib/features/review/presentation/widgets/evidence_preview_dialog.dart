import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/entities/student.dart';
import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Full-screen dialog to preview evidence and assign to student
///
/// Allows navigation between evidences and quick assignment/deletion
class EvidencePreviewDialog extends StatefulWidget {
  final List<Evidence> allEvidences;
  final int initialIndex;
  final List<Student> students;
  final List<Subject> subjects;
  final Function(int evidenceId, int studentId) onAssign;
  final Function(int evidenceId) onDelete;

  const EvidencePreviewDialog({
    required this.allEvidences,
    required this.initialIndex,
    required this.students,
    required this.subjects,
    required this.onAssign,
    required this.onDelete,
    super.key,
  });

  @override
  State<EvidencePreviewDialog> createState() => _EvidencePreviewDialogState();
}

class _EvidencePreviewDialogState extends State<EvidencePreviewDialog> {
  late int _currentIndex;
  int? _selectedStudentId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  Evidence get _currentEvidence => widget.allEvidences[_currentIndex];

  Subject? get _currentSubject {
    try {
      return widget.subjects.firstWhere(
        (s) => s.id == _currentEvidence.subjectId,
      );
    } catch (e) {
      return null;
    }
  }

  bool get _hasPrevious => _currentIndex > 0;
  bool get _hasNext => _currentIndex < widget.allEvidences.length - 1;

  void _navigatePrevious() {
    if (_hasPrevious) {
      setState(() {
        _currentIndex--;
        _selectedStudentId = null;
      });
    }
  }

  void _navigateNext() {
    if (_hasNext) {
      setState(() {
        _currentIndex++;
        _selectedStudentId = null;
      });
    }
  }

  Future<void> _handleAssign() async {
    if (_selectedStudentId == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await widget.onAssign(_currentEvidence.id!, _selectedStudentId!);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidencia asignada'),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 800),
          ),
        );

        // Move to next or close if last
        if (_hasNext) {
          _navigateNext();
        } else {
          Navigator.of(context).pop(true); // Return true to indicate changes
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    if (_isProcessing) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta evidencia?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentEvidence.filePath.split('/').last,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_currentSubject?.name ?? 'Sin asignatura'} - ${DateFormat('dd/MM/yyyy HH:mm').format(_currentEvidence.captureDate)}',
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(color: Colors.red),
            ),
          ],
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

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      await widget.onDelete(_currentEvidence.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidencia eliminada'),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 800),
          ),
        );

        // Close dialog and return true to refresh list
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.allEvidences.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Image/Video preview
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    child: _buildPreview(),
                  ),
                ),
              ),

              // Bottom controls
              Container(
                color: theme.colorScheme.surface,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Metadata
                        _buildMetadata(theme),
                        const SizedBox(height: 16),

                        // Student dropdown
                        DropdownButtonFormField<int>(
                          value: _selectedStudentId,
                          decoration: const InputDecoration(
                            labelText: 'Asignar a estudiante',
                            border: OutlineInputBorder(),
                          ),
                          items: widget.students
                              .map((student) => DropdownMenuItem<int>(
                                    value: student.id,
                                    child: Text(student.name),
                                  ))
                              .toList(),
                          onChanged: _isProcessing
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedStudentId = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),

                        // Action buttons
                        Row(
                          children: [
                            // Delete button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isProcessing ? null : _handleDelete,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Eliminar'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Assign button
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _selectedStudentId == null ||
                                        _isProcessing
                                    ? null
                                    : _handleAssign,
                                icon: _isProcessing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check),
                                label: const Text('Asignar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Navigation buttons overlay
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_currentEvidence.type == EvidenceType.image) {
      return Image.file(
        File(_currentEvidence.filePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.white,
            ),
          );
        },
      );
    } else if (_currentEvidence.type == EvidenceType.video) {
      // TODO: Add video player
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Vista previa de video\npróximamente',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      // EvidenceType.audio
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Audio',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMetadata(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentSubject?.name ?? 'Sin asignatura',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(_currentEvidence.captureDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Positioned.fill(
      child: Row(
        children: [
          // Previous button
          if (_hasPrevious)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _isProcessing ? null : _navigatePrevious,
                  icon: const Icon(Icons.chevron_left, size: 48),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            )
          else
            const Spacer(),

          const Spacer(flex: 5),

          // Next button
          if (_hasNext)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _isProcessing ? null : _navigateNext,
                  icon: const Icon(Icons.chevron_right, size: 48),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}
