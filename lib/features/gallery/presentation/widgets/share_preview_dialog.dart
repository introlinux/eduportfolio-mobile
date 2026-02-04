import 'dart:io';

import 'package:eduportfolio/features/gallery/domain/services/privacy_service.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class SharePreviewDialog extends StatefulWidget {
  final List<File> originalFiles;
  final PrivacyService privacyService;

  const SharePreviewDialog({
    required this.originalFiles,
    required this.privacyService,
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

  @override
  void initState() {
    super.initState();
    _activeFiles = List.from(widget.originalFiles);
  }

  @override
  void dispose() {
    // Optional: could trigger cleanup here, but better to do it after share or app exit
    super.dispose();
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

  // Process all active images with privacy filter
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
           // We only cache the PROCESSED version. 
           // If we need original, we have 'file'. 
           // But wait, if we toggle OFF, we just use 'file'.
           // If we toggle ON, we check cache or process.
           // However, if we remove a file, we just remove from active list.
           
           // Actually, we need to process specifically for privacy=true.
           // If privacy=false, we don't need to process (just return original).
           // But let's assume cache stores the "Privacy ON" version.
           
           final processed = await widget.privacyService.processImageForSharing(file, true);
           _processedCache[key] = processed;
        }
        
        if (mounted) {
          setState(() {
            _processedCount++;
          });
        }
      }
    } catch (e) {
      debugPrint("Error processing images: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  File _getCurrentFileDisplay(int index) {
    final original = _activeFiles[index];
    if (_isPrivacyMode) {
      // Return cached processed version if available, otherwise original (shouldn't happen if wait finish)
      // Or show original while processing?
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

    final filesToShare = <XFile>[];
    
    for (final file in _activeFiles) {
      final fileToSend = _isPrivacyMode ? (_processedCache[file.path] ?? file) : file;
      filesToShare.add(XFile(fileToSend.path));
    }

    // Close dialog first
    Navigator.of(context).pop();

    try {
      // Add a small delay for dialog close animation
      await Future.delayed(const Duration(milliseconds: 300));
      
      await Share.shareXFiles(
        filesToShare,
        text: 'Compartido desde EduPortfolio${_isPrivacyMode ? " (Modo Privacidad)" : ""}',
      );
    } catch (e) {
      debugPrint('Error sharing files: $e');
    }
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
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                         final fileToDisplay = _getCurrentFileDisplay(index);
                         return Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 4),
                           child: ClipRRect(
                             borderRadius: BorderRadius.circular(8),
                             child: Image.file(
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
                    title: const Text('Pixelar caras'),
                    secondary: Icon(
                      _isPrivacyMode ? Icons.visibility_off : Icons.visibility,
                      color: _isPrivacyMode ? theme.colorScheme.primary : null,
                    ),
                    value: _isPrivacyMode,
                    onChanged: _isProcessing ? null : _togglePrivacy,
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
}
