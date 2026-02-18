import 'dart:io';

import 'package:archive/archive.dart';
import 'package:eduportfolio/features/gallery/domain/services/privacy_service.dart';
import 'package:eduportfolio/features/gallery/domain/services/media3_video_privacy_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class SharePreviewDialog extends StatefulWidget {
  final List<File> originalFiles;
  final Map<String, String>? thumbnailPaths; // Optional: filePath -> thumbnailPath
  final PrivacyService privacyService;
  final Media3VideoPrivacyService videoPrivacyService;

  const SharePreviewDialog({
    required this.originalFiles,
    this.thumbnailPaths,
    required this.privacyService,
    required this.videoPrivacyService,
    super.key,
  });

  @override
  State<SharePreviewDialog> createState() => _SharePreviewDialogState();
}

class _SharePreviewDialogState extends State<SharePreviewDialog> {
  // Current active files (user may remove some)
  late List<File> _activeFiles;

  // State variables
  bool _isPrivacyMode = false;
  bool _isProcessing = false;
  Map<String, File> _processedCache = {}; // Cache processed files by path
  int _currentIndex = 0;

  // Progress tracking
  int _processedCount = 0;
  int _totalToProcess = 0;

  // ZIP mode
  bool _isZipMode = false;
  String? _overrideLoadingMessage;

  // Video player for current video (if any)
  VideoPlayerController? _videoController;

