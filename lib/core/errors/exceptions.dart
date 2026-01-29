/// Base exception for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.code]);

  @override
  String toString() => 'DatabaseException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// File system exceptions
class StorageException extends AppException {
  const StorageException(super.message, [super.code]);

  @override
  String toString() => 'StorageException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Face recognition exceptions
class FaceRecognitionException extends AppException {
  const FaceRecognitionException(super.message, [super.code]);

  @override
  String toString() => 'FaceRecognitionException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Media capture exceptions
class MediaCaptureException extends AppException {
  const MediaCaptureException(super.message, [super.code]);

  @override
  String toString() => 'MediaCaptureException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Encryption exceptions
class EncryptionException extends AppException {
  const EncryptionException(super.message, [super.code]);

  @override
  String toString() => 'EncryptionException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Permission exceptions
class PermissionException extends AppException {
  const PermissionException(super.message, [super.code]);

  @override
  String toString() => 'PermissionException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Invalid data exceptions
class InvalidDataException extends AppException {
  const InvalidDataException(super.message, [super.code]);

  @override
  String toString() => 'InvalidDataException: $message${code != null ? ' (Code: $code)' : ''}';
}
