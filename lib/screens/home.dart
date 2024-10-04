import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/widgets.dart';
import 'components/attachment_action.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<File?> _attachFiles = [];

  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CustomBottomSheet(
          bottomSheetHeight: 0.4 * MediaQuery.sizeOf(context).height,
          bottomSheetBody: AttachmentAction(
            attachFileList: _attachFiles,
            onFileAttached: (selectedFiles) {
              _attachFiles = [..._attachFiles, ...selectedFiles];
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Home screen'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[],
        ),
      ),
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
