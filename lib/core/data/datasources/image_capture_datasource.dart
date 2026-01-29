import 'package:image_picker/image_picker.dart';

/// DataSource for image capture operations
abstract class ImageCaptureDataSource {
  /// Capture image from camera
  /// Returns the file path or null if cancelled
  Future<String?> captureFromCamera();

  /// Pick image from gallery
  /// Returns the file path or null if cancelled
  Future<String?> pickFromGallery();
}

/// Implementation of ImageCaptureDataSource using image_picker
class ImageCaptureDataSourceImpl implements ImageCaptureDataSource {
  final ImagePicker _picker;

  ImageCaptureDataSourceImpl({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  @override
  Future<String?> captureFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compress to 85% quality
        maxWidth: 1920, // Max width for performance
        maxHeight: 1920, // Max height for performance
      );

      return image?.path;
    } catch (e) {
      // If user denies permissions or any other error occurs
      return null;
    }
  }

  @override
  Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress to 85% quality
        maxWidth: 1920, // Max width for performance
        maxHeight: 1920, // Max height for performance
      );

      return image?.path;
    } catch (e) {
      // If user denies permissions or any other error occurs
      return null;
    }
  }
}
