import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../domain/entities/file_item.dart';
import '../../../domain/entities/file_item_type.dart';

class FilePreviewPage extends StatefulWidget {
  final FileItem file;

  const FilePreviewPage({super.key, required this.file});

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isVideoInitialized = false;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    final localPath = widget.file.localPath;
    if (localPath == null) return;

    switch (widget.file.type) {
      case FileItemType.video:
        _videoController = VideoPlayerController.file(File(localPath))
          ..initialize().then((_) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController!.play();
          });
        break;
      case FileItemType.audio:
        _audioPlayer = AudioPlayer();
        _audioPlayer!.play(DeviceFileSource(localPath));
        setState(() {
          _isAudioPlaying = true;
        });
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          if (widget.file.remoteUrl != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                // TODO: Download file
              },
            ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (widget.file.type) {
      case FileItemType.image:
        if (widget.file.localPath != null) {
          return Center(
            child: Image.file(
              File(widget.file.localPath!),
              fit: BoxFit.contain,
            ),
          );
        } else if (widget.file.remoteUrl != null) {
          return Center(
            child: Image.network(
              widget.file.remoteUrl!,
              fit: BoxFit.contain,
            ),
          );
        }
        return const Center(child: Text('No image data'));
      case FileItemType.video:
        if (_isVideoInitialized && _videoController != null) {
          return Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      case FileItemType.audio:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.audio_file, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                widget.file.name,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              if (_audioPlayer != null)
                StreamBuilder<Duration>(
                  stream: _audioPlayer!.onPositionChanged,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return FutureBuilder<Duration?>(
                      future: _audioPlayer!.getDuration(),
                      builder: (context, durationSnapshot) {
                        final duration = durationSnapshot.data ?? Duration.zero;
                        return Column(
                          children: [
                            Slider(
                              value: position.inMilliseconds.toDouble(),
                              max: duration?.inMilliseconds.toDouble() ?? 1,
                              onChanged: (value) {
                                _audioPlayer!.seek(Duration(milliseconds: value.toInt()));
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    _formatDuration(duration ?? Duration.zero),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              IconButton(
                icon: Icon(
                  _isAudioPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 48,
                ),
                onPressed: () async {
                  if (_isAudioPlaying) {
                    await _audioPlayer!.pause();
                    setState(() {
                      _isAudioPlaying = false;
                    });
                  } else {
                    await _audioPlayer!.resume();
                    setState(() {
                      _isAudioPlaying = true;
                    });
                  }
                },
              ),
            ],
          ),
        );
      case FileItemType.pdf:
        if (widget.file.localPath != null) {
          return PDFView(
            filePath: widget.file.localPath!,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,
            onRender: (_pages) {},
            onViewCreated: (controller) {},
          );
        }
        return const Center(child: Text('Cannot preview PDF'));
      case FileItemType.other:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.insert_drive_file, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                widget.file.name,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                '${(widget.file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
    }
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
