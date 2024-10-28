import 'dart:async';
import 'dart:io';

import 'package:media_module/screens/components/audio/audio_record_file_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;

class AudioRecordController {
  final AudioRecordFileHelper _audioRecordFileHelper;
  AudioRecordController(this._audioRecordFileHelper);

  final StreamController<int> _recordDurationController =
      StreamController<int>.broadcast()..add(0);

  Sink<int> get recordDurationInput => _recordDurationController.sink;

  Stream<double> get amplitudeStream => _audioRecorder
      .onAmplitudeChanged(const Duration(milliseconds: 160))
      .map((amp) => amp.current);

  Stream<RecordState> get recordStateStream => _audioRecorder.onStateChanged();

  Stream<int> get recordDurationOutput => _recordDurationController.stream;

  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _recordDurationTimer;
  int _recordDuration = 0;

  void _startRecordDurationTimer() {
    _recordDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordDuration++;
      recordDurationInput.add(_recordDuration);
    });
  }

  void _resetRecordDuration() {
    _recordDuration = 0;
    recordDurationInput.add(_recordDuration);
    _recordDurationTimer?.cancel();
  }

  Future<void> start() async {
    final isMicroPermissionGranted = await checkMicrophonePermission();

    if (!isMicroPermissionGranted) {
      throw Exception('Microphone permission is not granted');
    }

    try {
      final fileName = path.join(
        (await _audioRecordFileHelper.getRecordsDirectory).path,
        '${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      await _audioRecorder.start(
        const RecordConfig(),
        path: fileName,
      );

      _startRecordDurationTimer();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pause() async {
    _recordDurationTimer?.cancel();
    await _audioRecorder.pause();
  }

  void resume() {
    _startRecordDurationTimer();
    _audioRecorder.resume();
  }

  Future<File?> stop() async {
    final path = await _audioRecorder.stop();

    if (path != null) {
      _resetRecordDuration();
      return File(path);
    } else {
      return null;
    }
  }

  Future<void> delete(String filePath) async {
    await pause();

    try {
      await _audioRecordFileHelper.deleteRecord(filePath);
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _recordDurationController.close();
    _audioRecorder.dispose();
    _recordDurationTimer?.cancel();
    _recordDurationTimer = null;
  }

  Future<bool> checkMicrophonePermission() async {
    const microPermission = Permission.microphone;
    if (await microPermission.isGranted) {
      return true;
    } else {
      final result = await microPermission.request();
      if (result.isGranted || result.isLimited) {
        return true;
      } else {
        return false;
      }
    }
  }
}
