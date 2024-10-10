import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:media_module/screens/screens.dart';
import 'package:video_player/video_player.dart';

import '../widgets/widgets.dart';

class MediaGalleryView extends StatefulWidget {
  final List<AttachmentItem> attachments;
  final AttachmentItem selectAttachment;
  const MediaGalleryView({
    super.key,
    required this.attachments,
    required this.selectAttachment,
  });

  @override
  State<MediaGalleryView> createState() => _MediaGalleryViewState();
}

class _MediaGalleryViewState extends State<MediaGalleryView> {
  late VideoPlayerController _controller;
  late Timer _inactiveTimer;
  bool _isUserActive = true;
  bool _showVideoControlView = false;

  String playbackSpeed = '1X';

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.selectAttachment.file)
      ..initialize().then((_) {
        setState(() {});
      })
      ..play();

    _inactiveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isUserActive) {
        setState(() {
          _isUserActive = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _inactiveTimer.cancel();
    super.dispose();
  }

  void _resetTimer() {
    setState(() {
      _isUserActive = true;
      _inactiveTimer.cancel();
      _inactiveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_isUserActive) {
          setState(() {
            _isUserActive = false;
          });
        }
      });
    });
  }

  Widget buildFullScreen({required Widget child}) {
    final size = _controller.value.size;
    final width = size.width;
    final height = size.height;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(width: width, height: height, child: child),
    );
  }

  Widget buildVideoPlayView() {
    if (_controller.value.isInitialized) {
      return GestureDetector(
        onTap: () {
          _resetTimer();
        },
        child: buildFullScreen(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Widget buildHeader() {
    const headerHeight = 60.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: _isUserActive ? -10 : -headerHeight,
      width: MediaQuery.sizeOf(context).width,
      height: headerHeight,
      child: Container(
        padding: const EdgeInsets.all(15),
        color: Colors.black.withOpacity(0.7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.picture_in_picture_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFooter() {
    const footerHeight = 120.0;

    List<PlaybackSpeedModel> playbackSpeedList = [
      PlaybackSpeedModel(title: '0.25x', id: '0.25X', speed: 0.25),
      PlaybackSpeedModel(title: '0.5x', id: '0.5X', speed: 0.5),
      PlaybackSpeedModel(title: '0.75x', id: '0.75X', speed: 0.75),
      PlaybackSpeedModel(title: '1x', id: '1X', speed: 1),
      PlaybackSpeedModel(title: '1.25x', id: '1.25X', speed: 1.25),
      PlaybackSpeedModel(title: '1.5x', id: '1.5X', speed: 1.5),
      PlaybackSpeedModel(title: '2x', id: '2X', speed: 2),
    ];

    void selectVideoSpeedBottomsheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return CustomBottomSheet(
            bottomSheetHeight: 0.45 * MediaQuery.sizeOf(context).height,
            showDivider: true,
            showHeader: true,
            headerTitle: 'Playback speed',
            bottomSheetBody: ListView.builder(
              itemCount: playbackSpeedList.length,
              itemBuilder: (context, index) {
                PlaybackSpeedModel playbackSpeedModel =
                    playbackSpeedList[index];
                bool isSelected = playbackSpeed == playbackSpeedModel.id;

                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.keyboard_double_arrow_right,
                    color: isSelected ? Colors.blue.shade900 : null,
                    size: 20,
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.blue.shade900,
                          size: 20,
                        )
                      : null,
                  title: Text(
                    playbackSpeedModel.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected ? Colors.blue.shade900 : null,
                        ),
                  ),
                  onTap: () {
                    setState(() {
                      playbackSpeed = playbackSpeedModel.id;
                      _controller.setPlaybackSpeed(playbackSpeedModel.speed);
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          );
        },
      );
    }

    Widget buildVideoControlView() {
      String videoDuration(Duration duration) {
        String twoDigits(int n) => n.toString().padLeft(2, '0');
        final minutes = duration.inMinutes;
        final seconds = twoDigits(duration.inSeconds.remainder(60));

        return '$minutes:$seconds';
      }

      return Container(
        height: 40,
        width: MediaQuery.sizeOf(context).width,
        color: Colors.black.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, child) {
              return Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    },
                    child: Icon(
                      (value.position == value.duration)
                          ? Icons.replay
                          : value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 5,
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        colors: VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white.withOpacity(0.5),
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    "${videoDuration(value.position)} / ${videoDuration(value.duration)}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ],
              );
            }),
      );
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: _isUserActive ? -10 : -footerHeight,
      width: MediaQuery.sizeOf(context).width,
      height: footerHeight,
      onEnd: () {
        setState(() {
          _showVideoControlView = _isUserActive;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _showVideoControlView
              ? buildVideoControlView()
              : const SizedBox(
                  height: 40,
                ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(15),
              color: Colors.black.withOpacity(0.7),
              width: MediaQuery.sizeOf(context).width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: null,
                    icon: Transform(
                      transform:
                          Matrix4.rotationY(math.pi), // Rotate 180 degrees
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.reply_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const IconButton(
                    onPressed: null,
                    icon: Icon(
                      Icons.closed_caption_outlined,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: selectVideoSpeedBottomsheet,
                    child: Text(
                      playbackSpeed,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const IconButton(
                    onPressed: null,
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: buildVideoPlayView(),
            ),
            buildHeader(),
            buildFooter(),
          ],
        ),
      ),
    );
  }
}

class PlaybackSpeedModel {
  final String id;
  final String title;
  final double speed;

  PlaybackSpeedModel({
    this.id = '1X',
    this.title = '1x',
    this.speed = 1,
  });
}
