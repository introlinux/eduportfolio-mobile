import 'package:eduportfolio/core/domain/repositories/evidence_repository.dart';

/// Storage information model
class StorageInfo {
  final int totalSizeBytes;
  final int evidenceCount;

  const StorageInfo({
    required this.totalSizeBytes,
    required this.evidenceCount,
  });

  /// Get size in megabytes
  double get sizeMB => totalSizeBytes / (1024 * 1024);

  /// Get size in gigabytes
  double get sizeGB => totalSizeBytes / (1024 * 1024 * 1024);

  /// Format size as human-readable string
  String get formattedSize {
    if (sizeGB >= 1) {
      return '${sizeGB.toStringAsFixed(2)} GB';
    } else if (sizeMB >= 1) {
      return '${sizeMB.toStringAsFixed(1)} MB';
    } else {
      return '${(totalSizeBytes / 1024).toStringAsFixed(0)} KB';
    }
  }
}

/// UseCase to get storage information
///
/// Returns total storage used by evidences and the count of evidences
class GetStorageInfoUseCase {
  final EvidenceRepository _repository;

  GetStorageInfoUseCase(this._repository);

  Future<StorageInfo> call() async {
    final totalSize = await _repository.getTotalStorageSize();
    final count = await _repository.countEvidences();

    return StorageInfo(
      totalSizeBytes: totalSize,
      evidenceCount: count,
    );
  }
}
