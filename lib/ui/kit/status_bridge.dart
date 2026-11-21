import 'package:brahma_core/brahma_core.dart' show Status;
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart' show ToastificationItem;
import 'package:ui_kit/ui_kit.dart' as ui;

// The kit speaks its own KitStatus (it does not depend on brahma_core);
// Udyoga speaks brahma_core's Status. These thin wrappers take a Status and
// hand the kit the KitStatus of the same name, so pages keep using Status.

extension StatusKit on Status {
  /// The kit's status of the same name, with the same colour and icon.
  ui.KitStatus get kit => ui.KitStatus.values.byName(name);
}

/// The kit's [ui.StatusPill], taking a brahma_core [Status].
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.status, this.icon, this.dot = true, this.quiet = false});
  final String label;
  final Status? status;
  final IconData? icon;
  final bool dot, quiet;

  @override
  Widget build(BuildContext context) =>
      ui.StatusPill(label, status: status?.kit, icon: icon, dot: dot, quiet: quiet);
}

/// The kit's [ui.StatTile], taking a brahma_core [Status].
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    this.caption,
    this.suffix = '',
    this.fractionDigits = 0,
    this.status,
  });
  final String label;
  final IconData icon;
  final num? value;
  final String? caption;
  final String suffix;
  final int fractionDigits;
  final Status? status;

  @override
  Widget build(BuildContext context) => ui.StatTile(
    label: label,
    icon: icon,
    value: value,
    caption: caption,
    suffix: suffix,
    fractionDigits: fractionDigits,
    status: status?.kit,
  );
}

/// The kit's [ui.showToast], taking a brahma_core [Status].
ToastificationItem showToast(
  BuildContext context,
  String title, {
  String? description,
  Status status = Status.info,
  Duration stay = const Duration(seconds: 4),
}) => ui.showToast(context, title, description: description, status: status.kit, stay: stay);
