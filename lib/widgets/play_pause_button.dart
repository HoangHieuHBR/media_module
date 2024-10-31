import 'package:flutter/material.dart';

class PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final Function()? onTap;
  const PlayPauseButton(
      {super.key, required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Theme.of(context).colorScheme.primary,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Center(
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Theme.of(context).colorScheme.surface,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
