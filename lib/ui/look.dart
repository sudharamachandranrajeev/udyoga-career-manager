import 'package:brahma_core/brahma_core.dart' hide Release, UpdateException, checksumsName, updaterProvider;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart'
    show
        ShadColorScheme,
        ShadMouseAreaSurface,
        ShadMouseCursorProvider,
        ShadTextTheme,
        ShadTheme,
        ShadThemeData;
import 'package:ui_kit/ui_kit.dart';

// The motion tokens, canvas and kit widgets live in the shared ui_kit
// package (pariksha-interview-kit); Udyoga installs its azure palette as a
// KitPalette and re-exports them here, so the pages import one file.
export 'package:ui_kit/ui_kit.dart'
    show
        Backdrop,
        Ease,
        Headline,
        KitPalette,
        Pace,
        Radii,
        RisePageTransitionsBuilder,
        Tilt,
        TiltGrid,
        TypeScale,
        figures,
        glassBlur,
        paced,
        reducedMotion;

// Udyoga's look: a calm, airy canvas (soft azure light, deep navy at night)
// so the content stands forward; cards set apart by hairline borders rather
// than heavy shadows; an ink pill navigation bar with an azure indicator;
// short, strong ease-out motion that stops when the system asks for reduced
// motion.

// One step darker than #2F6BFF, which gave white labels 4.499:1, just under
// WCAG AA; this is 4.56:1 and looks the same.
const azure = Color(0xFF2E6AFE);
const ink = Color(0xFF0B1020);
const mint = Color(0xFF12B886);

/// Headings: Plus Jakarta Sans. Reading text: Inter, made for screens.
const headingFont = 'PlusJakartaSans';
const bodyFont = 'Inter';

/// Every colour of one brightness, in one place. Installed on the theme as
/// the kit's palette, so the shared widgets paint in azure.
typedef Palette = KitPalette;

const _light = KitPalette(
  top: Color(0xFFE3EBFD),
  bottom: Color(0xFFF8FAFD),
  glow: Color(0x592F6BFF),
  glow2: Color(0x2E12B886),
  surface: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  subtle: Color(0xFFF2F5FA),
  raised: Color(0xFFEDF1F8),
  hairline: Color(0xFFE2E8F2),
  text: ink,
  heading: ink,
  muted: Color(0xFF586379),
  primary: azure,
);

const _dark = KitPalette(
  top: Color(0xFF0A1022),
  bottom: Color(0xFF05070F),
  glow: Color(0x4D2F6BFF),
  glow2: Color(0x2B12B886),
  surface: Color(0xFF0E1426),
  card: Color(0xFF111A2E),
  subtle: Color(0xFF151F37),
  raised: Color(0xFF1A2440),
  hairline: Color(0x17FFFFFF),
  text: Color(0xFFE8ECF6),
  heading: Color(0xFFFFFFFF),
  muted: Color(0xFF98A2B8),
  primary: Color(0xFF6E9BFF),
);

Palette palette(Brightness b) => b == Brightness.dark ? _dark : _light;

/// The canvas colours behind every page.
({Color top, Color bottom, Color glow, Color glow2}) canvas(Brightness b) {
  final p = palette(b);
  return (top: p.top, bottom: p.bottom, glow: p.glow, glow2: p.glow2);
}

