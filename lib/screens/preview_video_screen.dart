import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class PreviewVideoScreen extends StatefulWidget {
  final XFile videoFile;
  final Function(XFile? videoFile) onPopPreviousScreen;
  const PreviewVideoScreen({
    super.key,
    required this.videoFile,
    required this.onPopPreviousScreen,
  });

  @override
  State<PreviewVideoScreen> createState() => _PreviewVideoScreenState();
}

class _PreviewVideoScreenState extends State<PreviewVideoScreen> {
  XFile? videoFile;
  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;

  bool isShowVideoControl = true;

  @override
  void initState() {
    super.initState();
    videoFile = widget.videoFile;
    _startVideoPlayer();
  }

  @override
  void dispose() {
    videoController?.removeListener(videoPlayerListener!);
    videoController?.dispose();
    super.dispose();
  }

  Future<void> _startVideoPlayer() async {
    if (videoFile == null) {
      return;
    }

    final VideoPlayerController vController =
        VideoPlayerController.file(File(videoFile!.path));

    videoPlayerListener = () {
      if (videoController != null) {
        // Refreshing the state to update video player with the correct ratio.
        if (mounted) {
          setState(() {});
        }
        videoController!.removeListener(videoPlayerListener!);
      }
    };
    vController.addListener(videoPlayerListener!);
    await vController.setLooping(false);
    await vController.initialize();
    await videoController?.dispose();
    if (mounted) {
      setState(() {
        // imageFile = null;
        videoController = vController;
      });
    }
    await vController.play();
  }

  String _videoDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return '$minutes:$seconds';
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Container(
          width: MediaQuery.sizeOf(ctx).width * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                'Discard Media',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Flexible(
                child: Text(
                  'If you do this action now, you will lose any changes you\'ve made',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Discard',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildVideoPlayView() {
    final VideoPlayerController? localVideoController = videoController;

    if (localVideoController == null && videoFile == null) {
      return Container();
    } else if ((localVideoController == null)) {
      return Image.file(File(videoFile!.path));
    } else {
      return GestureDetector(
        onTap: () => setState(() {
          isShowVideoControl = !isShowVideoControl;
        }),
        child: buildFullScreen(
          child: AspectRatio(
            aspectRatio: localVideoController.value.aspectRatio,
            child: VideoPlayer(localVideoController),
          ),
        ),
      );
    }
  }

  Widget buildFullScreen({required Widget child}) {
    final size = videoController?.value.size ?? const Size(0, 0);
    final width = size.width;
    final height = size.height * 0.8;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(width: width, height: height, child: child),
    );
  }

  Widget buildVideoControlView() {
    final VideoPlayerController? localVideoController = videoController;

    if (localVideoController == null) {
      return Container();
    }

    return Visibility(
      visible: isShowVideoControl,
      child: Container(
        height: 40,
        width: MediaQuery.sizeOf(context).width,
        color: Colors.black.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            ValueListenableBuilder(
                valueListenable: localVideoController,
                builder: (context, value, child) {
                  return InkWell(
                    onTap: () {
                      if (value.isPlaying) {
                        localVideoController.pause();
                      } else {
                        localVideoController.play();
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
                  );
                }),
            Expanded(
              child: SizedBox(
                height: 5,
                child: VideoProgressIndicator(
                  localVideoController,
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
            ValueListenableBuilder(
              valueListenable: localVideoController,
              builder: (context, value, child) {
                return Text(
                  "${_videoDuration(value.position)} / ${_videoDuration(value.duration)}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () {},
            label: Text(
              'Save',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            icon: const Icon(
              Icons.system_update_tv_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          TextButton.icon(
            onPressed: () {
              _showDiscardDialog();
              widget.onPopPreviousScreen(null);
            },
            label: Text(
              'Retry',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
           
              widget.onPopPreviousScreen(videoFile);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Next',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
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
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            _showDiscardDialog();
            widget.onPopPreviousScreen(null);
          },
          icon: const Icon(Icons.keyboard_arrow_down),
          color: Colors.white,
          iconSize: 30,
        ),
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.8,
              width: MediaQuery.sizeOf(context).width,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: buildVideoPlayView(),
                  ),
                  Positioned(
                    bottom: 0,
                    child: buildVideoControlView(),
                  ),
                ],
              ),
            ),
          ),
          buildActionButton(),
        ],
      ),
    );
  }
}
