import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'preview_video_screen.dart';

class VideoRecordView extends StatefulWidget {
  const VideoRecordView({super.key});

  @override
  State<VideoRecordView> createState() => _VideoRecordViewState();
}

void _logError(String code, String? message) {
  // ignore: avoid_print
  print('Error: $code${message == null ? '' : '\nError Message: $message'}');
}

class _VideoRecordViewState extends State<VideoRecordView> {
  CameraController? controller;
  VideoPlayerController? videoController;

  XFile? imageFile;
  XFile? videoFile;

  late Stopwatch _stopwatch;

  List<CameraDescription> _cameras = <CameraDescription>[];

  CameraDescription? _selectedCamera;

  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  int _pointers = 0;

  bool enableAudio = true;
  bool isVideoMode = true;

  @override
  void initState() {
    super.initState();

    _initCamera();

    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();

    if (_cameras.isNotEmpty) {
      _selectedCamera = _cameras.first;
      _initializeCameraController(_selectedCamera!);
    }
  }

  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.veryHigh,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        _showInSnackBar(
            'Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
      await Future.wait(<Future<Object?>>[
        // The exposure mode is currently not supported on the web.
        ...!kIsWeb
            ? <Future<Object?>>[
                cameraController.getMinExposureOffset().then(
                    (double value) => _minAvailableExposureOffset = value),
                cameraController
                    .getMaxExposureOffset()
                    .then((double value) => _maxAvailableExposureOffset = value)
              ]
            : <Future<Object?>>[],
        cameraController
            .getMaxZoomLevel()
            .then((double value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((double value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          _showInSnackBar('You have denied camera access.');
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          _showInSnackBar('Please go to Settings app to enable camera access.');
        case 'CameraAccessRestricted':
          // iOS only
          _showInSnackBar('Camera access is restricted.');
        case 'AudioAccessDenied':
          _showInSnackBar('You have denied audio access.');
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          _showInSnackBar('Please go to Settings app to enable audio access.');
        case 'AudioAccessRestricted':
          // iOS only
          _showInSnackBar('Audio access is restricted.');
        default:
          _showCameraException(e);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    await _initializeCameraController(cameraDescription);
    setState(() {
      _selectedCamera = cameraDescription;
    });
  }

  Future<void> _startVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      _showInSnackBar('Error: select a camera first.');
      return;
    }

    if (cameraController.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return;
    }

    try {
      await cameraController.startVideoRecording();
      // Stop recording after 5 minutes
      if (cameraController.value.isRecordingVideo &&
          _stopwatch.elapsed.inSeconds >= 300) {
        _onStopButtonPressed();
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      return;
    }
  }

  Future<void> _pauseVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return;
    }

    try {
      await cameraController.pauseVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _resumeVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return;
    }

    try {
      await cameraController.resumeVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<XFile?> _stopVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return null;
    }

    try {
      return cameraController.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  Future<XFile?> _takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      _showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    _showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final CameraController cameraController = controller!;

    final Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  void _onTakePictureButtonPressed() {
    _takePicture().then((XFile? file) {
      if (mounted) {
        setState(() {
          imageFile = file;
          videoController?.dispose();
          videoController = null;
        });
        if (file != null) {
          _showInSnackBar('Picture saved to ${file.path}');
        }
      }
    });
  }

  void _onVideoRecordButtonPressed() {
    _startVideoRecording().then((_) {
      _handleStartStop();
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onStopButtonPressed() {
    _stopVideoRecording().then((XFile? file) {
      _timerReset();
      if (mounted) {
        setState(() {});
      }
      if (mounted && file != null) {
        // _showInSnackBar('Video recorded to ${file.path}');
        // videoFile = file;
        // _startVideoPlayer();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) {
              return PreviewVideoScreen(
                videoFile: file,
                onPopPreviousScreen: (file) {
                  Navigator.pop(context, file);
                },
              );
            },
          ),
        );
      }
    });
  }

  void _onPauseButtonPressed() {
    _pauseVideoRecording().then((_) {
      _handleStartStop();
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onResumeButtonPressed() {
    _resumeVideoRecording().then((_) {
      _handleStartStop();
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleStartStop() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
    } else {
      _stopwatch.start();
    }
    setState(() {});
  }

  void _timerReset() {
    if (_stopwatch.isRunning) {
      setState(() {
        _stopwatch.reset();
      });
    }
  }

  Widget buildCameraPreviewWidget() {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return Container(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        color: Colors.grey,
      );
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          controller!,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onTapDown: (TapDownDetails details) =>
                  onViewFinderTap(details, constraints),
            );
          }),
        ),
      );
    }
  }

  Widget buildCameraActionButton() {
    final CameraController? cameraController = controller;

    void onChanged() {
      if (_cameras.isEmpty) {
        return;
      }

      final currentIndex = _cameras.indexOf(_selectedCamera!);
      final nextIndex = (currentIndex + 1) % _cameras.length;
      _onNewCameraSelected(_cameras[nextIndex]);
    }

    Widget buildCaptureButton({bool isTakePhotoMode = false}) {
      if (cameraController != null) {
        if (cameraController.value.isRecordingVideo) {
          return StreamBuilder<int>(
            stream: Stream.periodic(const Duration(seconds: 1),
                (_) => _stopwatch.elapsed.inSeconds).asBroadcastStream(),
            builder: (context, snapshot) {
              final elapsedSeconds = snapshot.data ?? 0;
              final minutes = (elapsedSeconds ~/ 60).toString().padLeft(1, '0');
              final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 20,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "$minutes:$seconds / 5:00",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  ElevatedButton(
                    onPressed: _onStopButtonPressed,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(
                        side: BorderSide(
                          color: Colors.white,
                          width: 2.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.transparent,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.stop,
                        color: Colors.red,
                        size: 35,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
        return ElevatedButton(
          onPressed: () {
            if (isTakePhotoMode && !cameraController.value.isRecordingVideo) {
              _onTakePictureButtonPressed();
            } else if (!isTakePhotoMode &&
                !cameraController.value.isRecordingVideo) {
              _onVideoRecordButtonPressed();
            }
          },
          child: null,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(
              side: BorderSide(
                color: Colors.white,
                width: 2.0,
              ),
            ),
            padding: const EdgeInsets.all(35),
            backgroundColor: isTakePhotoMode ? Colors.grey : Colors.red,
          ),
        );
      }
      return ElevatedButton(
        onPressed: null,
        child: null,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(
            side: BorderSide(
              color: Colors.white,
              width: 2.0,
            ),
          ),
          padding: const EdgeInsets.all(35),
          backgroundColor: Colors.grey,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        (cameraController != null && cameraController.value.isRecordingVideo)
            ? ElevatedButton(
                onPressed: () {
                  if (cameraController.value.isRecordingPaused) {
                    _onResumeButtonPressed();
                  } else {
                    _onPauseButtonPressed();
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(
                    side: BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                  ),
                  padding: (cameraController.value.isRecordingPaused)
                      ? const EdgeInsets.all(25)
                      : const EdgeInsets.all(10),
                  backgroundColor: (cameraController.value.isRecordingPaused)
                      ? Colors.red
                      : Colors.transparent,
                ),
                child: (cameraController.value.isRecordingPaused)
                    ? null
                    : const Center(
                        child: Icon(
                          Icons.pause,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
              )
            : IconButton(
                onPressed: () {},
                color: Colors.white,
                icon: const Icon(Icons.image),
                iconSize: 30,
              ),
        const SizedBox(
          width: 30,
        ),
        buildCaptureButton(isTakePhotoMode: !isVideoMode),
        const SizedBox(
          width: 30,
        ),
        (cameraController != null && cameraController.value.isRecordingVideo)
            ? SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.1,
              )
            : IconButton(
                icon: const Icon(Icons.flip_camera_ios),
                color: Colors.white,
                iconSize: 30,
                onPressed: onChanged,
              )
      ],
    );
  }

  Widget buildActionType() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: !isVideoMode
                ? null
                : () {
                    setState(() {
                      isVideoMode = false;
                    });
                  },
            child: Text(
              'PHOTO',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: !isVideoMode ? Colors.transparent : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(
            width: 30,
          ),
          Text(
            isVideoMode ? 'VIDEO' : 'PHOTO',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(
            width: 30,
          ),
          TextButton(
            onPressed: isVideoMode
                ? null
                : () {
                    setState(() {
                      isVideoMode = true;
                    });
                  },
            child: Text(
              'VIDEO',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isVideoMode ? Colors.transparent : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          )
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
          onPressed: () => Navigator.pop(context),
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
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.8,
                width: MediaQuery.sizeOf(context).width,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: buildCameraPreviewWidget(),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: buildCameraActionButton(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          buildActionType(),
        ],
      ),
    );
  }
}