ThemeData udyogaTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final p = palette(b);
  final base = buildTheme(b, seed: azure, accent: mint);
  final scheme = base.colorScheme.copyWith(
    primary: p.primary,
    // White on the light dark-mode blue is 2.7:1, too faint for button
    // labels; ink is 7:1. White on light-mode azure is 4.56:1.
    onPrimary: dark ? ink : Colors.white,
    surface: p.surface,
    surfaceContainerLow: p.card,
    surfaceContainerHighest: p.raised,
    outlineVariant: p.hairline,
    onSurfaceVariant: p.muted,
  );
  final c = canvas(b);
  final line = BorderSide(color: p.hairline);
  final text = base.textTheme.apply(fontFamily: bodyFont, bodyColor: p.text, displayColor: p.heading);
  TextStyle? heading(TextStyle? s, FontWeight w, double size, [double spacing = -0.4]) =>
      s?.copyWith(fontFamily: headingFont, fontWeight: w, fontSize: size, letterSpacing: spacing);
  final type = text.copyWith(
    displayLarge: heading(text.displayLarge, FontWeight.w800, 57, -1.2),
    displayMedium: heading(text.displayMedium, FontWeight.w800, 45, -1),
    displaySmall: heading(text.displaySmall, FontWeight.w700, TypeScale.display, -0.8),
    headlineLarge: heading(text.headlineLarge, FontWeight.w700, TypeScale.display, -0.7),
    headlineMedium: heading(text.headlineMedium, FontWeight.w700, TypeScale.xxl, -0.6),
    headlineSmall: heading(text.headlineSmall, FontWeight.w700, TypeScale.xl),
    titleLarge: heading(text.titleLarge, FontWeight.w700, TypeScale.lg, -0.3),
    titleMedium: text.titleMedium?.copyWith(
      fontSize: TypeScale.base,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    titleSmall: text.titleSmall?.copyWith(fontSize: TypeScale.sm, fontWeight: FontWeight.w600),
    bodyLarge: text.bodyLarge?.copyWith(fontSize: TypeScale.base, height: 1.5, letterSpacing: 0),
    bodyMedium: text.bodyMedium?.copyWith(fontSize: TypeScale.sm, height: 1.45, letterSpacing: 0),
    bodySmall: text.bodySmall?.copyWith(fontSize: TypeScale.xs, color: p.muted),
    labelLarge: text.labelLarge?.copyWith(
      fontSize: TypeScale.sm,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
  );
  const stadium = StadiumBorder();
  final small = BorderRadius.circular(Radii.sm);
  final large = BorderRadius.circular(Radii.lg);
  return base.copyWith(
    colorScheme: scheme,
    textTheme: type,
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: bodyFont),
    // The canvas (see Backdrop) shows through every page.
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: scheme.surface,
    dividerTheme: DividerThemeData(color: p.hairline, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: c.top.withValues(alpha: dark ? 0.92 : 0.86),
      foregroundColor: type.titleLarge?.color,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: type.headlineSmall?.copyWith(fontSize: 22),
    ),
    // Depth from a hairline, not a shadow; in the dark a lighter surface.
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: large, side: line),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: stadium,
      side: line,
      backgroundColor: dark ? p.subtle : Colors.white,
      selectedColor: dark ? Colors.white : ink,
      secondarySelectedColor: dark ? Colors.white : ink,
      checkmarkColor: dark ? ink : Colors.white,
      labelStyle: type.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? (dark ? ink : Colors.white)
              : type.labelLarge?.color ?? scheme.onSurface,
        ),
      ),
      secondaryLabelStyle: type.labelLarge?.copyWith(color: dark ? ink : Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(stadium),
        side: WidgetStatePropertyAll(line),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? (dark ? Colors.white : ink) : scheme.surfaceContainerLow,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? (dark ? ink : Colors.white) : type.bodyLarge?.color,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: stadium,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: type.labelLarge?.copyWith(fontSize: 15),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: stadium,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        side: line,
        backgroundColor: scheme.surfaceContainerLow,
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: stadium)),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: azure,
      foregroundColor: Colors.white,
      shape: stadium,
      elevation: 2,
      highlightElevation: 4,
      extendedTextStyle: type.labelLarge?.copyWith(fontSize: 15, color: Colors.white),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: dark ? p.subtle : Colors.white,
      border: OutlineInputBorder(borderRadius: small, borderSide: line),
      enabledBorder: OutlineInputBorder(borderRadius: small, borderSide: line),
      focusedBorder: OutlineInputBorder(
        borderRadius: small,
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      // Lifted off the night canvas so it still reads as floating.
      backgroundColor: dark ? const Color(0xFF222C4D) : ink,
      surfaceTintColor: Colors.transparent,
      indicatorColor: azure,
      indicatorShape: stadium,
      elevation: 0,
      height: 64,
      // Icons only, like the reference designs; the tooltip names each.
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Colors.white : Colors.white70),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        type.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: azure,
      indicatorShape: stadium,
      selectedIconTheme: const IconThemeData(color: Colors.white),
      selectedLabelTextStyle: type.labelLarge?.copyWith(color: scheme.primary),
      unselectedLabelTextStyle: type.labelLarge?.copyWith(color: p.muted),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: large, side: line),
      titleTextStyle: type.headlineSmall,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: small, side: line),
    ),
    snackBarTheme: base.snackBarTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: small),
      backgroundColor: dark ? const Color(0xFF1C2643) : ink,
      // The background is dark in both modes, so the text must be light in
      // both. Material's default (onInverseSurface) is dark in dark mode,
      // which made toasts unreadable.
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(color: const Color(0xFFF4F6FB)),
      actionTextColor: const Color(0xFF9DB8FF),
      closeIconColor: const Color(0xFFF4F6FB),
    ),
    sliderTheme: base.sliderTheme.copyWith(trackHeight: 6),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    extensions: [p],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: RisePageTransitionsBuilder(),
        TargetPlatform.linux: RisePageTransitionsBuilder(),
        TargetPlatform.windows: RisePageTransitionsBuilder(),
        TargetPlatform.macOS: RisePageTransitionsBuilder(),
        TargetPlatform.iOS: RisePageTransitionsBuilder(),
        TargetPlatform.fuchsia: RisePageTransitionsBuilder(),
      },
    ),
  );
}

