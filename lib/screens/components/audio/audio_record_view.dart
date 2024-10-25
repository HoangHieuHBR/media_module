import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_module/screens/components/audio/audio_record_controller.dart';
import 'package:media_module/screens/components/audio/audio_record_file_helper.dart';
import 'package:media_module/screens/components/audio/audio_waves_view.dart';
import 'package:record/record.dart';

import '../../../widgets/play_pause_button.dart';

class RecordAudioView extends StatelessWidget {
  const RecordAudioView({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AudioRecordController>(
      create: (context) => AudioRecordController(AudioRecordFileHelper()),
      child: const AudioRecordViewBody(),
    );
  }
}

class AudioRecordViewBody extends StatefulWidget {
  const AudioRecordViewBody({super.key});

  @override
  State<AudioRecordViewBody> createState() => _AudioRecordViewBodyState();
}

class _AudioRecordViewBodyState extends State<AudioRecordViewBody> {
  late final AudioRecordController audioRecordController;

  @override
  void initState() {
    super.initState();
    audioRecordController = context.read<AudioRecordController>();
    audioRecordController.start();
  }

  @override
  void dispose() {
    audioRecordController.dispose();
    super.dispose();
  }

  Widget buildRecordButton() {
    return StreamBuilder(
      stream: audioRecordController.recordStateStream,
      builder: (context, snapshot) {
        final recordState = snapshot.data ?? RecordState.record;

        return PlayPauseButton(
          isPlaying: recordState == RecordState.record,
          onTap: () {
            if (recordState == RecordState.pause) {
              audioRecordController.resume();
            } else {
              audioRecordController.pause();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          const AudioWavesView(),
          const SizedBox(height: 16),
          const _TimerText(),
          const SizedBox(
            height: 10,
          ),
          buildRecordButton(),
        ],
      ),
    );
  }
}

class _TimerText extends StatelessWidget {
  const _TimerText({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder(
        initialData: 0,
        stream: context.read<AudioRecordController>().recordDurationOutput,
        builder: (context, snapshot) {
          final durationInSec = snapshot.data ?? 0;

          final int minutes = durationInSec ~/ 60;
          final int seconds = durationInSec % 60;
          return Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        },
      ),
    );
  }
}
