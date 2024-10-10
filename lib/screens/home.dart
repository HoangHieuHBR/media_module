import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../utils/file_util.dart';
import '../widgets/widgets.dart';
import 'components/attachment_action.dart';
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
  List<AttachmentItem> _attachFiles = [];

  final ImageFormat _format = ImageFormat.JPEG;

  String? _tempDir;

  final Uuid uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    getTemporaryDirectory().then((d) => _tempDir = d.path);
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

  void _navigateToMediaGalleryView(AttachmentItem attachment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) {
          return MediaGalleryView(
            selectAttachment: attachment,
            attachments: [..._attachFiles],
          );
        },
      ),
    );
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
      default:
        return const SizedBox();
    }
  }

  Widget videoAttachmentItem(AttachmentItem attachment) {
    VideoPlayerController controller =
        VideoPlayerController.file(attachment.file);

    return InkWell(
      onTap: () => _navigateToMediaGalleryView(attachment),
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
              child: Container(
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
                      _videoDuration(controller.value.duration),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
  }
}
