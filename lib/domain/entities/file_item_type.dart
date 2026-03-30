enum FileItemType {
  image,
  video,
  audio,
  pdf,
  excel,
  other;

  bool get isImage => this == FileItemType.image;
  bool get isVideo => this == FileItemType.video;
  bool get isAudio => this == FileItemType.audio;
  bool get isPdf => this == FileItemType.pdf;
  bool get isExcel => this == FileItemType.excel;
}
