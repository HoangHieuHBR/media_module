import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

import '../../../widgets/play_pause_button.dart';
import '../../media_gallery_view.dart';

class AudioPlayView extends StatefulWidget {
  final File audioFile;

  const AudioPlayView({
    super.key,
    required this.audioFile,
  });

  @override
  State<AudioPlayView> createState() => _AudioPlayViewState();
}

class _AudioPlayViewState extends State<AudioPlayView> {
  late final PlayerController playerController;
  late StreamSubscription<PlayerState> playerStateSubscription;
  ValueNotifier<PlaybackSpeedModel> playbackSpeed =
      ValueNotifier(playbackSpeedList[3]);

  File? file;

  List<double> waveformData = const [];

  @override
  void initState() {
    super.initState();
    playerController = PlayerController();
    playerStateSubscription = playerController.onPlayerStateChanged.listen((_) {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preparePlayer();
  }

  @override
  void dispose() {
    playerStateSubscription.cancel();
    playerController.dispose();
    super.dispose();
  }

  Future<void> _preparePlayer() async {
    file = widget.audioFile;

    if (file?.path == null) {
      return;
    }

    playerController.updateFrequency = UpdateFrequency.high;

    if (mounted) {
      final samples = const PlayerWaveStyle().getSamplesForWidth(200);

      await playerController.preparePlayer(
        path: file!.path,
        noOfSamples: samples,
      );

      playerController
          .extractWaveformData(
            path: file!.path,
            noOfSamples: samples,
          )
          .then((data) => waveformData = data);
    }
  }

  Widget buildWaveformView() {
    return Row(
      children: [
        AudioFileWaveforms(
          size: Size(MediaQuery.sizeOf(context).width * 0.5, 70),
          playerController: playerController,
          waveformData: waveformData,
          playerWaveStyle: PlayerWaveStyle(
            fixedWaveColor: Colors.grey[300]!,
            liveWaveColor: Theme.of(context).primaryColor,
            spacing: 8,
            showSeekLine: false,
            scaleFactor: 200,
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
      stream: playerController.onCurrentDurationChanged,
      builder: (context, snapshot) {
        final durationInSec = snapshot.data != null
            ? (snapshot.data != 0
                ? (snapshot.data! / 1000).round()
                : (playerController.maxDuration / 1000).round())
            : (playerController.maxDuration / 1000).round();

        final int minutes = durationInSec ~/ 60;
        final int seconds = durationInSec % 60;

        return Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
    );
  }

  Widget buildPlayButton() {
    return PlayPauseButton(
      isPlaying: playerController.playerState == PlayerState.playing,
      onTap: () async {
        playerController.playerState.isPlaying
            ? await playerController.pausePlayer()
            : await playerController.startPlayer(
                finishMode: FinishMode.pause,
              );
      },
    );
  }

  Widget buildChangeSpeedButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        int currentIndex = playbackSpeedList.indexOf(playbackSpeed.value);
        int nextIndex = (currentIndex + 1) % playbackSpeedList.length;
        playbackSpeed.value = playbackSpeedList[nextIndex];
        playerController.setRate(playbackSpeed.value.speed);
      },
      child: Container(
        width: 50,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: ValueListenableBuilder(
            valueListenable: playbackSpeed,
            builder: (context, value, _) {
              return Text(
                value.title,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.8,
      height: 60,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildPlayButton(),
          buildWaveformView(),
          buildChangeSpeedButton(),
        ],
      ),
    );
  }
}
