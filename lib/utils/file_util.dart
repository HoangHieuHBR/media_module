
enum FileItemType {
  image,
  video,
  audio,
  apk,
  word,
  excel,
  powerpoint,
  json,
  pdf,
  text,
  other,
}

class FileUtil {
  static final FileUtil _instance = FileUtil._internal();

  factory FileUtil() {
    return _instance;
  }

  static FileItemType mapFileType(String fileName) {
    String lastPath = fileName.split('.').last;
    return switch (lastPath) {
      'pdf' => FileItemType.pdf,
      'doc' || 'docx' => FileItemType.word,
      'xls' || 'xlsx' => FileItemType.excel,
      'ppt' || 'pptx' => FileItemType.powerpoint,
      'json' => FileItemType.json,
      'txt' => FileItemType.text,
      'apk' => FileItemType.apk,
      'mp3' || 'wav' || 'aac' || 'm4a' => FileItemType.audio,
      'mp4' || 'mkv' || 'avi' || 'mov' => FileItemType.video,
      'jpg' ||
      'jpeg' ||
      'png' ||
      'gif' ||
      'svg' ||
      'webp' ||
      'bmp' =>
        FileItemType.image,
      _ => FileItemType.other,
    };
  }

  FileUtil._internal();
}
