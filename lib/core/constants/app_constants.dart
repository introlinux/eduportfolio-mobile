/// Application-wide constants
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // App Info
  static const String appName = 'Eduportfolio';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'eduportfolio.db';
  static const int databaseVersion = 3;

  // Default Subjects
  static const List<String> defaultSubjects = [
    'Matemáticas',
    'Lengua',
    'Ciencias',
    'Inglés',
    'Artística',
  ];

  // File Naming
  static const String photoPrefix = 'IMG';
  static const String videoPrefix = 'VID';
  static const String audioPrefix = 'AUD';
  static const String thumbnailPrefix = 'THUMB';

  // Media Settings
  static const int photoResolution = 16000000; // 16MP
  static const int photoQuality = 85; // JPEG compression quality
  static const int videoResolution = 1080; // 1080p
  static const int audioBitrate = 192000; // 192kbps

  // Face Recognition
  static const int embeddingSize = 128;
  static const double recognitionThreshold = 0.6;
  static const int trainingPhotosRequired = 5;
  static const Duration maxInferenceTime = Duration(seconds: 2);

  // Storage Folders
  static const String temporalFolder = 'Temporal';
  static const String faceTrainingFolder = 'FaceTraining';

  // Limits
  static const int maxStudentsPerClass = 25;
}
