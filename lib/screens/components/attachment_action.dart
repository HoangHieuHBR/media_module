import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_module/config/config.dart';

import '../screens.dart';

class AttachmentAction extends StatefulWidget {
  final Function(List<File?> selectedFiles) onFileAttached;
  final List<File?> attachFileList;

  const AttachmentAction({
    super.key,
    required this.onFileAttached,
    this.attachFileList = const [],
  });

  @override
  State<AttachmentAction> createState() => _AttachmentActionState();
}

class _AttachmentActionState extends State<AttachmentAction> {
  void _openRecordVideo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VideoRecordView(),
      ),
    );
  }

  Widget buildRecordAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BottomSheetAction(
            actionKey: 'audio',
            icon: Icons.mic_outlined,
            title: 'Record an audio clip',
            // onActionTap: () => _showModalAndStartRecording(),
          ),
          BottomSheetAction(
            actionKey: 'video',
            icon: Icons.videocam_outlined,
            title: 'Record a video clip',
            onActionTap: () {
              _openRecordVideo();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildRecordAction();
  }
}

class BottomSheetAction extends StatelessWidget {
  final String actionKey;
  final String title;
  final IconData icon;
  final Color? color;
  final Function? onActionTap;
  const BottomSheetAction({
    super.key,
    required this.actionKey,
    required this.icon,
    required this.title,
    this.color,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      horizontalTitleGap: 0,
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(
        icon,
        color: color ?? Theme.of(context).colorScheme.secondTextColor,
      ),
      title: Text(
        ' $title',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color ?? Theme.of(context).colorScheme.secondTextColor,
            ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        if (onActionTap != null) {
          onActionTap!();
        }
      },
    );
  }
}
