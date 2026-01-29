import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card widget for displaying an evidence in review mode
///
/// Shows thumbnail, metadata, and optional checkbox for selection
class EvidenceReviewCard extends StatelessWidget {
  final Evidence evidence;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelectionChanged;

  const EvidenceReviewCard({
    required this.evidence,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onSelectionChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: InkWell(
        onTap: selectionMode
            ? () => onSelectionChanged(!isSelected)
            : onTap,
        onLongPress: selectionMode
            ? null
            : () => onSelectionChanged(true),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox (only visible in selection mode)
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) => onSelectionChanged(value ?? false),
                  ),
                ),

              // Thumbnail
              _buildThumbnail(theme),

              const SizedBox(width: 12),

              // Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject name
                    Text(
                      evidence.subject?.name ?? 'Sin asignatura',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Date
                    Text(
                      dateFormat.format(evidence.captureDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Filename (truncated)
                    Text(
                      _getFileName(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Type indicator icon
              Icon(
                _getTypeIcon(),
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: evidence.thumbnailPath != null
            ? Image.file(
                File(evidence.thumbnailPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(theme);
                },
              )
            : evidence.type == 'IMG'
                ? Image.file(
                    File(evidence.filePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder(theme);
                    },
                  )
                : _buildPlaceholder(theme),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        _getTypeIcon(),
        size: 40,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (evidence.type) {
      case 'IMG':
        return Icons.image;
      case 'VID':
        return Icons.videocam;
      case 'AUD':
        return Icons.mic;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileName() {
    return evidence.filePath.split('/').last;
  }
}
