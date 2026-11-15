import 'package:brahma_core/brahma_core.dart' show Motion, Status;
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../look.dart';

/// Shows a short note at the bottom of the screen, after Sonner: it slides
/// up, stays four seconds (longer when hovered), and can be swiped away.
/// [status] picks its icon and colour; under reduced motion it just appears.
ToastificationItem showToast(
  BuildContext context,
  String title, {
  String? description,
  Status status = Status.info,
  Duration stay = const Duration(seconds: 4),
}) {
  final theme = Theme.of(context);
  final p = palette(theme.brightness);
  final tone = status == Status.info ? p.primary : status.color;
  return toastification.show(
    context: context,
    title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
    description: description == null ? null : Text(description, maxLines: 3, overflow: TextOverflow.ellipsis),
    icon: Icon(status.icon, color: tone),
    type: switch (status) {
      Status.good => ToastificationType.success,
      Status.warning => ToastificationType.warning,
      Status.serious || Status.critical => ToastificationType.error,
      Status.info => ToastificationType.info,
    },
    style: ToastificationStyle.flat,
    alignment: Alignment.bottomCenter,
    autoCloseDuration: stay,
    // Toasts are the exception to the 250 ms rule: Sonner's 400 ms.
    animationDuration: Motion.reduced(context) ? Duration.zero : const Duration(milliseconds: 400),
    primaryColor: tone,
    backgroundColor: p.surface,
    foregroundColor: p.text,
    borderRadius: BorderRadius.circular(Radii.sm),
    borderSide: BorderSide(color: p.hairline),
    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
    showProgressBar: false,
    dragToClose: true,
    pauseOnHover: true,
    closeButton: const ToastCloseButton(showType: CloseButtonShowType.onHover),
  );
}
