import 'package:brahma_core/brahma_core.dart' show Motion;
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import '../look.dart';

/// Opens [builder]'s content in a sheet from the bottom, after Vaul: it
/// follows the finger, can be swiped down to close, and fits its content.
/// It moves on the drawer curve; under reduced motion it appears at once.
Future<T?> showSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  final reduced = Motion.reduced(context);
  return Navigator.of(context).push<T>(
    ModalSheetRoute<T>(
      swipeDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: reduced ? Duration.zero : const Duration(milliseconds: 300),
      transitionCurve: Ease.drawer,
      builder: (context) => KitSheet(child: builder(context)),
    ),
  );
}

/// The sheet's surface: rounded top corners, a hairline, a grab handle and
/// room for the system bar below.
class KitSheet extends StatelessWidget {
  const KitSheet({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = palette(Theme.of(context).brightness);
    return Sheet(
      decoration: MaterialSheetDecoration(
        size: SheetSize.fit,
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        clipBehavior: Clip.antiAlias,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                decoration: BoxDecoration(color: p.hairline, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: child),
          ],
        ),
      ),
    );
  }
}
