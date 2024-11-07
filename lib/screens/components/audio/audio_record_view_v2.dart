import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';

class AudioRecordViewV2 extends StatefulWidget {
  final RecorderController recorderController;
  final double bottomSheetHeight;
  const AudioRecordViewV2({
    super.key,
    required this.recorderController,
    required this.bottomSheetHeight,
  });

  @override
  State<AudioRecordViewV2> createState() => _AudioRecordViewV2State();
}

class _AudioRecordViewV2State extends State<AudioRecordViewV2> {
  @override
  void initState() {
    super.initState();
    widget.recorderController.record();
  }

  @override
  void dispose() {
    widget.recorderController.dispose();
    super.dispose();
  }

  Widget buildWaveform() {
    final width = MediaQuery.of(context).size.width * 0.6;
    return AudioWaveforms(
      size: Size(width, 50),
      recorderController: widget.recorderController,
      waveStyle: WaveStyle(
        waveColor: Colors.blue.shade900,
        extendWaveform: true,
        showMiddleLine: false,
      ),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  Widget buildTimerText() {
    return StreamBuilder(
      initialData: 0,
      stream: widget.recorderController.onCurrentDuration,
      builder: (context, snapshot) {
        final durationInSec =
            (snapshot.data != null && snapshot.data is Duration)
                ? (snapshot.data as Duration).inSeconds
                : 0;

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
    return CustomBottomSheet(
      bottomSheetHeight: widget.bottomSheetHeight,
      bottomSheetBody: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic_outlined),
              Text(
                'Recording an audio clip...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.blue[100],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                    ),
                  ),
                ),
                buildWaveform(),
                buildTimerText(),
                const Spacer(),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue[900],
                  child: InkWell(
                    onTap: () async {
                      var result = await widget.recorderController.stop();
                      if (result != null && context.mounted) {
                        print("Record file path: $result");
                        print("Record file size: ${File(result).lengthSync()}");
                        Navigator.pop(context, File(result));
                      }
                    },
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
