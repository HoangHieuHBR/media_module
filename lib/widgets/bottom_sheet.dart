import 'package:flutter/material.dart';

class DragHandle extends StatelessWidget {
  const DragHandle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: 40,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class BottomSheetTopBar extends StatelessWidget {
  final bool showBackButton;
  final bool showCloseButton;
  final bool showRemoveButton;
  final bool showDoneButton;
  final String title;
  final VoidCallback? onRemove;
  final VoidCallback? onDone;
  final VoidCallback? onClose;

  const BottomSheetTopBar({
    super.key,
    this.showBackButton = false,
    this.showCloseButton = false,
    this.showRemoveButton = false,
    this.title = '',
    this.showDoneButton = false,
    this.onRemove,
    this.onDone,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: SizedBox(
        height: 44.0, // the height of the header area is fixed
        child: Stack(
          children: [
            if (showBackButton)
              const Align(
                alignment: Alignment.centerLeft,
                child: BottomSheetButton(
                  icon: Icons.arrow_back_ios,
                ),
              ),
            if (showCloseButton)
              Align(
                alignment: Alignment.centerLeft,
                child: BottomSheetButton(
                  icon: Icons.close,
                  onTap: () =>
                      onClose != null ? onDone!() : Navigator.pop(context),
                ),
              ),
            if (showRemoveButton)
              Align(
                alignment: Alignment.centerLeft,
                child: BottomSheetButton(
                  widget: Text(
                    'Close',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.right,
                  ),
                  onTap: () => onRemove?.call(),
                ),
              ),
            Align(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (showDoneButton)
              Align(
                alignment: Alignment.centerRight,
                child: BottomSheetButton(
                  widget: Text(
                    'Done',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.right,
                  ),
                  onTap: () =>
                      onDone != null ? onDone!() : Navigator.pop(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CustomBottomSheet extends StatelessWidget {
  final Widget bottomSheetBody;
  final double? bottomSheetHeight;
  final Color? borderColor;
  final double borderWidth;
  final String headerTitle;
  final bool showDragHandle;
  final bool showHeader;
  final bool showDivider;
  final bool showBackButton;
  final bool showCloseButton;
  final bool showRemoveButton;
  final bool showDoneButton;
  final VoidCallback? onRemove;
  final VoidCallback? onDone;
  final VoidCallback? onClose;
  const CustomBottomSheet({
    super.key,
    required this.bottomSheetBody,
    this.bottomSheetHeight,
    this.borderColor,
    this.borderWidth = 1,
    this.headerTitle = '',
    this.showDragHandle = true,
    this.showHeader = false,
    this.showDivider = false,
    this.showBackButton = false,
    this.showCloseButton = false,
    this.showRemoveButton = false,
    this.showDoneButton = false,
    this.onRemove,
    this.onDone,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: bottomSheetHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (showDragHandle) const DragHandle(),
          if (showHeader)
            BottomSheetTopBar(
              title: headerTitle,
              showBackButton: showBackButton,
              showCloseButton: showCloseButton,
              showRemoveButton: showRemoveButton,
              showDoneButton: showDoneButton,
              onRemove: onRemove,
              onDone: onDone,
              onClose: onClose,
            ),
          if (showDivider) const Divider(height: 0.5, thickness: 0.5),
          Expanded(
            child: bottomSheetBody,
          ),
        ],
      ),
    );
  }
}

class BottomSheetButton extends StatelessWidget {
  const BottomSheetButton({
    super.key,
    this.widget,
    this.icon,
    this.iconSize = 24,
    this.onTap,
  });

  final Widget? widget;
  final VoidCallback? onTap;
  final IconData? icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: widget ??
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: Icon(icon),
            ),
      ),
    );
  }
}
