import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/settings.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../services/push_service.dart';
import '../utils/country_utils.dart';
import '../utils/platform_utils.dart';

class SettingsPage extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final Future<void> Function()? onClearProcessCache;
  final PushService? pushService;

  const SettingsPage({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.onClearProcessCache,
    this.pushService,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late AppSettings _settings;
  final ApiService _apiService = ApiService();
  List<String> _countries = [];
  bool _loadingCountries = true;

  // Push notification state
  bool _isSubscribing = false;
  bool _isUnsubscribing = false;
  PushSubscriptionState? _pushState;
  String? _pushError;
  bool _isTestingNotification = false;

  // Method channel for Android notification testing
  static const _notificationChannel = MethodChannel(
    'com.ignacioaldama.egdata/notification',
  );

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _loadCountries();
    _loadPushState();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await _apiService.getCountries();
      if (mounted) {
        setState(() {
          _countries = countries;
          _loadingCountries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCountries = false;
        });
      }
    }
  }

  Future<void> _loadPushState() async {
    if (widget.pushService == null) return;
    final state = await widget.pushService!.getSubscriptionState();
    if (mounted) {
      setState(() {
        _pushState = state;
      });
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  void _updateSettings(AppSettings newSettings) {
    // Track country changes
    if (_settings.country != newSettings.country) {
      AnalyticsService().setUserCountry(newSettings.country);
    }

    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged(newSettings);
  }

  Future<void> _clearProcessCache() async {
    if (widget.onClearProcessCache == null) return;

    await widget.onClearProcessCache!();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Process cache cleared'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          ),
        ),
      );
    }
  }

  Future<void> _subscribeToPush() async {
    if (widget.pushService == null) return;

    setState(() {
      _isSubscribing = true;
      _pushError = null;
    });

    // Subscribe with free-games topic by default if notifyFreeGames is enabled
    final topics = <String>[];
    if (_settings.notifyFreeGames) {
      topics.add(PushTopics.freeGames);
    }

    final result = await widget.pushService!.subscribe(topics: topics);

    if (mounted) {
      setState(() {
        _isSubscribing = false;
        if (result.success) {
          _pushError = null;
          _updateSettings(_settings.copyWith(pushNotificationsEnabled: true));
        } else {
          _pushError = result.error;
        }
      });

      if (result.success) {
        await _loadPushState();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Subscribed to push notifications'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusSmall),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _unsubscribeFromPush() async {
    if (widget.pushService == null) return;

    setState(() {
      _isUnsubscribing = true;
      _pushError = null;
    });

    final result = await widget.pushService!.unsubscribe();

    if (mounted) {
      setState(() {
        _isUnsubscribing = false;
        if (result.success) {
          _pushError = null;
          _pushState = PushSubscriptionState(isSubscribed: false, topics: []);
          _updateSettings(_settings.copyWith(pushNotificationsEnabled: false));
        } else {
          _pushError = result.error;
        }
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unsubscribed from push notifications'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleTopic(String topic, bool subscribe) async {
    if (widget.pushService == null) return;

    PushSubscriptionResult result;
    if (subscribe) {
      result = await widget.pushService!.subscribeToTopics(topics: [topic]);
    } else {
      result = await widget.pushService!.unsubscribeFromTopics(topics: [topic]);
    }

    if (mounted && result.success) {
      await _loadPushState();
    } else if (mounted && !result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to update topic'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          ),
        ),
      );
    }
  }

  /// Test the custom notification layout (Android only)
  Future<void> _testNotification() async {
    if (!Platform.isAndroid) return;

    setState(() {
      _isTestingNotification = true;
    });

    try {
      // Use a sample offer ID - this is "The Witcher 3: Wild Hunt" which is often free
      // You can change this to any valid offer ID
      const testOfferId = '9064fdd49de04718abe631788ad5a759';

      await _notificationChannel.invokeMethod('testFreeGameNotification', {
        'offerId': testOfferId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Test notification sent'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingNotification = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 100),
                  child: _buildSettingsLayout(constraints.maxWidth),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsLayout(double width) {
    final useColumns = PlatformUtils.isDesktop && width >= 880;
    final primarySections = <Widget>[
      if (PlatformUtils.isMobile) _buildPreferencesSection(),
      if (!PlatformUtils.isMobile) ...[
        _buildSyncSection(),
        _buildStartupSection(),
        _buildDesktopNotificationsSection(),
      ],
      if (PlatformUtils.isMobile && widget.pushService != null)
        _buildPushNotificationsSection(),
    ];
    final secondarySections = <Widget>[
      if (PlatformUtils.isDesktop) _buildDataSection(),
      _buildAboutSection(),
    ];

    if (!useColumns) {
      return _buildSectionStack([...primarySections, ...secondarySections]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _buildSectionStack(primarySections)),
        const SizedBox(width: 22),
        Expanded(flex: 5, child: _buildSectionStack(secondarySections)),
      ],
    );
  }

  Widget _buildSectionStack(List<Widget> sections) {
    return Column(
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          if (index > 0) const SizedBox(height: 20),
          sections[index],
        ],
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSection(
      title: 'Preferences',
      description: 'Regional pricing and storefront behavior.',
      icon: Icons.tune_rounded,
      color: AppColors.primary,
      children: [
        _buildSettingTile(
          icon: Icons.public_rounded,
          title: 'Country',
          subtitle: 'Used for pricing and regional content',
          trailing: _buildCountrySelector(),
        ),
      ],
    );
  }

  Widget _buildSyncSection() {
    return _buildSection(
      title: 'Sync',
      description: 'Control manifest uploads and background checks.',
      icon: Icons.sync_rounded,
      color: AppColors.accent,
      children: [
        _buildSettingTile(
          icon: Icons.cloud_upload_rounded,
          title: 'Auto Sync',
          subtitle: 'Automatically upload manifests at regular intervals',
          trailing: _SettingsToggle(
            value: _settings.autoSync,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(autoSync: value));
            },
          ),
        ),
        _buildDivider(),
        _buildSettingTile(
          icon: Icons.schedule_rounded,
          title: 'Sync Interval',
          subtitle: 'How often to check for new manifests',
          trailing: _buildIntervalSelector(),
          enabled: _settings.autoSync,
        ),
      ],
    );
  }

  Widget _buildStartupSection() {
    return _buildSection(
      title: 'Startup',
      description: 'Decide how EGData behaves with the desktop shell.',
      icon: Icons.power_settings_new_rounded,
      color: AppColors.success,
      children: [
        if (Platform.isWindows) ...[
          _buildSettingTile(
            icon: Icons.login_rounded,
            title: 'Launch at Startup',
            subtitle: 'Start EGData Client when you log in',
            trailing: _SettingsToggle(
              value: _settings.launchAtStartup,
              onChanged: (value) {
                _updateSettings(_settings.copyWith(launchAtStartup: value));
              },
            ),
          ),
          _buildDivider(),
        ],
        _buildSettingTile(
          icon: Icons.move_to_inbox_rounded,
          title: 'Minimize to Tray',
          subtitle: 'Keep running in system tray when window is closed',
          trailing: _SettingsToggle(
            value: _settings.minimizeToTray,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(minimizeToTray: value));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopNotificationsSection() {
    return _buildSection(
      title: 'Notifications',
      description: 'Choose which local desktop alerts should appear.',
      icon: Icons.notifications_rounded,
      color: AppColors.warning,
      children: [
        _buildSettingTile(
          icon: Icons.card_giftcard_rounded,
          title: 'Free Games',
          subtitle: 'Notify when free games become available',
          trailing: _SettingsToggle(
            value: _settings.notifyFreeGames,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(notifyFreeGames: value));
            },
          ),
        ),
        _buildDivider(),
        _buildSettingTile(
          icon: Icons.rocket_launch_rounded,
          title: 'Releases',
          subtitle: 'Notify when upcoming games release',
          trailing: _SettingsToggle(
            value: _settings.notifyReleases,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(notifyReleases: value));
            },
          ),
        ),
        _buildDivider(),
        _buildSettingTile(
          icon: Icons.sell_rounded,
          title: 'Sales',
          subtitle: 'Notify when games go on sale',
          trailing: _SettingsToggle(
            value: _settings.notifySales,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(notifySales: value));
            },
          ),
        ),
        _buildDivider(),
        _buildSettingTile(
          icon: Icons.star_rounded,
          title: 'Followed Games',
          subtitle: 'Notify when followed games are updated',
          trailing: _SettingsToggle(
            value: _settings.notifyFollowedUpdates,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(notifyFollowedUpdates: value));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return _buildSection(
      title: 'Data',
      description: 'Maintenance actions for local app data.',
      icon: Icons.storage_rounded,
      color: AppColors.accentPink,
      children: [
        _buildActionTile(
          title: 'Clear Process Cache',
          subtitle: 'Force refresh of game process names from API',
          icon: Icons.refresh_rounded,
          onTap: _clearProcessCache,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About',
      description: 'Client information and project purpose.',
      icon: Icons.info_outline_rounded,
      color: AppColors.textSecondary,
      children: [
        _buildSettingTile(
          icon: Icons.memory_rounded,
          title: 'EGData Client',
          subtitle: 'Version 0.1.0',
          trailing: _buildBadge('FLUTTER'),
        ),
        _buildDivider(),
        _buildSettingTile(
          icon: Icons.science_rounded,
          title: 'Purpose',
          subtitle: 'Preserves Epic Games Store manifest data for research',
          trailing: _buildIconBadge(Icons.science_rounded),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
              ),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Configure sync, startup, notifications, and local data.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusSmall),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.04),
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(
                        AppColors.radiusSmall,
                      ),
                      border: Border.all(color: color.withValues(alpha: 0.28)),
                    ),
                    child: Icon(icon, size: 19, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(children: children),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 70),
      color: AppColors.border,
    );
  }

  Widget _buildPushNotificationsSection() {
    final isSubscribed = _pushState?.isSubscribed ?? false;
    final subscribedTopics = _pushState?.topics ?? [];
    final isAvailable = widget.pushService?.isAvailable ?? false;

    return _buildSection(
      title: 'Notifications',
      description: 'Mobile push delivery and notification topics.',
      icon: Icons.notifications_rounded,
      color: AppColors.primary,
      children: [
        // Show warning if Firebase is not configured
        if (!isAvailable) ...[
          Container(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Firebase Not Configured',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Push notifications require Firebase setup. Contact the developer for configuration.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Subscribe/Unsubscribe button
          Container(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSubscribed
                                ? 'Subscribed'
                                : 'Subscribe to Push Notifications',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSubscribed
                                ? 'Receiving notifications from EGData'
                                : 'Get real-time notifications on your device',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (isSubscribed)
                      _SettingsButton(
                        label: 'Unsubscribe',
                        color: AppColors.error,
                        foregroundColor: Colors.white,
                        loading: _isUnsubscribing,
                        onPressed: _isUnsubscribing
                            ? null
                            : _unsubscribeFromPush,
                      )
                    else
                      _SettingsButton(
                        label: 'Subscribe',
                        color: AppColors.primary,
                        foregroundColor: AppColors.background,
                        loading: _isSubscribing,
                        onPressed: _isSubscribing ? null : _subscribeToPush,
                      ),
                  ],
                ),
                if (_pushError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppColors.radiusSmall,
                      ),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pushError!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Topic subscriptions (only shown when subscribed)
          if (isSubscribed) ...[
            _buildDivider(),
            _buildSettingTile(
              icon: Icons.card_giftcard_rounded,
              title: 'Free Games',
              subtitle: 'Receive notifications for new free games',
              trailing: _SettingsToggle(
                value: subscribedTopics.contains(PushTopics.freeGames),
                onChanged: (value) {
                  _toggleTopic(PushTopics.freeGames, value);
                },
              ),
            ),
          ],
          // Test notification button (Android only)
          if (Platform.isAndroid) ...[
            _buildDivider(),
            _buildActionTile(
              title: 'Test Notification',
              subtitle: 'Preview the custom notification layout',
              icon: _isTestingNotification
                  ? Icons.hourglass_empty_rounded
                  : Icons.notifications_active_rounded,
              onTap: _isTestingNotification ? () {} : _testNotification,
            ),
          ],
        ], // end of else (isAvailable)
      ],
    );
  }

  Widget _buildSettingTile({
    IconData? icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final leading = icon == null
              ? const SizedBox.shrink()
              : _buildTileIcon(icon);
          final text = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (icon != null) ...[
                            leading,
                            const SizedBox(width: 12),
                          ],
                          text,
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(alignment: Alignment.centerLeft, child: trailing),
                    ],
                  )
                : Row(
                    children: [
                      if (icon != null) ...[leading, const SizedBox(width: 12)],
                      text,
                      const SizedBox(width: 16),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.52,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          widthFactor: 1,
                          child: trailing,
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTileIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Icon(icon, color: AppColors.textSecondary, size: 18),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildIconBadge(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Icon(icon, color: AppColors.textMuted, size: 18),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildTileIcon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.26),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalSelector() {
    const options = [
      (15, '15m'),
      (30, '30m'),
      (60, '1h'),
      (120, '2h'),
      (360, '6h'),
      (720, '12h'),
      (1440, '24h'),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 292),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final option in options)
            _SettingsChoice(
              label: option.$2,
              selected: _settings.syncIntervalMinutes == option.$1,
              enabled: _settings.autoSync,
              onTap: () {
                _updateSettings(
                  _settings.copyWith(syncIntervalMinutes: option.$1),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCountrySelector() {
    if (_loadingCountries) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.textSecondary,
        ),
      );
    }

    final currentCountry = _countries.contains(_settings.country)
        ? _settings.country
        : (_countries.isNotEmpty ? _countries.first : 'US');

    final countryData = CountryUtils.getCountry(currentCountry);
    final displayName = countryData?.name ?? currentCountry;
    final flag = countryData?.flag ?? '';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showCountryPicker(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (flag.isNotEmpty) ...[
                  Text(flag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerSheet(
        countries: _countries,
        selectedCountry: _settings.country,
        onSelect: (code) {
          _updateSettings(_settings.copyWith(country: code));
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final trackColor = value
        ? AppColors.primary.withValues(alpha: 0.22)
        : AppColors.surfaceLight;
    final borderColor = value
        ? AppColors.primary.withValues(alpha: 0.55)
        : AppColors.borderLight;
    final knobColor = value ? AppColors.primary : AppColors.textMuted;

    return Semantics(
      button: true,
      toggled: value,
      enabled: true,
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 66,
            height: 34,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
              border: Border.all(color: borderColor),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: value
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: value ? 7 : 0,
                      right: value ? 0 : 7,
                    ),
                    child: Text(
                      value ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        color: value ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: knobColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _SettingsChoice({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary.withValues(alpha: 0.55)
        : AppColors.borderLight;
    final backgroundColor = selected
        ? AppColors.primary.withValues(alpha: 0.14)
        : AppColors.surfaceLight;
    final textColor = selected ? AppColors.primary : AppColors.textSecondary;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              color: enabled ? textColor : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color foregroundColor;
  final bool loading;
  final VoidCallback? onPressed;

  const _SettingsButton({
    required this.label,
    required this.color,
    required this.foregroundColor,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabled ? 1 : 0.55,
          child: Container(
            constraints: const BoxConstraints(minWidth: 116, minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
              border: Border.all(color: color.withValues(alpha: 0.65)),
            ),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foregroundColor,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        color: foregroundColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final List<String> countries;
  final String selectedCountry;
  final ValueChanged<String> onSelect;

  const _CountryPickerSheet({
    required this.countries,
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryData> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    _filteredCountries = CountryUtils.getCountriesForCodes(widget.countries);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredCountries = CountryUtils.getCountriesForCodes(
          widget.countries,
        );
      } else {
        _filteredCountries = CountryUtils.searchCountries(
          widget.countries,
          _searchController.text,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Select Country',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Search field
                TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search countries...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppColors.radiusSmall,
                      ),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppColors.radiusSmall,
                      ),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppColors.radiusSmall,
                      ),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Country list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: bottomPadding + 20),
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry;

                return InkWell(
                  onTap: () => widget.onSelect(country.code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          country.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                country.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                country.code,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
