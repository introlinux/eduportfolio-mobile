import 'dart:io';

import 'package:eduportfolio/core/domain/entities/evidence.dart';
import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card widget to display an evidence in the gallery
class EvidenceCard extends StatelessWidget {
  final Evidence evidence;
  final Subject? subject;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const EvidenceCard({
    required this.evidence,
    this.subject,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Image thumbnail
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Image.file(
                    File(evidence.filePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                  // Needs review indicator
                  if (!evidence.isReviewed)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pending,
                              size: 14,
                              color: theme.colorScheme.onError,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Revisar',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onError,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject name
                  if (subject != null)
                    Text(
                      subject!.name,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  // Capture date
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dateFormat.format(evidence.captureDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // File size
                  if (evidence.fileSizeMB != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.storage,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${evidence.fileSizeMB!.toStringAsFixed(1)} MB',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
            // Selection overlay
            if (isSelectionMode)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : Colors.transparent,
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 3,
                          )
                        : null,
                  ),
                ),
              ),
            // Selection checkbox
            if (isSelectionMode)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
