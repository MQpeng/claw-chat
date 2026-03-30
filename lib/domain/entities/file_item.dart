import 'package:hive/hive.dart';
import 'file_item_type.dart';

class FileItem extends HiveObject {
  final String id;
  final String name;
  final int size;
  final String? remoteUrl;
  final String? localPath;
  final String mimeType;
  final FileItemType type;

  FileItem({
    required this.id,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.type,
    this.remoteUrl,
    this.localPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'remoteUrl': remoteUrl,
      'localPath': localPath,
      'mimeType': mimeType,
      'type': type.name,
    };
  }

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'] as String,
      name: json['name'] as String,
      size: json['size'] as int,
      mimeType: json['mimeType'] as String,
      type: FileItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FileItemType.other,
      ),
      remoteUrl: json['remoteUrl'] as String?,
      localPath: json['localPath'] as String?,
    );
  }

  FileItem copyWith({
    String? id,
    String? name,
    int? size,
    String? remoteUrl,
    String? localPath,
    String? mimeType,
    FileItemType? type,
  }) {
    return FileItem(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      type: type ?? this.type,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      localPath: localPath ?? this.localPath,
    );
  }
}
