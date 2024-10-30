import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

class AudioPlayWavesView extends StatefulWidget {
  final PlayerController audioPlayerController;
  final File audioFile;
  final Size waveSize;

  const AudioPlayWavesView({
    super.key,
    required this.audioPlayerController,
    required this.audioFile,
    required this.waveSize,
  });

  @override
  State<AudioPlayWavesView> createState() => _AudioPlayWavesViewState();
}

class _AudioPlayWavesViewState extends State<AudioPlayWavesView> {
  File? file;

  @override
  void initState() {
    super.initState();

    _preparePlayer();
  }

  void _preparePlayer() async {
    file = widget.audioFile;

    widget.audioPlayerController.preparePlayer(
      path: file!.path,
    );
  }

  Widget buildWaveformView() {
    return Row(
      children: [
        AudioFileWaveforms(
          size: widget.waveSize,
          playerController: widget.audioPlayerController,
          playerWaveStyle: PlayerWaveStyle(
            fixedWaveColor: Colors.white54,
            liveWaveColor: Theme.of(context).primaryColor,
            spacing: 8,
          ),
        ),
        const SizedBox(
          width: 5,
        ),
        buildTimerText(),
      ],
    );
  }

  Widget buildTimerText() {
    return StreamBuilder(
      initialData: 0,
      stream: widget.audioPlayerController.onCurrentDurationChanged,
      builder: (context, snapshot) {
        final durationInSec =
            snapshot.data ?? widget.audioPlayerController.maxDuration;

        final int minutes = durationInSec ~/ 60;
        final int seconds = durationInSec % 60;

        return Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildWaveformView();
  }
}
