import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../domain/entities/file_item.dart';
import '../../../domain/entities/file_item_type.dart';

typedef OnAttachmentSelected = void Function(FileItem file);

class AttachmentPicker {
  static Future<void> show({
    required BuildContext context,
    required OnAttachmentSelected onFilePicked,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: FaIcon(FontAwesomeIcons.camera, color: Colors.white),
              ),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final status = await Permission.camera.request();
                if (!status.isGranted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera permission required')),
                  );
                  return;
                }
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.camera);
                if (image == null) return;
                final file = FileItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: image.name,
                  size: await image.readAsBytes().then((value) => value.length),
                  mimeType: 'image/jpeg',
                  type: FileItemType.image,
                  localPath: image.path,
                );
                onFilePicked(file);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: FaIcon(FontAwesomeIcons.image, color: Colors.white),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                if (image == null) return;
                final file = FileItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: image.name,
                  size: await image.readAsBytes().then((value) => value.length),
                  mimeType: 'image/jpeg',
                  type: FileItemType.image,
                  localPath: image.path,
                );
                onFilePicked(file);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: FaIcon(FontAwesomeIcons.file, color: Colors.white),
              ),
              title: const Text('Choose File'),
              onTap: () async {
                Navigator.pop(context);
                final status = await Permission.storage.request();
                if (!status.isGranted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Storage permission required')),
                  );
                  return;
                }
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: false,
                  withData: false,
                );
                if (result == null || result.files.isEmpty) return;
                final fileInfo = result.files.first;
                FileItemType type = FileItemType.other;
                final extension = fileInfo.extension?.toLowerCase() ?? '';
                final mimeType = _getMimeType(extension);

                if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
                  type = FileItemType.image;
                } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
                  type = FileItemType.video;
                } else if (['mp3', 'wav', 'ogg', 'flac'].contains(extension)) {
                  type = FileItemType.audio;
                } else if (extension == 'pdf') {
                  type = FileItemType.pdf;
                }

                final file = FileItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString() + (fileInfo.name ?? ''),
                  name: fileInfo.name ?? 'unknown',
                  size: fileInfo.size ?? 0,
                  mimeType: mimeType,
                  type: type,
                  localPath: fileInfo.path,
                );
                onFilePicked(file);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static String _getMimeType(String? extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
