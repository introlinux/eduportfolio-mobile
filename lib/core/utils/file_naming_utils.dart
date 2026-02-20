/// Shared utilities for generating normalized file names in evidence use cases
class FileNamingUtils {
  FileNamingUtils._();

  /// Remove accents from text
  ///
  /// Examples:
  /// - "Matemáticas" → "Matematicas"
  /// - "Inglés" → "Ingles"
  /// - "Artística" → "Artistica"
  static String removeAccents(String text) {
    const withAccents = 'áéíóúÁÉÍÓÚñÑüÜ';
    const withoutAccents = 'aeiouAEIOUnNuU';

    String result = text;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }

    return result;
  }

  /// Extract first 3 letters of subject name in uppercase
  ///
  /// Examples:
  /// - "Matemáticas" → "MAT"
  /// - "Lengua" → "LEN"
  /// - "Inglés" → "ING"
  static String generateSubjectId(String subjectName) {
    final normalized = removeAccents(subjectName);
    final id = normalized.length >= 3
        ? normalized.substring(0, 3).toUpperCase()
        : normalized.toUpperCase().padRight(3, 'X');
    return id;
  }

  /// Normalize student name by replacing spaces with hyphens
  ///
  /// Examples:
  /// - "Juan Garcia" → "Juan-Garcia"
  /// - "María López Pérez" → "Maria-Lopez-Perez"
  static String normalizeStudentName(String name) {
    final normalized = removeAccents(name);
    return normalized.replaceAll(' ', '-');
  }
}
