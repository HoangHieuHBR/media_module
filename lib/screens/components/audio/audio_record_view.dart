import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_module/screens/components/audio/audio_record_controller.dart';
import 'package:media_module/screens/components/audio/audio_record_waves_view.dart';

import '../../../widgets/widgets.dart';

class RecordAudioView extends StatelessWidget {
  final AudioRecordController audioRecordController;
  final double bottomSheetHeight;
  const RecordAudioView({
    super.key,
    required this.audioRecordController,
    required this.bottomSheetHeight,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AudioRecordController>(
      create: (context) => audioRecordController,
      child: AudioRecordViewBody(
        audioRecordController: audioRecordController,
        bottomSheetHeight: bottomSheetHeight,
      ),
    );
  }
}

class AudioRecordViewBody extends StatefulWidget {
  final AudioRecordController audioRecordController;
  final double bottomSheetHeight;
  const AudioRecordViewBody({
    super.key,
    required this.audioRecordController,
    required this.bottomSheetHeight,
  });

  @override
  State<AudioRecordViewBody> createState() => _AudioRecordViewBodyState();
}

class _AudioRecordViewBodyState extends State<AudioRecordViewBody> {
  @override
  void initState() {
    super.initState();
    widget.audioRecordController.start();
  }

  @override
  void dispose() {
    widget.audioRecordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: CustomBottomSheet(
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
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.blue[100],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  const AudioWavesView(),
                  const _TimerText(),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue[900],
                    child: InkWell(
                      onTap: () async {
                        var result = await widget.audioRecordController.stop();
                        if (result != null && context.mounted) {
                          print("Record file path: ${result.path}");
                          print("Record file size: ${result.lengthSync()}");
                          Navigator.pop(context, result);
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
      ),
    );
  }
}

class _TimerText extends StatelessWidget {
  const _TimerText();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
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
    );
  }
}
