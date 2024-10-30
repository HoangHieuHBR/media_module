import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:media_module/utils/floating_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../utils/file_util.dart';
import '../widgets/play_pause_button.dart';
import '../widgets/widgets.dart';
import 'components/attachment_action.dart';
import 'components/audio/audio_play_waves_view.dart';
import 'media_gallery_view.dart';

class ThumbnailRequest {
  final String video;
  final String? thumbnailPath;
  final ImageFormat imageFormat;
  final int maxHeight;
  final int maxWidth;
  final int timeMs;
  final int quality;

  const ThumbnailRequest({
    required this.video,
    required this.thumbnailPath,
    required this.imageFormat,
    required this.maxHeight,
    required this.maxWidth,
    required this.timeMs,
    required this.quality,
  });
}

class ThumbnailResult {
  final Image image;
  final int dataSize;
  final int height;
  final int width;
  const ThumbnailResult(
      {required this.image,
      required this.dataSize,
      required this.height,
      required this.width});
}

class AttachmentItem {
  final String attachmentId;
  final File file;

  const AttachmentItem({
    required this.attachmentId,
    required this.file,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PlayerController playerController;
  late StreamSubscription<PlayerState> playerStateSubscription;
  ValueNotifier<PlaybackSpeedModel> playbackSpeed = ValueNotifier(
    PlaybackSpeedModel(),
  );
  List<AttachmentItem> _attachFiles = [];
  AttachmentItem? _selectedAttachment;

  final ImageFormat _format = ImageFormat.JPEG;

  String? _tempDir;

  final Uuid uuid = const Uuid();

  bool alreadyAddedOverlays = false;

  @override
  void initState() {
    super.initState();
    getTemporaryDirectory().then((d) => _tempDir = d.path);
    playerController = PlayerController();
    playerStateSubscription = playerController.onPlayerStateChanged.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    playerStateSubscription.cancel();
    playerController.dispose();
    super.dispose();
  }

  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CustomBottomSheet(
          bottomSheetHeight: 0.4 * MediaQuery.sizeOf(context).height,
          bottomSheetBody: AttachmentAction(
            attachFileList: _attachFiles.map((e) => e.file).toList(),
            onFileAttached: (selectedFiles) {
              for (var attachFile in selectedFiles) {
                var newAttachment = AttachmentItem(
                  attachmentId: uuid.v4(),
                  file: attachFile!,
                );

                _attachFiles = [..._attachFiles, newAttachment];
              }
              setState(() {});
            },
          ),
        );
      },
    );
  }

  String _videoDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return '$minutes:$seconds';
  }

  Future<ThumbnailResult> _buildVideoThumbnail(ThumbnailRequest r) async {
    final Completer<ThumbnailResult> completer = Completer();

    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: r.video,
      headers: {
        "USERHEADER1": "user defined header1",
        "USERHEADER2": "user defined header2",
      },
      thumbnailPath: r.thumbnailPath,
      imageFormat: r.imageFormat,
      maxHeight: r.maxHeight,
      maxWidth: r.maxWidth,
      timeMs: r.timeMs,
      quality: r.quality,
    );

    final file = File(thumbnailPath!);
    Uint8List bytes = file.readAsBytesSync();

    int imageDataSize = bytes.length;

    final image = Image.memory(
      bytes,
      fit: BoxFit.cover,
      height: r.maxHeight.toDouble(),
      width: r.maxWidth.toDouble(),
    );

    image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(ThumbnailResult(
        image: image,
        dataSize: imageDataSize,
        height: info.image.height,
        width: (MediaQuery.sizeOf(context).width * 0.8).toInt(),
      ));
    }));

    return completer.future;
  }

  Widget buildAttachmentList() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Scrollbar(
        child: ListView.builder(
          itemCount: _attachFiles.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            var attachment = _attachFiles[index];
            return attachmentItem(attachment);
          },
        ),
      ),
    );
  }

  Widget attachmentItem(AttachmentItem attachment) {
    FileItemType fileType = FileUtil.mapFileType(attachment.file.path);

    switch (fileType) {
      case FileItemType.video:
        return videoAttachmentItem(attachment);
      case FileItemType.audio:
        return audioAttachmentItem(attachment);
      default:
        return const SizedBox();
    }
  }

  Widget videoAttachmentItem(AttachmentItem attachment) {
    VideoPlayerController controller =
        VideoPlayerController.file(attachment.file);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAttachment = attachment;
        });
        FloatingUtil.showFull();
      },
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.3,
        width: MediaQuery.sizeOf(context).width * 0.8,
        child: Stack(
          children: [
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
              child: FutureBuilder<ThumbnailResult>(
                future: _buildVideoThumbnail(
                  ThumbnailRequest(
                    video: attachment.file.path,
                    thumbnailPath: _tempDir,
                    imageFormat: _format,
                    maxHeight: 0,
                    maxWidth: 0,
                    timeMs: 0,
                    quality: 50,
                  ),
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final image = snapshot.data!.image;
                    final imageHeight = snapshot.data!.height.toDouble();
                    final imageWidth = snapshot.data!.width.toDouble();

                    return SizedBox(
                      height: imageHeight,
                      width: imageWidth,
                      child: image,
                    );
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/330px-No-Image-Placeholder.svg.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            Positioned(
              bottom: 5,
              left: 5,
              child: FutureBuilder(
                  future: controller.initialize(),
                  builder: (context, snapshot) {
                    String videoDuration = '0:00';

                    if (snapshot.connectionState == ConnectionState.done) {
                      videoDuration = _videoDuration(controller.value.duration);

                      return Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            Text(
                              videoDuration,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            Text(
                              videoDuration,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget audioAttachmentItem(AttachmentItem attachment) {
    Widget buildPlayButton() {
      return PlayPauseButton(
        isPlaying: playerController.playerState == PlayerState.playing,
        onTap: () {
          if (playerController.playerState == PlayerState.playing) {
            playerController.pausePlayer();
          } else {
            playerController.startPlayer();
          }
        },
      );
    }

    Widget buildChangeSpeedButton() {
      return InkWell(
        onTap: () {
          int currentIndex = playbackSpeedList.indexOf(playbackSpeed.value);
          int nextIndex = (currentIndex + 1) % playbackSpeedList.length;
          playbackSpeed.value = playbackSpeedList[nextIndex];
          playerController.setRate(playbackSpeed.value.speed);
        },
        child: Container(
          width: 70,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
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

    return Container(
      width: MediaQuery.sizeOf(context).width * 0.8,
      height: 100,
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
        children: [
          buildPlayButton(),
          const SizedBox(
            width: 5,
          ),
          AudioPlayWavesView(
            audioFile: attachment.file,
            audioPlayerController: playerController,
            waveSize: Size(MediaQuery.sizeOf(context).width * 0.6, 50),
          ),
          const SizedBox(
            width: 5,
          ),
          buildChangeSpeedButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (layoutContext, constraints) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (alreadyAddedOverlays || _selectedAttachment == null) {
          return;
        }

        Overlay.of(layoutContext).insert(
          OverlayEntry(
            builder: (context) => MediaGalleryView(
              selectAttachment: _selectedAttachment!,
              attachments: [..._attachFiles],
            ),
          ),
        );

        alreadyAddedOverlays = true;
      });

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Home screen'),
        ),
        body: buildAttachmentList(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAttachmentBottomSheet();
          },
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      );
    });
  }
}
