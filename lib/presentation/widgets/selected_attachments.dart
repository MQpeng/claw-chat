import 'dart:io';
import 'package:flutter/material.dart';
import '../../../domain/entities/file_item.dart';
import '../../../domain/entities/file_item_type.dart';

typedef OnRemove = void Function(FileItem file);

class SelectedAttachments extends StatelessWidget {
  final List<FileItem> files;
  final OnRemove onRemove;

  const SelectedAttachments({
    super.key,
    required this.files,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return Container(
            width: 64,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: file.type.isImage && file.localPath != null
                        ? Image.file(
                            File(file.localPath!),
                            fit: BoxFit.cover,
                            width: 64,
                            height: 64,
                          )
                        : Center(
                            child: Icon(
                              _getIconForType(file.type),
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: IconButton(
                    icon: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                    onPressed: () => onRemove(file),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(FileItemType type) {
    switch (type) {
      case FileItemType.image:
        return Icons.image;
      case FileItemType.video:
        return Icons.video_file;
      case FileItemType.audio:
        return Icons.audio_file;
      case FileItemType.pdf:
        return Icons.picture_as_pdf;
      case FileItemType.excel:
        return Icons.table_chart;
      case FileItemType.other:
        return Icons.insert_drive_file;
    }
  }
}
