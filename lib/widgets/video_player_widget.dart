import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize video player controller with the provided video URL
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    )..initialize().then((_) {
        // Set the video to loop and start playing once initialized
        _controller.setLooping(true);
        _controller.play();
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(
                  key:
                      UniqueKey(), // Ensures the VideoPlayer widget rebuilds when a new controller is set
                  _controller,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          )
        // Display a circular progress indicator while the video loads
        : const Center(child: CircularProgressIndicator());
  }

  @override
  void dispose() {
    super.dispose();
    // Dispose of the video controller when the widget is disposed
    _controller.dispose();
  }
}
