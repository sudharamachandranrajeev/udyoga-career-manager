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

// Udyoga's look: a calm, airy canvas (soft azure light, deep navy at night)
// so the content stands forward; cards set apart by hairline borders rather
// than heavy shadows; an ink pill navigation bar with an azure indicator;
// short, strong ease-out motion that stops when the system asks for reduced
// motion.

const azure = Color(0xFF2F6BFF);
const ink = Color(0xFF0B1020);
const mint = Color(0xFF12B886);

/// Headings: Plus Jakarta Sans. Reading text: Inter, made for screens.
const headingFont = 'PlusJakartaSans';
const bodyFont = 'Inter';

/// Corner radii: [sm] for inputs, buttons and small cards, [lg] for cards,
/// dialogs and sheets. Pills are fully round.
abstract final class Radii {
  static const sm = 12.0;
  static const lg = 16.0;
  static const pill = 999.0;
}

/// How strongly frosted glass (the floating bars, sheets) blurs what is
/// behind it.
const glassBlur = 16.0;

/// The type scale, in logical pixels: 12, 14, 16, 20, 24, 30, 36.
abstract final class TypeScale {
  static const xs = 12.0;
  static const sm = 14.0;
  static const base = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 30.0;
  static const display = 36.0;
}

/// Figures that line up in columns and do not jiggle as they change: for
/// counts, money and dates. Merge it into any style that shows numbers.
const figures = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

/// Motion curves, after Emil Kowalski's: [out] for things entering or
/// leaving, [inOut] for things moving on screen, [drawer] for sheets.
/// Nothing uses ease-in: it feels slow to start.
abstract final class Ease {
  static const out = Cubic(0.23, 1, 0.32, 1);
  static const inOut = Cubic(0.77, 0, 0.175, 1);
  static const drawer = Cubic(0.32, 0.72, 0, 1);
}

/// Motion lengths. Interface motion stays between 150 and 250 ms.
abstract final class Pace {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 250);
}

/// [d], or no time at all when the system asks for reduced motion.
Duration paced(BuildContext context, Duration d) => Motion.reduced(context) ? Duration.zero : d;

/// Every colour of one brightness, in one place.
typedef Palette = ({
  // The canvas behind every page: a vertical wash and two faint glows.
  Color top,
  Color bottom,
  Color glow,
  Color glow2,
  // Surfaces, from the page to quiet fills inside it.
  Color surface,
  Color card,
  Color subtle,
  Color raised,
  // Lines and text.
  Color hairline,
  Color text,
  Color heading,
  Color muted,
  Color primary,
});

const _light = (
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

const _dark = (
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
    // labels; ink is 7:1.
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

/// The canvas: a soft vertical wash with two faint glows, behind every page.
class Backdrop extends StatelessWidget {
  const Backdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = canvas(Theme.of(context).brightness);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.top, c.bottom],
          stops: const [0, 0.55],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -160, right: -120, child: _Glow(c.glow, 420)),
          Positioned(bottom: -200, left: -160, child: _Glow(c.glow2, 460)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow(this.color, this.size);
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}

/// Pushed pages rise a little into place and fade in, while the page
/// underneath dims slightly. A page opens tens of times a day, so it is short
/// (250 ms) and leaves at once: the way back starts fast. No 3D turn: it
/// added nothing but time.
class RisePageTransitionsBuilder extends PageTransitionsBuilder {
  const RisePageTransitionsBuilder();

  @override
  Duration get transitionDuration => Pace.slow;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Each page brings its own canvas, so the page beneath never shows through.
    child = Backdrop(child: child);
    // Under reduced motion a fade remains: it moves nothing.
    if (Motion.reduced(context)) return FadeTransition(opacity: animation, child: child);
    final inCurve = CurvedAnimation(parent: animation, curve: Ease.out, reverseCurve: Ease.out.flipped);
    final outCurve = CurvedAnimation(parent: secondaryAnimation, curve: Ease.out);
    return AnimatedBuilder(
      animation: Listenable.merge([inCurve, outCurve]),
      child: child,
      builder: (context, child) => Opacity(
        opacity: (inCurve.value.clamp(0, 1) * (1 - outCurve.value * 0.2)).toDouble(),
        child: Transform.translate(offset: Offset(0, (1 - inCurve.value) * 24), child: child),
      ),
    );
  }
}

/// Press feedback for a card that opens something: it sinks a touch while
/// held, so the app is seen to have heard. It used to tilt towards the
/// pointer in 3D as well; that ran on every hover over every list, tens of
/// times a day, and said nothing, so it is gone. Hover is left to the
/// card's own highlight (SpotlightCard). Still under reduced motion.
class Tilt extends StatefulWidget {
  const Tilt({super.key, required this.child});
  final Widget child;

  @override
  State<Tilt> createState() => _TiltState();
}

class _TiltState extends State<Tilt> {
  var _down = false;

  void _press(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: Pace.fast,
        curve: Ease.out,
        child: widget.child,
      ),
    );
  }
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

/// A big greeting with one phrase picked out in the brand colour.
class Headline extends StatelessWidget {
  const Headline(this.parts, {super.key});

  /// Alternating plain and highlighted runs, starting plain.
  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final base = t.headlineMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.2);
    return Text.rich(
      TextSpan(
        children: [
          for (final (i, p) in parts.indexed)
            TextSpan(
              text: p,
              style: i.isOdd
                  ? base?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)
                  : base,
            ),
        ],
      ),
    );
  }
}

/// A [TileGrid] whose tiles sink a touch when pressed (see [Tilt]).
class TiltGrid extends StatelessWidget {
  const TiltGrid({super.key, required this.children, this.minWidth = 200});
  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) => TileGrid(
    minWidth: minWidth,
    children: [for (final c in children) Tilt(child: c)],
  );
}