  // Audio player for current audio (if any)
  ja.AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _activeFiles = List.from(widget.originalFiles);
    _initializeFirstController();
  }

  /// Initialize controller for the first file if it's video or audio
  Future<void> _initializeFirstController() async {
    if (_activeFiles.isEmpty) return;
    
    final firstFile = _activeFiles[0];
    if (_isVideoFile(firstFile)) {
      _videoController = VideoPlayerController.file(firstFile);
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      if (mounted) setState(() {});
    } else if (_isAudioFile(firstFile)) {
      _audioPlayer = ja.AudioPlayer();
      await _audioPlayer!.setFilePath(firstFile.path);
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  /// Check if file is a video based on extension
  bool _isVideoFile(File file) {
    final ext = file.path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv');
  }

  /// Check if file is an audio file based on extension
  bool _isAudioFile(File file) {
    final ext = file.path.toLowerCase();
    return ext.endsWith('.mp3') ||
        ext.endsWith('.wav') ||
        ext.endsWith('.m4a') ||
        ext.endsWith('.aac') ||
        ext.endsWith('.ogg') ||
        ext.endsWith('.opus');
  }

  // Toggle privacy mode and trigger processing
  void _togglePrivacy(bool value) {
    setState(() {
      _isPrivacyMode = value;
    });
    
    if (_isPrivacyMode) {
      _processImages();
    }
  }

  // Process all active files (images and videos) with privacy filter
  Future<void> _processImages() async {
    setState(() {
      _isProcessing = true;
      _processedCount = 0;
      _totalToProcess = _activeFiles.length;
    });

    try {
      for (int i = 0; i < _activeFiles.length; i++) {
        final file = _activeFiles[i];
        final key = file.path;

        // If not already cached for this mode
        if (!_processedCache.containsKey(key)) {
          final File processed;

          // Use appropriate service based on file type
          if (_isVideoFile(file)) {
            processed = await widget.videoPrivacyService.processVideoForSharing(file, true);
          } else if (_isAudioFile(file)) {
            // Audio files are skipped for privacy processing
            processed = file;
          } else {
            processed = await widget.privacyService.processImageForSharing(file, true);
          }

          _processedCache[key] = processed;
        }

        if (mounted) {
          setState(() {
            _processedCount++;
          });
        }
      }
    } catch (e) {
      debugPrint("Error processing files: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        // Re-initialize controller to show processed file
        await _refreshMediaController();
      }
    }
  }

  /// Refresh media controller to display the current file (original or processed)
  Future<void> _refreshMediaController() async {
    final fileToDisplay = _getCurrentFileDisplay(_currentIndex);
    
    // Dispose both controllers first
    await _videoController?.dispose();
    _videoController = null;
    await _audioPlayer?.dispose();
    _audioPlayer = null;

    if (_isVideoFile(fileToDisplay)) {
      _videoController = VideoPlayerController.file(fileToDisplay);
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
    } else if (_isAudioFile(fileToDisplay)) {
      _audioPlayer = ja.AudioPlayer();
      await _audioPlayer!.setFilePath(fileToDisplay.path);
    }
    
    if (mounted) setState(() {});
  }

  File _getCurrentFileDisplay(int index) {
    final original = _activeFiles[index];
    if (_isPrivacyMode) {
      return _processedCache[original.path] ?? original;
    } else {
      return original;
    }
  }

  void _discardCurrentFile() {
    setState(() {
      _activeFiles.removeAt(_currentIndex);
      if (_currentIndex >= _activeFiles.length) {
        _currentIndex = _activeFiles.isNotEmpty ? _activeFiles.length - 1 : 0;
      }
    });

    if (_activeFiles.isEmpty) {
      Navigator.of(context).pop(); // Close if no files left
    }
  }

  Future<void> _shareFiles() async {
    if (_activeFiles.isEmpty) return;

    // Collect the files to send (processed or original)
    final filesToSend = <File>[];
    for (final file in _activeFiles) {
      filesToSend.add(_isPrivacyMode ? (_processedCache[file.path] ?? file) : file);
    }

    if (_isZipMode) {
      // Ask for optional password
      final password = await _showPasswordDialog();
      if (password == null) return; // User cancelled

      setState(() {
        _isProcessing = true;
        _overrideLoadingMessage =
            password.isEmpty ? 'Creando ZIP...' : 'Creando ZIP con contraseña...';
      });

      try {
        final zipFile = await _createZipFile(filesToSend, password);
        if (!mounted) return;
        Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 300));
        await Share.shareXFiles(
          [XFile(zipFile.path)],
          text: 'Compartido desde EduPortfolio${_isPrivacyMode ? " (Modo Privacidad)" : ""}',
        );
      } catch (e) {
        debugPrint('Error creating ZIP: $e');
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _overrideLoadingMessage = null;
          });
        }
      }
    } else {
      // Share files individually (original behavior)
      Navigator.of(context).pop();
      try {
        await Future.delayed(const Duration(milliseconds: 300));
        await Share.shareXFiles(
          filesToSend.map((f) => XFile(f.path)).toList(),
          text: 'Compartido desde EduPortfolio${_isPrivacyMode ? " (Modo Privacidad)" : ""}',
        );
      } catch (e) {
        debugPrint('Error sharing files: $e');
      }
    }
  }

  /// Shows a dialog to ask for an optional ZIP password.
  /// Returns the password string (possibly empty) or null if cancelled.
  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    bool obscureText = true;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Contraseña del ZIP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Escribe una contraseña para proteger el ZIP.\n'
                'Déjalo vacío para compartir sin contraseña.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: obscureText,
                decoration: InputDecoration(
                  labelText: 'Contraseña (opcional)',
                  hintText: 'Sin contraseña',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscureText = !obscureText),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );

    // Defer disposal until after the dialog exit animation completes.
    // showDialog resolves as soon as pop() is called, but the widget tree
    // still references the controller during the closing animation.
    Future.delayed(const Duration(milliseconds: 300), controller.dispose);
    return result;
  }

  /// Creates a ZIP file from [files], optionally encrypted with [password].
  Future<File> _createZipFile(List<File> files, String password) async {
    final archive = Archive();
    final usedNames = <String>{};

    for (final file in files) {
      final bytes = await file.readAsBytes();
      String fileName = file.path.split('/').last;

      // Resolve duplicate file names
      if (usedNames.contains(fileName)) {
        final dotIndex = fileName.lastIndexOf('.');
        final base = dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
        final ext = dotIndex != -1 ? fileName.substring(dotIndex) : '';
        int counter = 1;
        while (usedNames.contains('${base}_$counter$ext')) {
          counter++;
        }
        fileName = '${base}_$counter$ext';
      }
      usedNames.add(fileName);

      archive.addFile(ArchiveFile.bytes(fileName, bytes));
    }

    final encoder = ZipEncoder(password: password.isEmpty ? null : password);
    final zipBytes = encoder.encode(archive);

    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now();
    final datestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final zipFile = File('${tempDir.path}/evidencias_$datestamp.zip');
    await zipFile.writeAsBytes(zipBytes);

    return zipFile;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.share, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Vista Previa',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  // Image Counter
                  if (_activeFiles.isNotEmpty)
                    Text(
                      '${_currentIndex + 1}/${_activeFiles.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            
            // Image Preview Area
            if (_activeFiles.isNotEmpty)
              Flexible(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Carousel
                    PageView.builder(
                      itemCount: _activeFiles.length,
                      onPageChanged: (index) async {
                        // Dispose previous controllers
                        await _videoController?.dispose();
                        _videoController = null;
                        await _audioPlayer?.dispose();
                        _audioPlayer = null;

                        setState(() {
                          _currentIndex = index;
                        });

                        // Initialize appropriate controller
                        final fileToDisplay = _getCurrentFileDisplay(index);
                        if (_isVideoFile(fileToDisplay)) {
                          _videoController = VideoPlayerController.file(fileToDisplay);
                          await _videoController!.initialize();
                          await _videoController!.setLooping(true);
                        } else if (_isAudioFile(fileToDisplay)) {
                          _audioPlayer = ja.AudioPlayer();
                          await _audioPlayer!.setFilePath(fileToDisplay.path);
                        }
                        
                        if (mounted) setState(() {});
                      },
                      itemBuilder: (context, index) {
                        final fileToDisplay = _getCurrentFileDisplay(index);
                        final originalPath = _activeFiles[index].path;
                        final thumbnailPath = widget.thumbnailPaths?[originalPath];
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _isVideoFile(fileToDisplay)
                                ? _buildVideoPreview()
                                : _isAudioFile(fileToDisplay)
                                    ? _buildAudioPreview(thumbnailPath)
                                    : Image.file(
                                        fileToDisplay,
                                        fit: BoxFit.contain,
                                        gaplessPlayback: true,
                                      ),
                          ),
                        );
                      },
                    ),
                    
                    // Loading Overlay
                    if (_isProcessing)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: Colors.white),
                              const SizedBox(height: 16),
                              Text(
                                _overrideLoadingMessage ??
                                    'Procesando $_processedCount/$_totalToProcess...',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Discard Button (Top Right of Image)
                    if (!_isProcessing)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Descartar esta imagen',
                            onPressed: _discardCurrentFile,
                          ),
                        ),
                      ),
                      
                    // Nav Arrows (Optional, mostly for desktop but helpful hint)
                    if (!_isProcessing && _activeFiles.length > 1) ...[
                      if (_currentIndex > 0)
                        Positioned(
                           left: 8,
                           child: CircleAvatar(
                             backgroundColor: Colors.white.withOpacity(0.5),
                             radius: 16,
                             child: Icon(Icons.chevron_left, color: Colors.black),
                           ),
                        ),
                      if (_currentIndex < _activeFiles.length - 1)
                        Positioned(
                           right: 8,
                           child: CircleAvatar(
                             backgroundColor: Colors.white.withOpacity(0.5),
                             radius: 16,
                             child: Icon(Icons.chevron_right, color: Colors.black),
                           ),
                        ),
                    ]
                  ],
                ),
              ),

            // Controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Privacy Toggle
                  SwitchListTile(
                    title: const Text('Ocultar caras'),
                    secondary: Icon(
                      _isPrivacyMode ? Icons.visibility_off : Icons.visibility,
                      color: _isPrivacyMode ? theme.colorScheme.primary : null,
                    ),
                    value: _isPrivacyMode,
                    onChanged: (_isProcessing || _isAudioFile(_activeFiles[_currentIndex]))
                        ? null
                        : _togglePrivacy,
                  ),

                  // ZIP Toggle
                  SwitchListTile(
                    title: const Text('Comprimir en ZIP'),
                    secondary: Icon(
                      Icons.folder_zip,
                      color: _isZipMode ? theme.colorScheme.primary : null,
                    ),
                    value: _isZipMode,
                    onChanged: _isProcessing
                        ? null
                        : (value) => setState(() => _isZipMode = value),
                  ),

                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _isProcessing ? null : _shareFiles,
                        icon: const Icon(Icons.share),
                        label: Text('Compartir (${_activeFiles.length})'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          if (!_videoController!.value.isPlaying)
            Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.play_arrow,
                size: 48,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview(String? thumbnailPath) {
    return Stack(
      children: [
        // Cover image as background
        if (thumbnailPath != null)
          Positioned.fill(
            child: Image.file(
              File(thumbnailPath),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.mic, size: 64, color: Colors.grey),
              ),
            ),
          )
        else
          const Center(
            child: Icon(Icons.mic, size: 64, color: Colors.grey),
          ),

        // Audio controls overlay at bottom
        if (_audioPlayer != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play/pause button
                  StreamBuilder<ja.PlayerState>(
                    stream: _audioPlayer!.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final playing = playerState?.playing ?? false;
                      final processingState = playerState?.processingState;

                      if (processingState == ja.ProcessingState.completed) {
                        return IconButton(
                          iconSize: 48,
                          icon: const Icon(Icons.replay, color: Colors.white),
                          onPressed: () {
                            _audioPlayer!.seek(Duration.zero);
                            _audioPlayer!.play();
                          },
                        );
                      }

                      return IconButton(
                        iconSize: 48,
                        icon: Icon(
                          playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (playing) {
                            _audioPlayer!.pause();
                          } else {
                            _audioPlayer!.play();
                          }
                        },
                      );
                    },
                  ),
                  // Seek bar
                  StreamBuilder<Duration>(
                    stream: _audioPlayer!.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = _audioPlayer!.duration ?? Duration.zero;

                      return Row(
                        children: [
                          Text(
                            _formatDurationMs(position),
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                          Expanded(
                            child: Slider(
                              value: duration.inMilliseconds > 0
                                  ? position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble())
                                  : 0,
                              max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1,
                              activeColor: Colors.blue,
                              inactiveColor: Colors.white24,
                              onChanged: (value) {
                                _audioPlayer!.seek(Duration(milliseconds: value.toInt()));
                              },
                            ),
                          ),
                          Text(
                            _formatDurationMs(duration),
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          )
        else
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  String _formatDurationMs(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
