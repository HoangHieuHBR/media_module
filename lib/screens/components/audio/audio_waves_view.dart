import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_module/screens/components/audio/audio_record_controller.dart';

class AudioWavesView extends StatefulWidget {
  const AudioWavesView({super.key});

  @override
  State<AudioWavesView> createState() => _AudioWavesViewState();
}

class _AudioWavesViewState extends State<AudioWavesView> {
  final ScrollController _scrollController = ScrollController();
  List<double> amplitudes = [];
  late StreamSubscription<double> amplitudeSubscription;
  double wavesMaxHeight = 45;
  final double minimumAmpl = -67;

  @override
  void initState() {
    super.initState();
    amplitudeSubscription =
        context.read<AudioRecordController>().amplitudeStream.listen((amp) {
      setState(() {
        amplitudes.add(amp);
      });

      if (_scrollController.positions.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 160),
        );
      }
    });
  }

  @override
  void dispose() {
    amplitudeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: wavesMaxHeight,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: amplitudes.length,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          double amplitue = amplitudes[index].clamp(minimumAmpl, 0);

          double amplPercentage = 1 - (amplitue / minimumAmpl).abs();

          double waveHeight = wavesMaxHeight * amplPercentage;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: waveHeight),
                duration: const Duration(milliseconds: 140),
                curve: Curves.decelerate,
                builder: (context, waveHeight, child) {
                  return SizedBox(
                    height: waveHeight,
                    width: 8,
                    child: child,
                  );
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
