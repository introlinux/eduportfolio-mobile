import 'dart:developer' as developer;

/// Simple logger utility for the application
///
/// This logger provides different log levels and can be easily
/// replaced with a more sophisticated logging solution in the future.
class Logger {
  Logger._(); // Private constructor to prevent instantiation

  static const String _name = 'Eduportfolio';

  /// Log debug messages
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 500, // Debug level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log info messages
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 800, // Info level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log warning messages
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error messages
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }
}
