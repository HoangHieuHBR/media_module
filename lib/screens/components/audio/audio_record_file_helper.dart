import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AudioRecordFileHelper {
  final String _recordsDirectoryName = "audio_records";
  String? _appDirPath;

  Future<String> get _getAppDirPath async {
    _appDirPath ??= (await getApplicationDocumentsDirectory()).path;
    return _appDirPath!;
  }

  Future<Directory> get getRecordsDirectory async {
    Directory recordsDir =
        Directory(path.join(await _getAppDirPath, _recordsDirectoryName));

    if (!(await recordsDir.exists())) {
      await recordsDir.create();
    }
    return recordsDir;
  }
}
