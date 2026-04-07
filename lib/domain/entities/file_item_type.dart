import 'package:hive/hive.dart';

part 'file_item_type.g.dart';

@HiveType(typeId: 5)
enum FileItemType {
  @HiveField(0)
  image,
  @HiveField(1)
  video,
  @HiveField(2)
  audio,
  @HiveField(3)
  pdf,
  @HiveField(4)
  other;

  bool get isImage => this == FileItemType.image;
  bool get isVideo => this == FileItemType.video;
  bool get isAudio => this == FileItemType.audio;
  bool get isPdf => this == FileItemType.pdf;
}
