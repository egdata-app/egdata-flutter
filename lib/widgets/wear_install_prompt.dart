import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/wear_service.dart';

/// A widget that shows a bottom sheet prompting users to install the EGData app
/// on their Wear OS watch. Similar to Google's Fast Pair UI for Bluetooth devices.
/// Only shows when a watch is connected but doesn't have the app installed.
class WearInstallPrompt extends StatefulWidget {
  const WearInstallPrompt({super.key});

  @override
  State<WearInstallPrompt> createState() => _WearInstallPromptState();
}

class _WearInstallPromptState extends State<WearInstallPrompt> {
  static const _dismissedDevicesKey = 'wear_install_dismissed_devices';

  final _wearService = WearService();
  bool _hasChecked = false;
  bool _sheetShown = false;

  @override
  void initState() {
    super.initState();
    // Delay the check slightly to let the app settle
    Future.delayed(const Duration(milliseconds: 500), _checkWearDevices);
  }

  Future<Set<String>> _getDismissedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_dismissedDevicesKey) ?? [];
    return list.toSet();
  }

  Future<void> _addDismissedDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_dismissedDevicesKey) ?? [];
    if (!list.contains(deviceId)) {
      list.add(deviceId);
      await prefs.setStringList(_dismissedDevicesKey, list);
    }
  }

  Future<void> _checkWearDevices() async {
    if (!_wearService.isAvailable || _hasChecked || _sheetShown) return;

    _hasChecked = true;

    final devices = await _wearService.getDevicesNeedingApp();
    if (devices.isEmpty || !mounted) return;

    // Filter out devices that were previously dismissed
    final dismissedIds = await _getDismissedDevices();
    final eligibleDevices = devices
        .where((device) => !dismissedIds.contains(device.id))
        .toList();

    if (eligibleDevices.isNotEmpty && mounted) {
      _sheetShown = true;
      _showInstallSheet(eligibleDevices.first);
    }
  }

  void _showInstallSheet(WearDevice device) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _WearInstallSheet(
        device: device,
        wearService: _wearService,
        onDismiss: () => _addDismissedDevice(device.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't render anything - it just triggers the bottom sheet
    return const SizedBox.shrink();
  }
}

class _WearInstallSheet extends StatefulWidget {
  final WearDevice device;
  final WearService wearService;
  final VoidCallback onDismiss;

  const _WearInstallSheet({
    required this.device,
    required this.wearService,
    required this.onDismiss,
  });

  @override
  State<_WearInstallSheet> createState() => _WearInstallSheetState();
}

class _WearInstallSheetState extends State<_WearInstallSheet> {
  bool _isInstalling = false;

  Future<void> _installOnWatch() async {
    developer.log('Install button tapped for device: ${widget.device}', name: 'WearInstallPrompt');

    // Capture ScaffoldMessenger before any async work or navigation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final deviceName = widget.device.displayName;
    final deviceId = widget.device.id;

    setState(() => _isInstalling = true);

    developer.log('Calling openPlayStoreOnWatch with id: $deviceId', name: 'WearInstallPrompt');
    final success = await widget.wearService.openPlayStoreOnWatch(deviceId);
    developer.log('openPlayStoreOnWatch returned: $success', name: 'WearInstallPrompt');

    if (mounted) {
      setState(() => _isInstalling = false);

      if (success) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Opening Play Store on $deviceName...'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to open Play Store on watch. This may not work on emulators.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              children: [
                // Watch icon with animated ring
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        IconsaxPlusBold.watch,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Device name
                Text(
                  widget.device.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  'Get free game alerts on your watch',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Install button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isInstalling ? null : _installOnWatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isInstalling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Install',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Not now button
                TextButton(
                  onPressed: () {
                    widget.onDismiss();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                  child: const Text(
                    'Not now',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
