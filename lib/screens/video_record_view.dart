import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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

    if (_cameras.isNotEmpty) {
      _selectedCamera = _cameras.first;
      _initializeCameraController(_selectedCamera!);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
  }

  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      kIsWeb ? ResolutionPreset.max : ResolutionPreset.medium,
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

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
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

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    await _initializeCameraController(cameraDescription);
    setState(() {
      _selectedCamera = cameraDescription;
    });
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

  Widget buildCameraPreviewWidget() {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
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
    void onChanged() {
      if (_cameras.isEmpty) {
        return;
      }

      final currentIndex = _cameras.indexOf(_selectedCamera!);
      final nextIndex = (currentIndex + 1) % _cameras.length;
      _onNewCameraSelected(_cameras[nextIndex]);
    }

    Widget buildCaptureButton({bool isTakePhotoMode = false}) {
      return ElevatedButton(
        onPressed: () {
          if (isTakePhotoMode) {
            _onTakePictureButtonPressed();
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
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
        IconButton(
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
                  children: <Widget>[
                    Positioned(
                      top: 20,
                      left: 10,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        color: Colors.white,
                        iconSize: 30,
                        icon: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ),
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