/// The same palette for the shadcn_ui widgets (buttons, inputs, badges and
/// cards in the kit), so they sit beside the Material ones without a seam.
ShadThemeData shadTheme(Brightness b) {
  final p = palette(b);
  return ShadThemeData(
    brightness: b,
    radius: BorderRadius.circular(Radii.sm),
    textTheme: ShadTextTheme(family: bodyFont),
    colorScheme: ShadColorScheme(
      background: p.surface,
      foreground: p.text,
      card: p.card,
      cardForeground: p.text,
      popover: p.surface,
      popoverForeground: p.text,
      primary: p.primary,
      primaryForeground: Colors.white,
      secondary: p.subtle,
      secondaryForeground: p.text,
      muted: p.subtle,
      mutedForeground: p.muted,
      accent: p.raised,
      accentForeground: p.text,
      destructive: const Color(0xFFE5484D),
      destructiveForeground: Colors.white,
      border: p.hairline,
      input: p.hairline,
      ring: p.primary,
      selection: p.primary.withValues(alpha: 0.3),
    ),
  );
}

/// Puts the shadcn_ui theme (following the Material theme's brightness, so
/// light and dark switch together) and the pointer services its widgets
/// need inside a MaterialApp, from the app's `builder`.
class ShadBridge extends StatelessWidget {
  const ShadBridge({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ShadTheme(
    data: shadTheme(Theme.of(context).brightness),
    child: ShadMouseAreaSurface(child: ShadMouseCursorProvider(child: child)),
  );
}

/// An employer's mark: its initials on a gradient picked from its name, so
/// the same employer always looks the same (no logos are fetched).
class OrgLogo extends StatelessWidget {
  const OrgLogo(this.name, {super.key, this.size = 44});
  final String name;
  final double size;

  /// FNV-1a: well spread, so similar names still get different colours.
  static int _hash(String s) => s.codeUnits.fold(0x811C9DC5, (h, c) => ((h ^ c) * 0x01000193) & 0xFFFFFFFF);

  static const _palettes = [
    [Color(0xFF2F6BFF), Color(0xFF7A5CFF)],
    [Color(0xFF12B886), Color(0xFF0CA5E9)],
    [Color(0xFFFF7A45), Color(0xFFFF4D7E)],
    [Color(0xFF7A5CFF), Color(0xFFE056FD)],
    [Color(0xFF0EA5E9), Color(0xFF2F6BFF)],
    [Color(0xFFF59F00), Color(0xFFFF6B3D)],
    [Color(0xFF20C997), Color(0xFF2F9E44)],
    [Color(0xFF364FC7), Color(0xFF15AABF)],
  ];

  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && w[0].contains(RegExp('[A-Za-z0-9]')));
    final letters = words.take(2).map((w) => w[0].toUpperCase()).join();
    final colors = _palettes[(_hash(name.toLowerCase()) >> 8) % _palettes.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        boxShadow: [
          BoxShadow(color: colors.first.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      child: Text(
        letters.isEmpty ? '•' : letters,
        style: TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w800,
          fontSize: size * (letters.length > 1 ? 0.36 : 0.44),
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
