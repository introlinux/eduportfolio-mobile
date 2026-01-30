import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings using SharedPreferences
class AppSettingsService {
  static const String _keyImageResolution = 'image_resolution';
  static const int _defaultImageResolution = 1080;

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

  /// Reset all settings to defaults
  Future<void> resetAllSettings() async {
    await _prefs.clear();
  }
}

