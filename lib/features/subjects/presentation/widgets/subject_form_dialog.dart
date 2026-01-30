import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:flutter/material.dart';

/// Dialog for creating or editing a subject
class SubjectFormDialog extends StatefulWidget {
  final Subject? subject; // null for create, non-null for edit

  const SubjectFormDialog({
    this.subject,
    super.key,
  });

  @override
  State<SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<SubjectFormDialog> {
  late TextEditingController _nameController;
  late String _selectedColor;
  late String _selectedIcon;
  late bool _isDefault;

  // Predefined color options
  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Azul', 'value': '0xFF2196F3'},
    {'name': 'Verde', 'value': '0xFF4CAF50'},
    {'name': 'Rojo', 'value': '0xFFF44336'},
    {'name': 'Naranja', 'value': '0xFFFF9800'},
    {'name': 'Púrpura', 'value': '0xFF9C27B0'},
    {'name': 'Rosa', 'value': '0xFFE91E63'},
    {'name': 'Amarillo', 'value': '0xFFFFEB3B'},
    {'name': 'Cian', 'value': '0xFF00BCD4'},
    {'name': 'Lima', 'value': '0xFFCDDC39'},
    {'name': 'Índigo', 'value': '0xFF3F51B5'},
  ];

  // Predefined icon options
  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'Libro', 'icon': Icons.book},
    {'name': 'Calculadora', 'icon': Icons.calculate},
    {'name': 'Ciencia', 'icon': Icons.science},
    {'name': 'Idioma', 'icon': Icons.language},
    {'name': 'Arte', 'icon': Icons.palette},
    {'name': 'Música', 'icon': Icons.music_note},
    {'name': 'Deporte', 'icon': Icons.sports_soccer},
    {'name': 'Historia', 'icon': Icons.history_edu},
    {'name': 'Geografía', 'icon': Icons.map},
    {'name': 'Tecnología', 'icon': Icons.computer},
    {'name': 'Escritura', 'icon': Icons.edit},
    {'name': 'Lectura', 'icon': Icons.menu_book},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _selectedColor = widget.subject?.color ?? '0xFF2196F3';
    _selectedIcon = widget.subject?.icon ?? 'book';
    _isDefault = widget.subject?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _getColorFromString(String colorString) {
    return Color(int.parse(colorString));
  }

  IconData _getIconFromString(String iconString) {
    // Map string names to IconData
    final iconMap = {
      'book': Icons.book,
      'calculate': Icons.calculate,
      'science': Icons.science,
      'language': Icons.language,
      'palette': Icons.palette,
      'music_note': Icons.music_note,
      'sports_soccer': Icons.sports_soccer,
      'history_edu': Icons.history_edu,
      'map': Icons.map,
      'computer': Icons.computer,
      'edit': Icons.edit,
      'menu_book': Icons.menu_book,
    };
    return iconMap[iconString] ?? Icons.book;
  }

  String _getIconStringFromIconData(IconData icon) {
    // Map IconData to string names
    final reverseMap = {
      Icons.book.codePoint: 'book',
      Icons.calculate.codePoint: 'calculate',
      Icons.science.codePoint: 'science',
      Icons.language.codePoint: 'language',
      Icons.palette.codePoint: 'palette',
      Icons.music_note.codePoint: 'music_note',
      Icons.sports_soccer.codePoint: 'sports_soccer',
      Icons.history_edu.codePoint: 'history_edu',
      Icons.map.codePoint: 'map',
      Icons.computer.codePoint: 'computer',
      Icons.edit.codePoint: 'edit',
      Icons.menu_book.codePoint: 'menu_book',
    };
    return reverseMap[icon.codePoint] ?? 'book';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.subject != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar Asignatura' : 'Nueva Asignatura'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Matemáticas',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            // Color selector
            Text(
              'Color',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((colorOption) {
                final color = _getColorFromString(colorOption['value']);
                final isSelected = _selectedColor == colorOption['value'];

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorOption['value'];
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Icon selector
            Text(
              'Icono',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconOptions.map((iconOption) {
                final icon = iconOption['icon'] as IconData;
                final iconString = _getIconStringFromIconData(icon);
                final isSelected = _selectedIcon == iconString;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIcon = iconString;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Default checkbox
            CheckboxListTile(
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value ?? false;
                });
              },
              title: const Text('Asignatura predeterminada'),
              subtitle: const Text(
                'Aparecerá en el inicio por defecto',
                style: TextStyle(fontSize: 12),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El nombre no puede estar vacío'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final subject = Subject(
              id: widget.subject?.id,
              name: name,
              color: _selectedColor,
              icon: _selectedIcon,
              isDefault: _isDefault,
            );

            Navigator.of(context).pop(subject);
          },
          child: Text(isEdit ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
