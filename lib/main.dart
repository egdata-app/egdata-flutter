import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:windows_single_instance/windows_single_instance.dart';
import 'pages/home_page.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure only one instance of the app runs on Windows
  if (Platform.isWindows) {
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      'egdata_client_single_instance',
      onSecondWindow: (args) async {
        // When a second instance is launched, bring this window to front
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  // Initialize window manager for desktop platforms
  if (Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1100, 750),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'EGData Client',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // Initialize launch at startup
    launchAtStartup.setup(
      appName: 'EGData Client',
      appPath: Platform.resolvedExecutable,
    );
  }

  runApp(const EGDataApp());
}

// Epic Games inspired color palette
class AppColors {
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF242424);
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderLight = Color(0xFF3A3A3A);
  static const Color primary = Color(0xFF0078F2);
  static const Color primaryLight = Color(0xFF40A9FF);
  static const Color accent = Color(0xFF00D4AA);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF666666);
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFFA940);
  static const Color error = Color(0xFFFF4D4F);
}

class EGDataApp extends StatelessWidget {
  const EGDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    const interTextStyle = TextStyle(fontFamily: 'Inter');
    final baseTextTheme = ThemeData.dark().textTheme.apply(
      fontFamily: 'Inter',
    );

    return MaterialApp(
      title: 'EGData Client',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          onSurface: AppColors.textPrimary,
          outline: AppColors.border,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: interTextStyle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        dividerColor: AppColors.border,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        textTheme: baseTextTheme.copyWith(
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          bodySmall: baseTextTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: AppColors.textMuted),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.borderLight),
          radius: const Radius.circular(2),
        ),
      ),
      home: const HomePage(),
    );
  }
}
