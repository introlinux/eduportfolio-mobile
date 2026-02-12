import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eduportfolio/core/utils/logger.dart';
import 'package:eduportfolio/features/sync/domain/entities/sync_models.dart';
import 'package:http/http.dart' as http;

/// Service for synchronization with desktop application
///
/// Handles HTTP communication with the desktop server for syncing
/// students, courses, subjects, and evidences.
class SyncService {
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _fileTimeout = Duration(minutes: 5);

  final http.Client _client;
  String? _password; // Contraseña del servidor para autenticación

  SyncService({http.Client? client}) : _client = client ?? http.Client();

  /// Set the server password for authentication
  ///
  /// This password will be included in all sync requests as Bearer token
  void setPassword(String password) {
    _password = password;
  }

  /// Get authentication headers for sync requests
  Map<String, String> _getAuthHeaders() {
    if (_password == null || _password!.isEmpty) {
      throw SyncException(
        'Password not set. Please configure server password first.',
      );
    }
    return {
      'Authorization': 'Bearer $_password',
    };
  }

  /// Get system information from desktop server
  ///
  /// Returns server IP, port, and status.
  /// Throws [SyncException] if connection fails.
  Future<SystemInfo> getSystemInfo(String baseUrl) async {
    try {
      Logger.info('Getting system info from: $baseUrl');

      final uri = Uri.parse('$baseUrl/api/system/info');
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final systemInfo = SystemInfo.fromJson(json);
        Logger.info('System info retrieved: ${systemInfo.ip}:${systemInfo.port}');
        return systemInfo;
      } else {
        throw SyncException(
          'Failed to get system info: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw SyncException('Connection timeout. Check server is running.');
    } on SocketException {
      throw SyncException(
        'Cannot connect to server. Check IP address and network.',
      );
    } catch (e) {
      Logger.error('Error getting system info', e);
      throw SyncException('Error connecting to server: $e');
    }
  }

  /// Get metadata from desktop server
  ///
  /// Returns all students, courses, subjects, and evidences from desktop.
  /// Throws [SyncException] if request fails.
  Future<SyncMetadata> getMetadata(String baseUrl) async {
    try {
      Logger.info('🟦 [SYNC-OUT] Solicitando metadatos a: $baseUrl');

      final uri = Uri.parse('$baseUrl/api/sync/metadata');
      final response = await _client
          .get(uri, headers: _getAuthHeaders())
          .timeout(_timeout);

      if (response.statusCode == 200) {
        Logger.info('   ✅ Respuesta recibida (${response.bodyBytes.length} bytes)');
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final metadata = SyncMetadata.fromJson(json);
        Logger.info(
          '   📊 Resumen recibido:\n'
          '      - Estudiantes: ${metadata.students.length}\n'
          '      - Cursos: ${metadata.courses.length}\n'
          '      - Asignaturas: ${metadata.subjects.length}\n'
          '      - Evidencias: ${metadata.evidences.length}',
        );
        return metadata;
      } else {
        throw SyncException(
          'Failed to get metadata: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw SyncException('Connection timeout while fetching metadata.');
    } on SocketException {
      throw SyncException('Network error while fetching metadata.');
    } catch (e) {
      Logger.error('Error getting metadata', e);
      throw SyncException('Error fetching metadata: $e');
    }
  }

  /// Push metadata to desktop server
  ///
  /// Sends local students, courses, subjects, and evidences to desktop.
  /// Throws [SyncException] if request fails.
  Future<void> pushMetadata(String baseUrl, SyncMetadata metadata) async {
    try {
      Logger.info('🟩 [SYNC-IN] Enviando metadatos locales a: $baseUrl');
      Logger.info(
          '   📊 Resumen a enviar:\n'
          '      - Estudiantes: ${metadata.students.length}\n'
          '      - Cursos: ${metadata.courses.length}\n'
          '      - Asignaturas: ${metadata.subjects.length}\n'
          '      - Evidencias: ${metadata.evidences.length}',
        );

      final uri = Uri.parse('$baseUrl/api/sync/push');
      final headers = {
        'Content-Type': 'application/json',
        ..._getAuthHeaders(),
      };
      
      final body = jsonEncode(metadata.toJson());
      Logger.info('   📤 Enviando payload (${body.length} bytes)...');

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.info('   ✅ Metadatos enviados correctamente');
        // Loggear respuesta del servidor si hay detalles
        try {
           final json = jsonDecode(response.body);
           if (json['results'] != null) {
             Logger.info('   📥 Respuesta del servidor: ${jsonEncode(json['results'])}');
           }
        } catch (_) {}

      } else {
        throw SyncException(
          'Failed to push metadata: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw SyncException('Connection timeout while pushing metadata.');
    } on SocketException {
      throw SyncException('Network error while pushing metadata.');
    } catch (e) {
      Logger.error('Error pushing metadata', e);
      throw SyncException('Error pushing metadata: $e');
    }
  }

  /// Upload file to desktop server
  ///
  /// Uploads an evidence file (image, video, or audio) to the desktop.
  /// [onProgress] callback receives progress as a value between 0.0 and 1.0.
  /// Throws [SyncException] if upload fails.
  Future<void> uploadFile(
    String baseUrl,
    File file,
    String filename, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      Logger.info('📤 [FILE-UPLOAD] Subiendo archivo: $filename');

      final uri = Uri.parse('$baseUrl/api/sync/files');
      final request = http.MultipartRequest('POST', uri);

      // Add authentication headers
      request.headers.addAll(_getAuthHeaders());

      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      request.files.add(
        http.MultipartFile(
          'file',
          fileStream,
          fileLength,
          filename: filename,
        ),
      );

      final streamedResponse =
          await _client.send(request).timeout(_fileTimeout);

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        Logger.info('   ✅ Archivo subido correctamente: $filename');
      } else {
        throw SyncException(
          'Failed to upload file: ${streamedResponse.statusCode}',
        );
      }
    } on TimeoutException {
      throw SyncException('Upload timeout for file: $filename');
    } on SocketException {
      throw SyncException('Network error while uploading file: $filename');
    } catch (e) {
      Logger.error('Error uploading file', e);
      throw SyncException('Error uploading file: $e');
    }
  }

  /// Download file from desktop server
  ///
  /// Downloads an evidence file and saves it to [savePath].
  /// [onProgress] callback receives progress as a value between 0.0 and 1.0.
  /// Throws [SyncException] if download fails.
  Future<File> downloadFile(
    String baseUrl,
    String filename,
    String savePath, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      Logger.info('📥 [FILE-DOWNLOAD] Descargando archivo: $filename');

      final uri = Uri.parse('$baseUrl/api/sync/files/$filename');
      final response = await _client
          .get(uri, headers: _getAuthHeaders())
          .timeout(_fileTimeout);

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        Logger.info('   ✅ Archivo descargado: $filename (${response.bodyBytes.length} bytes)');
        return file;
      } else if (response.statusCode == 404) {
        throw SyncException('File not found on server: $filename');
      } else {
        throw SyncException(
          'Failed to download file: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw SyncException('Download timeout for file: $filename');
    } on SocketException {
      throw SyncException('Network error while downloading file: $filename');
    } catch (e) {
      Logger.error('Error downloading file', e);
      throw SyncException('Error downloading file: $e');
    }
  }

  /// Test connection to desktop server
  ///
  /// Returns true if connection is successful, false otherwise.
  Future<bool> testConnection(String baseUrl) async {
    try {
      await getSystemInfo(baseUrl);
      return true;
    } catch (e) {
      Logger.warning('Connection test failed', e);
      return false;
    }
  }

  /// Validate password by attempting to fetch metadata
  ///
  /// Returns true if password is correct, false otherwise.
  /// This method temporarily sets the password and tries to authenticate.
  Future<bool> validatePassword(String baseUrl, String password) async {
    try {
      Logger.info('Validating password for: $baseUrl');

      // Temporarily set password
      final oldPassword = _password;
      _password = password;

      try {
        // Try to fetch metadata with this password
        await getMetadata(baseUrl);
        return true;
      } catch (e) {
        Logger.warning('Password validation failed', e);
        return false;
      } finally {
        // Restore old password
        _password = oldPassword;
      }
    } catch (e) {
      Logger.error('Error validating password', e);
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// Exception thrown when synchronization fails
class SyncException implements Exception {
  final String message;

  SyncException(this.message);

  @override
  String toString() => 'SyncException: $message';
}
