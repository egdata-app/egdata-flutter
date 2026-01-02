import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:fluquery/fluquery.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_shell.dart';
import 'utils/platform_utils.dart';
import 'services/analytics_service.dart';

// Desktop-only imports (conditionally used)
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

// App version - keep in sync with pubspec.yaml
const String appVersion = '1.0.20';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (currently not used, but kept for future configuration)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: .env file not found (optional).');
  }

  // Initialize Firebase for mobile platforms (required for push notifications and analytics)
  // Firebase configuration files (google-services.json / GoogleService-Info.plist) are optional
  if (PlatformUtils.isMobile) {
    try {
      await Firebase.initializeApp();
      // Initialize Firebase Analytics
      await AnalyticsService().initialize();
      // Initialize Firebase In-App Messaging
      FirebaseInAppMessaging.instance.setMessagesSuppressed(false);
    } catch (e) {
      // Firebase not configured - push notifications and analytics will be disabled
      debugPrint('Firebase initialization failed: $e');
      debugPrint('Push notifications and analytics will be disabled. To enable them, add Firebase configuration files.');
    }
  }

  // Desktop-only initialization
  if (PlatformUtils.isDesktop) {
    await _initDesktop(args);
  }

  runApp(const EGDataApp());
}

/// Initialize desktop-specific features (window manager, single instance, etc.)
Future<void> _initDesktop(List<String> args) async {
  // Ensure only one instance of the app runs on Windows
  if (PlatformUtils.isWindows) {
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
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(900, 650),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'EGData Client',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Initialize launch at startup (Windows only for now)
  if (PlatformUtils.isWindows) {
    launchAtStartup.setup(
      appName: 'EGData Client',
      appPath: Platform.resolvedExecutable,
    );
  }
}

// Unreal Engine inspired color palette
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceLight = Color(0xFF1A1A1A);
  static const Color surfaceHover = Color(0xFF1E1E1E);

  // Glassmorphism
  static Color get surfaceGlass => Colors.white.withValues(alpha: 0.03);
  static Color get borderGlass => Colors.white.withValues(alpha: 0.08);

  // Borders
  static const Color border = Color(0xFF1F1F1F);
  static const Color borderLight = Color(0xFF2A2A2A);

  // Primary accent (Cyan)
  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryLight = Color(0xFF5CE1FF);
  static const Color primaryDark = Color(0xFF00A3CC);
  static const Color primaryMuted = Color(0xFF0891B2);

  // Secondary accents
  static const Color accent = Color(0xFF8B5CF6); // Purple
  static const Color accentPink = Color(0xFFEC4899); // Pink

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Border radius constants
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Glass decoration helper
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: surfaceGlass,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: borderGlass),
  );

  // Glass decoration with custom radius
  static BoxDecoration glassDecorationWithRadius(double radius) =>
      BoxDecoration(
        color: surfaceGlass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderGlass),
      );

  // Radial gradient background decoration (desktop)
  static BoxDecoration get radialGradientBackground => const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(-0.5, -0.8),
      radius: 1.5,
      colors: [
        Color(0xFF1A1A2E), // Subtle dark blue-purple tint
        Color(0xFF0F0F14), // Darker transition
        Color(0xFF0A0A0A), // Pure black (background)
      ],
      stops: [0.0, 0.4, 0.8],
    ),
  );

  // Secondary radial gradient for accent glow (desktop)
  static BoxDecoration get accentGlowBackground => BoxDecoration(
    gradient: RadialGradient(
      center: const Alignment(0.8, 0.6),
      radius: 1.2,
      colors: [primary.withValues(alpha: 0.03), Colors.transparent],
      stops: const [0.0, 0.6],
    ),
  );

  // Mobile-optimized radial gradient (adjusted for portrait orientation)
  static BoxDecoration get mobileRadialGradientBackground => const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(0.0, -0.3),
      radius: 1.8,
      colors: [
        Color(0xFF1A1A2E), // Subtle dark blue-purple tint
        Color(0xFF0F0F14), // Darker transition
        Color(0xFF0A0A0A), // Pure black (background)
      ],
      stops: [0.0, 0.35, 0.7],
    ),
  );

  // Mobile-optimized accent glow (positioned at top-right corner)
  static BoxDecoration get mobileAccentGlowBackground => BoxDecoration(
    gradient: RadialGradient(
      center: const Alignment(0.6, -0.4),
      radius: 1.0,
      colors: [primary.withValues(alpha: 0.04), Colors.transparent],
      stops: const [0.0, 0.5],
    ),
  );
}

class EGDataApp extends StatelessWidget {
  const EGDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    const interTextStyle = TextStyle(fontFamily: 'Inter');
    final baseTextTheme = ThemeData.dark().textTheme.apply(fontFamily: 'Inter');

    return QueryClientProvider(
      client: QueryClient(),
      child: MaterialApp(
        title: 'EGData Client',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        navigatorObservers: [
          if (AnalyticsService().observer != null)
            AnalyticsService().observer!,
        ],
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
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        dividerColor: AppColors.border,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        textTheme: baseTextTheme.copyWith(
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          bodySmall: baseTextTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.borderLight),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintStyle: const TextStyle(color: AppColors.textMuted),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.borderLight),
          radius: const Radius.circular(4),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.textMuted;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary.withValues(alpha: 0.3);
            }
            return AppColors.border;
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusLarge),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            border: Border.all(color: AppColors.border),
          ),
          textStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
      ),
        home: const AppShell(),
      ),
    );
  }
}
