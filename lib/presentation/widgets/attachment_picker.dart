import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../domain/entities/file_item.dart';
import '../../../domain/entities/file_item_type.dart';

typedef OnAttachmentSelected = void Function(List<FileItem> files);

class AttachmentPicker extends StatelessWidget {
  final OnAttachmentSelected onAttachmentSelected;

  const AttachmentPicker({
    super.key,
    required this.onAttachmentSelected,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要相机权限才能拍照')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return;

    final file = FileItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: image.name,
      size: await image.readAsBytes().then((value) => value.length),
      mimeType: 'image/jpeg',
      type: FileItemType.image,
      localPath: image.path,
    );

    onAttachmentSelected([file]);
  }

  Future<void> _pickFiles(BuildContext context) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要存储权限才能选择文件')),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final files = result.files.map((file) {
      FileItemType type = FileItemType.other;
      final extension = file.extension?.toLowerCase() ?? '';
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

      return FileItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() +
            (file.name ?? ''),
        name: file.name ?? 'unknown',
        size: file.size ?? 0,
        mimeType: mimeType,
        type: type,
        localPath: file.path,
      );
    }).toList();

    onAttachmentSelected(files);
  }

  String _getMimeType(String? extension) {
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

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: const FaIcon(FontAwesomeIcons.camera),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          label: '拍照',
          onTap: () => _pickImage(context, ImageSource.camera),
        ),
        SpeedDialChild(
          child: const FaIcon(FontAwesomeIcons.image),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          label: '从相册选择',
          onTap: () => _pickImage(context, ImageSource.gallery),
        ),
        SpeedDialChild(
          child: const FaIcon(FontAwesomeIcons.file),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          label: '选择文件',
          onTap: () => _pickFiles(context),
        ),
      ],
    );
  }
}
