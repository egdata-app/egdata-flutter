import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'main.dart';
import 'models/tray_popup_stats.dart';
import 'services/tray_popup_window_service.dart';
import 'services/windows_cursor_service.dart';
import 'services/windows_window_style_service.dart';

class TrayPopupWindowApp extends StatelessWidget {
  final Map<String, dynamic> initialPayload;

  const TrayPopupWindowApp({super.key, required this.initialPayload});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData.dark().textTheme.apply(fontFamily: 'Inter');

    return MaterialApp(
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
        textTheme: baseTextTheme,
      ),
      home: TrayPopupWindowPage(initialPayload: initialPayload),
    );
  }
}

class TrayPopupWindowPage extends StatefulWidget {
  final Map<String, dynamic> initialPayload;

  const TrayPopupWindowPage({super.key, required this.initialPayload});

  @override
  State<TrayPopupWindowPage> createState() => _TrayPopupWindowPageState();
}

class _TrayPopupWindowPageState extends State<TrayPopupWindowPage>
    with WidgetsBindingObserver {
  late TrayPopupStats _stats;
  Timer? _outsideClickMonitor;
  bool _closeRequested = false;
  bool _readyForOutsideClickClose = false;
  DateTime _openedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _stats = TrayPopupStats.fromJson(
      widget.initialPayload['stats'] as Map<String, dynamic>? ?? const {},
    );

    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'tray_popup_update_stats') {
        final raw = call.arguments as Map<dynamic, dynamic>?;
        if (raw != null && mounted) {
          setState(() {
            _stats = TrayPopupStats.fromJson(raw.cast<String, dynamic>());
          });
        }
      } else if (call.method == 'tray_popup_on_show') {
        _closeRequested = false;
        _readyForOutsideClickClose = false;
        _openedAt = DateTime.now();
        _startOutsideClickMonitor();
      }
      return null;
    });

    WidgetsBinding.instance.addObserver(this);
    _notifyVisibility(true);
    _readyForOutsideClickClose = false;
    _openedAt = DateTime.now();
    _startOutsideClickMonitor();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyBorderlessWindowStyleWithRetry();
    });
  }

  Future<void> _applyBorderlessWindowStyleWithRetry() async {
    if (WindowsWindowStyleService.makeActiveWindowBorderless()) {
      return;
    }

    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 90));

      final activeApplied =
          WindowsWindowStyleService.makeActiveWindowBorderless();
      if (activeApplied) {
        return;
      }

      WindowsWindowStyleService.makeBorderlessToolWindow(
        TrayPopupWindowService.popupWindowTitle,
      );
    }
  }

  @override
  void dispose() {
    _outsideClickMonitor?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _notifyVisibility(false);
    super.dispose();
  }

  void _startOutsideClickMonitor() {
    if (!Platform.isWindows) {
      return;
    }

    _outsideClickMonitor?.cancel();
    _outsideClickMonitor = Timer.periodic(const Duration(milliseconds: 75), (
      _,
    ) {
      if (!mounted || _closeRequested) {
        return;
      }

      final elapsedMs = DateTime.now().difference(_openedAt).inMilliseconds;
      if (elapsedMs < 250) {
        return;
      }

      final mouseDown = WindowsCursorService.isMouseButtonDown();

      // Wait until the opening click is fully released before we start
      // outside-click dismissal checks.
      if (!mouseDown) {
        _readyForOutsideClickClose = true;
        return;
      }

      if (!_readyForOutsideClickClose) {
        return;
      }

      final insideWindow = WindowsCursorService.isCursorInsideWindow(
        TrayPopupWindowService.popupWindowTitle,
      );
      if (!insideWindow) {
        _requestClose();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _requestClose();
    }
  }

  Future<void> _notifyVisibility(bool visible) async {
    await DesktopMultiWindow.invokeMethod(0, 'tray_popup_visibility', {
      'visible': visible,
    });
  }

  Future<void> _requestOpenMain() async {
    await DesktopMultiWindow.invokeMethod(0, 'tray_popup_request_open_main');
  }

  Future<void> _requestQuit() async {
    await DesktopMultiWindow.invokeMethod(0, 'tray_popup_request_quit');
  }

  Future<void> _requestClose() async {
    if (_closeRequested) {
      return;
    }
    _closeRequested = true;
    await DesktopMultiWindow.invokeMethod(0, 'tray_popup_request_close');
  }

  @override
  Widget build(BuildContext context) {
    final hasCurrentGame =
        _stats.currentGame != null &&
        _stats.currentGame!.trim().isNotEmpty &&
        _stats.currentSessionTime != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                if (hasCurrentGame) _buildNowPlaying(),
                _buildStatsGrid(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.games_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'EGData Quick View',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _stats.currentGame ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _stats.currentSessionTime ?? '',
            style: const TextStyle(
              color: AppColors.primary,
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              label: 'This Week',
              value: _stats.weeklyPlaytime,
              icon: Icons.timer_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              label: 'Installed',
              value: '${_stats.gamesInstalled}',
              icon: Icons.library_add_check_rounded,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              label: 'Most Played',
              value: _stats.mostPlayedGame?.isNotEmpty == true
                  ? _stats.mostPlayedGame!
                  : '-',
              icon: Icons.star_rounded,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _requestOpenMain,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Open'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: _requestQuit,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.borderLight),
                padding: const EdgeInsets.symmetric(vertical: 11),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('Quit'),
            ),
          ),
        ],
      ),
    );
  }
}
