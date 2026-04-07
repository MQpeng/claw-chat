import 'package:hive/hive.dart';
import 'file_item_type.dart';

part 'file_item.g.dart';

@HiveType(typeId: 4)
class FileItem extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int size;
  @HiveField(3)
  final String? remoteUrl;
  @HiveField(4)
  final String? localPath;
  @HiveField(5)
  final String mimeType;
  @HiveField(6)
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
