import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:flutter/material.dart';

/// Card widget to display a subject in the home screen
class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;

  const SubjectCard({
    required this.subject,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Default colors for subjects
    final color = _getSubjectColor(subject.name);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background icon
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  _getSubjectIcon(subject.name),
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getSubjectIcon(subject.name),
                      size: 32,
                      color: Colors.white,
                    ),
                    const Spacer(),
                    Text(
                      subject.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toca para capturar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String name) {
    switch (name.toLowerCase()) {
      case 'matemáticas':
        return const Color(0xFF1E88E5); // Blue
      case 'lengua':
        return const Color(0xFFE53935); // Red
      case 'ciencias':
        return const Color(0xFF43A047); // Green
      case 'inglés':
        return const Color(0xFFFB8C00); // Orange
      case 'artística':
        return const Color(0xFF8E24AA); // Purple
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  IconData _getSubjectIcon(String name) {
    switch (name.toLowerCase()) {
      case 'matemáticas':
        return Icons.calculate;
      case 'lengua':
        return Icons.menu_book;
      case 'ciencias':
        return Icons.science;
      case 'inglés':
        return Icons.language;
      case 'artística':
        return Icons.palette;
      default:
        return Icons.school;
    }
  }
}
