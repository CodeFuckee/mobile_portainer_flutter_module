import 'package:flutter/material.dart';
import 'theme_extensions.dart';

class AppTheme {
  AppTheme._();

  static const double fabBottomInset = 88;

  // HarmonyOS-inspired light color scheme
  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0A84FF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD9EAFF),
    onPrimaryContainer: Color(0xFF001C3D),
    secondary: Color(0xFF5A6A80),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDEE8F5),
    onSecondaryContainer: Color(0xFF152537),
    tertiary: Color(0xFF705E80),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF4DEFF),
    onTertiaryContainer: Color(0xFF271A37),
    error: Color(0xFFC8102E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD8),
    onErrorContainer: Color(0xFF410006),
    surface: Color(0xFFF7F8FA),
    onSurface: Color(0xFF1A1C1E),
    surfaceContainerHighest: Color(0xFFE1E3E8),
    surfaceContainerHigh: Color(0xFFE7E9EE),
    surfaceContainer: Color(0xFFEDEFF4),
    surfaceContainerLow: Color(0xFFF3F5FA),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFF444850),
    outline: Color(0xFF747880),
    outlineVariant: Color(0xFFC4C7D0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2F3034),
    onInverseSurface: Color(0xFFF1F1F5),
    inversePrimary: Color(0xFFA2CCFF),
  );

  // HarmonyOS-inspired dark color scheme
  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4DA3FF),
    onPrimary: Color(0xFF002952),
    primaryContainer: Color(0xFF004080),
    onPrimaryContainer: Color(0xFFD6E9FF),
    secondary: Color(0xFFB2C2D8),
    onSecondary: Color(0xFF1D2C3E),
    secondaryContainer: Color(0xFF334356),
    onSecondaryContainer: Color(0xFFDEE8F5),
    tertiary: Color(0xFFD8C0E6),
    onTertiary: Color(0xFF3B2A4A),
    tertiaryContainer: Color(0xFF524061),
    onTertiaryContainer: Color(0xFFF4DEFF),
    error: Color(0xFFFFB3AD),
    onError: Color(0xFF680010),
    errorContainer: Color(0xFF920017),
    onErrorContainer: Color(0xFFFFDAD8),
    surface: Color(0xFF0F1218),
    onSurface: Color(0xFFE2E5EC),
    surfaceContainerHighest: Color(0xFF282C35),
    surfaceContainerHigh: Color(0xFF23272F),
    surfaceContainer: Color(0xFF1E2129),
    surfaceContainerLow: Color(0xFF191C23),
    surfaceContainerLowest: Color(0xFF0A0D13),
    onSurfaceVariant: Color(0xFFC4C7D1),
    outline: Color(0xFF8E929B),
    outlineVariant: Color(0xFF444850),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE2E5EC),
    onInverseSurface: Color(0xFF2F3034),
    inversePrimary: Color(0xFF0A84FF),
  );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required DockerColors dockerColors,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final textTheme = isDark
        ? Typography.material2021().white
        : Typography.material2021().englishLike;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      scaffoldBackgroundColor: colorScheme.surfaceContainer,

      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        labelMedium: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelSmall: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 1,
        color: isDark ? colorScheme.surfaceContainerLow : null,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark
              ? BorderSide(color: colorScheme.outlineVariant, width: 0.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
      ),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        prefixIconColor: colorScheme.onSurfaceVariant,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(179)),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 80,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        selectedIconTheme: IconThemeData(
          color: colorScheme.onPrimaryContainer,
          size: 22,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
          size: 22,
        ),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
          fontSize: 12,
        ),
        groupAlignment: -0.3,
        minWidth: 80,
      ),

      tabBarTheme: TabBarThemeData(
        tabAlignment: TabAlignment.start,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
      ),

      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 0.5,
        color: colorScheme.outlineVariant,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
      ),

      listTileTheme: ListTileThemeData(
        textColor: colorScheme.onSurface,
        iconColor: colorScheme.onSurfaceVariant,
      ),

      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide.none,
      ),

      extensions: [dockerColors],
    );
  }

  static ThemeData light() => _buildTheme(
        colorScheme: _lightColorScheme,
        dockerColors: DockerColors.light,
      );

  static ThemeData dark() => _buildTheme(
        colorScheme: _darkColorScheme,
        dockerColors: DockerColors.dark,
      );
}
