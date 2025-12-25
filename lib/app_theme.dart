import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SerenePalette {
  const SerenePalette({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.heroGradientColors,
    required this.backgroundGradientColors,
    required this.glassBackground,
    required this.glassBorder,
  });

  final String id;
  final String name;
  final String description;
  final String emoji;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final List<Color> heroGradientColors;
  final List<Color> backgroundGradientColors;
  final Color glassBackground;
  final Color glassBorder;

  LinearGradient get heroGradient => LinearGradient(
        colors: heroGradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get backgroundGradient => LinearGradient(
        colors: backgroundGradientColors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}

class SereneThemeColors extends ThemeExtension<SereneThemeColors> {
  const SereneThemeColors({
    required this.paletteId,
    required this.heroGradient,
    required this.backgroundGradient,
    required this.glassBackground,
    required this.glassBorder,
  });

  final String paletteId;
  final LinearGradient heroGradient;
  final LinearGradient backgroundGradient;
  final Color glassBackground;
  final Color glassBorder;

  @override
  ThemeExtension<SereneThemeColors> copyWith({
    String? paletteId,
    LinearGradient? heroGradient,
    LinearGradient? backgroundGradient,
    Color? glassBackground,
    Color? glassBorder,
  }) {
    return SereneThemeColors(
      paletteId: paletteId ?? this.paletteId,
      heroGradient: heroGradient ?? this.heroGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  ThemeExtension<SereneThemeColors> lerp(
    covariant ThemeExtension<SereneThemeColors>? other,
    double t,
  ) {
    if (other is! SereneThemeColors) return this;
    return SereneThemeColors(
      paletteId: t < 0.5 ? paletteId : other.paletteId,
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
      backgroundGradient:
          LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

const serenePalettes = [
  SerenePalette(
    id: 'aurora',
    name: 'Aurora Mist',
    description: 'Cool blues and violets for focused calm.',
    emoji: '🌌',
    primary: Color(0xFF8AB4FF),
    secondary: Color(0xFF6A7FDB),
    background: Color(0xFF05060A),
    surface: Color(0xFF0B0E15),
    heroGradientColors: [Color(0xFF6C63FF), Color(0xFF4AD4F4)],
    backgroundGradientColors: [Color(0xFF060910), Color(0xFF0B0E15)],
    glassBackground: Color(0x66121C2F),
    glassBorder: Color(0x22FFFFFF),
  ),
  SerenePalette(
    id: 'sundown',
    name: 'Sundown Glow',
    description: 'Sunset ambers for gentle evening sessions.',
    emoji: '🌅',
    primary: Color(0xFFFFAD66),
    secondary: Color(0xFFE45C5C),
    background: Color(0xFF0F0607),
    surface: Color(0xFF1B0F10),
    heroGradientColors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
    backgroundGradientColors: [Color(0xFF180709), Color(0xFF2C0F11)],
    glassBackground: Color(0x662B0F11),
    glassBorder: Color(0x33FFB199),
  ),
  SerenePalette(
    id: 'forest',
    name: 'Forest Bath',
    description: 'Earthy greens to feel grounded and fresh.',
    emoji: '🌿',
    primary: Color(0xFF7FD8A4),
    secondary: Color(0xFF2F8F75),
    background: Color(0xFF050C09),
    surface: Color(0xFF08140F),
    heroGradientColors: [Color(0xFF0BAB64), Color(0xFF3BB78F)],
    backgroundGradientColors: [Color(0xFF041008), Color(0xFF0B1F17)],
    glassBackground: Color(0x6610241B),
    glassBorder: Color(0x332CDBA2),
  ),
  SerenePalette(
    id: 'ember',
    name: 'Midnight Ember',
    description: 'Moody magentas with a warm, creative spark.',
    emoji: '🔥',
    primary: Color(0xFFFF8FB1),
    secondary: Color(0xFF7F5AF0),
    background: Color(0xFF080208),
    surface: Color(0xFF150613),
    heroGradientColors: [Color(0xFF6A11CB), Color(0xFFFF6FD8)],
    backgroundGradientColors: [Color(0xFF120213), Color(0xFF1E0824)],
    glassBackground: Color(0x66240328),
    glassBorder: Color(0x33FF6FD8),
  ),
  SerenePalette(
    id: 'lilac',
    name: 'Lunar Bloom',
    description: 'Iridescent purples for dreamy, spacious breaths.',
    emoji: '💜',
    primary: Color(0xFFB388FF),
    secondary: Color(0xFF8E5CFF),
    background: Color(0xFF05020C),
    surface: Color(0xFF120826),
    heroGradientColors: [Color(0xFF933FFE), Color(0xFFFF8DE7)],
    backgroundGradientColors: [Color(0xFF080214), Color(0xFF1B0C2D)],
    glassBackground: Color(0x66120524),
    glassBorder: Color(0x33933FFE),
  ),
];

SerenePalette paletteById(String id) {
  return serenePalettes.firstWhere(
    (palette) => palette.id == id,
    orElse: () => serenePalettes.first,
  );
}

ThemeData buildSereneTheme(SerenePalette palette) {
  final baseTextTheme = ThemeData(brightness: Brightness.dark).textTheme;
  final bodyTextTheme = GoogleFonts.manropeTextTheme(baseTextTheme);

  TextStyle? displayStyle(TextStyle? base,
      {FontWeight weight = FontWeight.w600}) {
    if (base == null) return null;
    return GoogleFonts.onest(textStyle: base).copyWith(
      fontWeight: weight,
      letterSpacing: -0.3,
    );
  }

  final textTheme = bodyTextTheme.copyWith(
    displayLarge: displayStyle(bodyTextTheme.displayLarge, weight: FontWeight.w500),
    displayMedium:
        displayStyle(bodyTextTheme.displayMedium, weight: FontWeight.w500),
    displaySmall:
        displayStyle(bodyTextTheme.displaySmall, weight: FontWeight.w600),
    headlineLarge:
        displayStyle(bodyTextTheme.headlineLarge, weight: FontWeight.w600),
    headlineMedium:
        displayStyle(bodyTextTheme.headlineMedium, weight: FontWeight.w600),
    headlineSmall:
        displayStyle(bodyTextTheme.headlineSmall, weight: FontWeight.w600),
  );
  final colorScheme = ColorScheme.dark(
    primary: palette.primary,
    onPrimary: Colors.black,
    secondary: palette.secondary,
    onSecondary: Colors.white,
    surface: palette.surface,
    onSurface: Colors.white,
    background: palette.background,
    onBackground: Colors.white,
    error: const Color(0xFFFF6B6B),
    onError: Colors.white,
  );

  return ThemeData(
    colorScheme: colorScheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: palette.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface.withOpacity(0.9),
      indicatorColor: palette.primary.withOpacity(0.2),
      iconTheme:
          WidgetStateProperty.all(const IconThemeData(color: Colors.white)),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    useMaterial3: true,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.black,
        textStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: palette.glassBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
    extensions: [
      SereneThemeColors(
        paletteId: palette.id,
        heroGradient: palette.heroGradient,
        backgroundGradient: palette.backgroundGradient,
        glassBackground: palette.glassBackground,
        glassBorder: palette.glassBorder,
      ),
    ],
  );
}

SereneThemeColors sereneTheme(BuildContext context) {
  return Theme.of(context).extension<SereneThemeColors>() ??
      const SereneThemeColors(
        paletteId: 'fallback',
        heroGradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
        backgroundGradient: LinearGradient(
          colors: [Color(0xFF060910), Color(0xFF0B0E15)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        glassBackground: Color(0x66121C2F),
        glassBorder: Color(0x22FFFFFF),
      );
}

BoxDecoration glassDecoration(BuildContext context, {BorderRadius? radius}) {
  final serene = sereneTheme(context);
  return BoxDecoration(
    borderRadius: radius ?? BorderRadius.circular(24),
    color: serene.glassBackground,
    border: Border.all(color: serene.glassBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
