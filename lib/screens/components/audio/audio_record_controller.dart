import 'package:media_module/screens/components/audio/audio_record_file_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecordController {
  final AudioRecordFileHelper _audioRecordFileHelper;
  AudioRecordController(this._audioRecordFileHelper);

  Stream<double> get amplitudeStream => _audioRecorder
      .onAmplitudeChanged(const Duration(milliseconds: 180))
      .map((amp) => amp.current);

  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<void> start() async {
    final isMicroPermissionGranted = await _checkMicrophonePermission();

    if (!isMicroPermissionGranted) {
      throw Exception('Microphone permission is not granted');
    }

    try {
      await _audioRecorder.start(
        const RecordConfig(),
        path: (await _audioRecordFileHelper.getRecordsDirectory).path,
      );
    } catch (e) {
      rethrow;
    }
  }

  void pause() {
    _audioRecorder.pause();
  }

  void resume() {
    _audioRecorder.resume();
  }

  Future<bool> _checkMicrophonePermission() async {
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
