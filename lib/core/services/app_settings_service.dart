import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings using SharedPreferences
class AppSettingsService {
  static const String _keyImageResolution = 'image_resolution';
  static const int _defaultImageResolution = 1080;

  static const String _keyVideoResolution = 'video_resolution';
  static const int _defaultVideoResolution = 720;

  final SharedPreferences _prefs;

  AppSettingsService(this._prefs);

  /// Get the configured image resolution (height in pixels)
  /// Returns 1080, 1440, or 2160
  Future<int> getImageResolution() async {
    return _prefs.getInt(_keyImageResolution) ?? _defaultImageResolution;
  }

  /// Set the image resolution (height in pixels)
  /// Valid values: 1080, 1440, 2160
  Future<void> setImageResolution(int resolution) async {
    if (resolution != 1080 && resolution != 1440 && resolution != 2160) {
      throw ArgumentError(
        'Invalid resolution: $resolution. Must be 1080, 1440, or 2160',
      );
    }
    await _prefs.setInt(_keyImageResolution, resolution);
  }

  /// Get the ResolutionPreset based on configured resolution
  Future<ResolutionPreset> getResolutionPreset() async {
    final resolution = await getImageResolution();
    return _resolutionToPreset(resolution);
  }

  /// Convert resolution height to ResolutionPreset
  ResolutionPreset _resolutionToPreset(int resolution) {
    switch (resolution) {
      case 1080:
        return ResolutionPreset.veryHigh; // 1080p
      case 1440:
        return ResolutionPreset.ultraHigh; // 2160p/4K (closest to 1440p)
      case 2160:
        return ResolutionPreset.max; // Maximum resolution available
      default:
        return ResolutionPreset.veryHigh; // Default to 1080p
    }
  }

  // Video resolution methods

  /// Get the configured video resolution (height in pixels)
  /// Returns 480, 720, or 1080
  Future<int> getVideoResolution() async {
    return _prefs.getInt(_keyVideoResolution) ?? _defaultVideoResolution;
  }

  /// Set the video resolution (height in pixels)
  /// Valid values: 480, 720, 1080
  Future<void> setVideoResolution(int resolution) async {
    if (resolution != 480 && resolution != 720 && resolution != 1080) {
      throw ArgumentError(
        'Invalid resolution: $resolution. Must be 480, 720, or 1080',
      );
    }
    await _prefs.setInt(_keyVideoResolution, resolution);
  }

  /// Get the ResolutionPreset for video based on configured resolution
  Future<ResolutionPreset> getVideoResolutionPreset() async {
    final resolution = await getVideoResolution();
    return _videoResolutionToPreset(resolution);
  }

  /// Convert video resolution height to ResolutionPreset
  ResolutionPreset _videoResolutionToPreset(int resolution) {
    switch (resolution) {
      case 480:
        return ResolutionPreset.medium;
      case 720:
        return ResolutionPreset.high;
      case 1080:
        return ResolutionPreset.veryHigh;
      default:
        return ResolutionPreset.high; // Default to 720p
    }
  }

  // Sync configuration methods

  static const String _keySyncServerUrl = 'sync_server_url';
  static const String _keyLastSyncTimestamp = 'last_sync_timestamp';

  /// Get the configured sync server URL (e.g., "192.168.1.100:3000")
  Future<String?> getSyncServerUrl() async {
    return _prefs.getString(_keySyncServerUrl);
  }

  /// Set the sync server URL
  Future<void> setSyncServerUrl(String url) async {
    await _prefs.setString(_keySyncServerUrl, url);
  }

  /// Clear the sync server URL
  Future<void> clearSyncServerUrl() async {
    await _prefs.remove(_keySyncServerUrl);
  }

  /// Get the last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    final str = _prefs.getString(_keyLastSyncTimestamp);
    return str != null ? DateTime.tryParse(str) : null;
  }

  /// Set the last sync timestamp
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    await _prefs.setString(_keyLastSyncTimestamp, timestamp.toIso8601String());
  }

  /// Reset all settings to defaults
  Future<void> resetAllSettings() async {
    await _prefs.clear();
  }
}

