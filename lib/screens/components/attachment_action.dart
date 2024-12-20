import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:media_module/config/config.dart';
import 'package:media_module/screens/components/audio/audio_record_controller.dart';

import '../screens.dart';
import 'audio/audio_record_file_helper.dart';
import 'audio/audio_record_view_v2.dart';

class AttachmentAction extends StatefulWidget {
  final Function(List<File?> selectedFiles) onFileAttached;
  final List<File?> attachFileList;

  const AttachmentAction({
    super.key,
    required this.onFileAttached,
    this.attachFileList = const [],
  });

  @override
  State<AttachmentAction> createState() => _AttachmentActionState();
}

class _AttachmentActionState extends State<AttachmentAction> {
  final AudioRecordController _audioRecordController = AudioRecordController(
    AudioRecordFileHelper(),
  );
  late final RecorderController recorderController;

  bool _isRecordingAudio = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100
      ..bitRate = 48000;
  }

  void _showModalAndStartRecording() async {
    final permission = await _audioRecordController.checkMicrophonePermission();
    // final permission = await recorderController.checkPermission();
    if (permission) {
      setState(() {
        _isRecordingAudio = true;
      });
      if (mounted) {
        _showRecordAudioView();
      }
    }
  }

  void _showRecordAudioView() async {
    var result = await showModalBottomSheet(
      enableDrag: _isRecordingAudio ? false : true,
      isDismissible: _isRecordingAudio ? false : true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (btContext) {
        // return RecordAudioView(
        //   audioRecordController: _audioRecordController,
        //   bottomSheetHeight: MediaQuery.of(context).size.height * 0.15,
        // );
        return AudioRecordViewV2(
          recorderController: recorderController,
          bottomSheetHeight: MediaQuery.of(context).size.height * 0.15,
        );
      },
    );

    if (result != null && result is File) {
      widget.onFileAttached([result]);
    }
  }

  void _openRecordVideo() async {
    var result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VideoRecordView(),
      ),
    );

    if (result != null && result is XFile) {
      var file = File(result.path);
      widget.onFileAttached([file]);
    }
  }

  Widget buildRecordAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BottomSheetAction(
            actionKey: 'audio',
            icon: Icons.mic_outlined,
            title: 'Record an audio clip',
            onActionTap: () => _showModalAndStartRecording(),
          ),
          BottomSheetAction(
            actionKey: 'video',
            icon: Icons.videocam_outlined,
            title: 'Record a video clip',
            onActionTap: () => _openRecordVideo(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildRecordAction();
  }
}

class BottomSheetAction extends StatelessWidget {
  final String actionKey;
  final String title;
  final IconData icon;
  final Color? color;
  final Function? onActionTap;
  const BottomSheetAction({
    super.key,
    required this.actionKey,
    required this.icon,
    required this.title,
    this.color,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      horizontalTitleGap: 0,
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(
        icon,
        color: color ?? Theme.of(context).colorScheme.secondTextColor,
      ),
      title: Text(
        ' $title',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color ?? Theme.of(context).colorScheme.secondTextColor,
            ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        if (onActionTap != null) {
          onActionTap!();
        }
      },
    );
  }
}
