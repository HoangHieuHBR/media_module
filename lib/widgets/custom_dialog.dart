import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final Widget titleWidget;
  final EdgeInsetsGeometry? contentPadding;
  final Widget contentWidget;
  final String onSaveTitle;
  final String onCancelTitle;
  final Color? onSaveButtonColor;
  final Color? onCancelButtonColor;
  final void Function()? onSave;
  final void Function()? onCancel;
  const CustomDialog({
    super.key,
    required this.titleWidget,
    this.contentPadding,
    required this.contentWidget,
    this.onSaveTitle = 'Save',
    this.onCancelTitle = 'Cancel',
    this.onSaveButtonColor,
    this.onCancelButtonColor,
    this.onSave,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20))),
      actions: [
        TextButton(
          onPressed: onCancel ??
              () {
                Navigator.of(context).pop();
              },
          child: Text(
            onCancelTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onCancelButtonColor ?? Colors.redAccent,
                ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onSave != null) {
              onSave!();
            }
          },
          child: Text(
            onSaveTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onSaveButtonColor ?? Colors.blueAccent,
                ),
          ),
        ),
      ],
      title: titleWidget,
      contentPadding: contentPadding ?? const EdgeInsets.all(20),
      content: contentWidget,
    );
  }
}
