import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card widget for displaying an evidence in review mode
///
/// Shows thumbnail, metadata, and optional checkbox for selection
class EvidenceReviewCard extends StatelessWidget {
  final Evidence evidence;
  final Subject? subject;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelectionChanged;

  const EvidenceReviewCard({
    required this.evidence,
    required this.subject,
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
                      subject?.name ?? 'Sin asignatura',
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            evidence.thumbnailPath != null
                ? Image.file(
                    File(evidence.thumbnailPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder(theme);
                    },
                  )
                : evidence.type == EvidenceType.image
                    ? Image.file(
                        File(evidence.filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder(theme);
                        },
                      )
                    : _buildPlaceholder(theme),

            // Video play overlay
            if (evidence.type == EvidenceType.video)
              Center(
                child: Icon(
                  Icons.play_circle_filled,
                  size: 32,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),

            // Duration badge
            if (evidence.type == EvidenceType.video && evidence.duration != null)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    _formatDuration(evidence.duration!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
      case EvidenceType.image:
        return Icons.image;
      case EvidenceType.video:
        return Icons.videocam;
      case EvidenceType.audio:
        return Icons.mic;
    }
  }

  String _getFileName() {
    return evidence.filePath.split('/').last;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
