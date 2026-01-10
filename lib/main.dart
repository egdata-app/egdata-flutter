import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fluquery/fluquery.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'app_shell.dart';
import 'utils/platform_utils.dart';
import 'services/analytics_service.dart';
import 'services/widget_service.dart';
import 'services/follow_service.dart';
import 'services/push_service.dart';
import 'services/notification_service.dart';
import 'database/database_service.dart';
import 'pages/mobile_offer_detail_page.dart';

// Desktop-only imports (conditionally used)
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

// App version - keep in sync with pubspec.yaml
const String appVersion = '1.0.20';

// Global key for navigation from the MethodChannel
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (currently not used, but kept for future configuration)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: .env file not found (optional).');
  }

  // Initialize Database
  final dbService = await DatabaseService.getInstance();

  // Initialize Notification Service
  final notificationService = NotificationService();
  try {
    await notificationService.init();
  } catch (e) {
    debugPrint('Notification service initialization failed: $e');
    // Non-fatal - continue app initialization
  }

  // Initialize Firebase for mobile platforms
  if (PlatformUtils.isMobile) {
    try {
      await Firebase.initializeApp();

      // Initialize Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      await AnalyticsService().initialize();
      FirebaseInAppMessaging.instance.setMessagesSuppressed(false);
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }

    // Update widget with latest free games data (non-blocking)
    if (Platform.isAndroid || Platform.isIOS) {
      // Fire and forget - don't block app startup
      WidgetService().updateWidget().catchError((e) {
        debugPrint('Widget update failed: $e');
      });
    }
  }

  // Desktop-only initialization
  if (PlatformUtils.isDesktop) {
    await _initDesktop(args);
  }

  runApp(EGDataApp(
    dbService: dbService,
    notificationService: notificationService,
  ));
}

/// Initialize desktop-specific features
Future<void> _initDesktop(List<String> args) async {
  if (PlatformUtils.isWindows) {
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      'egdata_client_single_instance',
      onSecondWindow: (args) async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

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

  if (PlatformUtils.isWindows) {
    launchAtStartup.setup(
      appName: 'EGData Client',
      appPath: Platform.resolvedExecutable,
    );
  }
}

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
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);

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

  // Background decorations
  static BoxDecoration get radialGradientBackground => const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(-0.5, -0.8),
      radius: 1.5,
      colors: [
        Color(0xFF1A1A2E),
        Color(0xFF0F0F14),
        Color(0xFF0A0A0A),
      ],
      stops: [0.0, 0.4, 0.8],
    ),
  );

  static BoxDecoration get accentGlowBackground => BoxDecoration(
    gradient: RadialGradient(
      center: const Alignment(0.8, 0.6),
      radius: 1.2,
      colors: [primary.withValues(alpha: 0.03), Colors.transparent],
      stops: const [0.0, 0.6],
    ),
  );

  static BoxDecoration get mobileRadialGradientBackground => const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(0.0, -0.3),
      radius: 1.8,
      colors: [
        Color(0xFF1A1A2E),
        Color(0xFF0F0F14),
        Color(0xFF0A0A0A),
      ],
      stops: [0.0, 0.35, 0.7],
    ),
  );

  static BoxDecoration get mobileAccentGlowBackground => BoxDecoration(
    gradient: RadialGradient(
      center: const Alignment(0.6, -0.4),
      radius: 1.0,
      colors: [primary.withValues(alpha: 0.04), Colors.transparent],
      stops: const [0.0, 0.5],
    ),
  );
}

class EGDataApp extends StatefulWidget {
  final DatabaseService dbService;
  final NotificationService notificationService;

  const EGDataApp({
    super.key,
    required this.dbService,
    required this.notificationService,
  });

  @override
  State<EGDataApp> createState() => _EGDataAppState();
}

class _EGDataAppState extends State<EGDataApp> {
  late final QueryClient _queryClient;
  static const platform = MethodChannel('com.ignacioaldama.egdata/widget');

  // Services for detail page navigation
  late final FollowService _followService;
  late final PushService _pushService;

  @override
  void initState() {
    super.initState();
    _queryClient = QueryClient();

    // Initialize services with the shared instances
    _followService = FollowService(db: widget.dbService);
    _pushService = PushService(
      db: widget.dbService,
      notification: widget.notificationService,
    );

    _initWidgetChannel();
  }

  void _initWidgetChannel() {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    platform.setMethodCallHandler((call) async {
      if (call.method == "onOfferSelected") {
        final String? offerId = call.arguments as String?;
        if (offerId != null) {
          _navigateToOffer(offerId);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialWidgetClick();
    });
  }

  Future<void> _checkInitialWidgetClick() async {
    try {
      final String? offerId = await platform.invokeMethod('getPendingOfferId');
      if (offerId != null) {
        _navigateToOffer(offerId);
      }
    } catch (e) {
      debugPrint("Error checking initial widget click: $e");
    }
  }

  void _navigateToOffer(String offerId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => MobileOfferDetailPage(
          offerId: offerId,
          followService: _followService,
          pushService: _pushService,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _queryClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final baseTextTheme = ThemeData.dark().textTheme.apply(fontFamily: 'Inter');

    return QueryClientProvider(
      client: _queryClient,
      child: MaterialApp(
        navigatorKey: navigatorKey,
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
          textTheme: baseTextTheme,
        ),
        home: AppShell(queryClient: _queryClient),
      ),
    );
  }
}
