import 'dart:io';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/settings.dart';
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

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _settings;
  final ApiService _apiService = ApiService();
  List<String> _countries = [];
  bool _loadingCountries = true;

  // Push notification state
  bool _isSubscribing = false;
  bool _isUnsubscribing = false;
  PushSubscriptionState? _pushState;
  String? _pushError;

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
          _pushState = PushSubscriptionState(
            isSubscribed: false,
            topics: [],
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country selection only on mobile (desktop doesn't need it)
                  if (PlatformUtils.isMobile) ...[
                    _buildSection(
                      title: 'Preferences',
                      icon: Icons.tune_rounded,
                      color: AppColors.primary,
                      children: [
                        _buildSettingTile(
                          title: 'Country',
                          subtitle: 'Used for pricing and regional content',
                          trailing: _buildCountrySelector(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (!PlatformUtils.isMobile) ...[
                    _buildSection(
                      title: 'Sync',
                      icon: Icons.sync_rounded,
                      color: AppColors.accent,
                      children: [
                        _buildSettingTile(
                          title: 'Auto Sync',
                          subtitle: 'Automatically upload manifests at regular intervals',
                          trailing: Switch(
                            value: _settings.autoSync,
                            onChanged: (value) {
                              _updateSettings(_settings.copyWith(autoSync: value));
                            },
                          ),
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          title: 'Sync Interval',
                          subtitle: 'How often to check for new manifests',
                          trailing: _buildIntervalDropdown(),
                          enabled: _settings.autoSync,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Startup',
                      icon: Icons.power_settings_new_rounded,
                      color: AppColors.success,
                      children: [
                        if (Platform.isWindows) ...[
                          _buildSettingTile(
                            title: 'Launch at Startup',
                            subtitle: 'Start EGData Client when you log in',
                            trailing: Switch(
                              value: _settings.launchAtStartup,
                              onChanged: (value) {
                                _updateSettings(_settings.copyWith(launchAtStartup: value));
                              },
                            ),
                          ),
                          _buildDivider(),
                        ],
                        _buildSettingTile(
                          title: 'Minimize to Tray',
                          subtitle: 'Keep running in system tray when window is closed',
                          trailing: Switch(
                            value: _settings.minimizeToTray,
                            onChanged: (value) {
                              _updateSettings(_settings.copyWith(minimizeToTray: value));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Desktop: show local notification settings
                  if (!PlatformUtils.isMobile) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Notifications',
                      icon: Icons.notifications_rounded,
                      color: AppColors.warning,
                      children: [
                        _buildSettingTile(
                          title: 'Free Games',
                          subtitle: 'Notify when free games become available',
                          trailing: Switch(
                            value: _settings.notifyFreeGames,
                            onChanged: (value) {
                              _updateSettings(_settings.copyWith(notifyFreeGames: value));
                            },
                          ),
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          title: 'Releases',
                          subtitle: 'Notify when upcoming games release',
                          trailing: Switch(
                            value: _settings.notifyReleases,
                            onChanged: (value) {
                              _updateSettings(_settings.copyWith(notifyReleases: value));
                            },
                          ),
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          title: 'Sales',
                          subtitle: 'Notify when games go on sale',
                          trailing: Switch(
                            value: _settings.notifySales,
                            onChanged: (value) {
                              _updateSettings(_settings.copyWith(notifySales: value));
                            },
                          ),
                        ),
                        _buildDivider(),
                        _buildSettingTile(
                          title: 'Followed Games',
                          subtitle: 'Notify when followed games are updated',
                          trailing: Switch(
                            value: _settings.notifyFollowedUpdates,
                            onChanged: (value) {
                              _updateSettings(_settings.copyWith(notifyFollowedUpdates: value));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Mobile: show push notification settings
                  if (PlatformUtils.isMobile && widget.pushService != null) ...[
                    const SizedBox(height: 24),
                    _buildPushNotificationsSection(),
                  ],
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Data',
                    icon: Icons.storage_rounded,
                    color: AppColors.accent,
                    children: [
                      _buildActionTile(
                        title: 'Clear Process Cache',
                        subtitle: 'Force refresh of game process names from API',
                        icon: Icons.refresh_rounded,
                        onTap: _clearProcessCache,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'About',
                    icon: Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                    children: [
                      _buildSettingTile(
                        title: 'EGData Client',
                        subtitle: 'Version 0.1.0',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Text(
                            'FLUTTER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _buildSettingTile(
                        title: 'Purpose',
                        subtitle: 'Helps preserve Epic Games Store manifest data for research',
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                          ),
                          child: const Icon(
                            Icons.science_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure app behavior',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppColors.radiusSmall),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.border,
    );
  }

  Widget _buildPushNotificationsSection() {
    final isSubscribed = _pushState?.isSubscribed ?? false;
    final subscribedTopics = _pushState?.topics ?? [];
    final isAvailable = widget.pushService?.isAvailable ?? false;

    return _buildSection(
      title: 'Notifications',
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
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
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
                          isSubscribed ? 'Subscribed' : 'Subscribe to Push Notifications',
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
                    ElevatedButton(
                      onPressed: _isUnsubscribing ? null : _unsubscribeFromPush,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                        ),
                      ),
                      child: _isUnsubscribing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Unsubscribe',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isSubscribing ? null : _subscribeToPush,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                        ),
                      ),
                      child: _isSubscribing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Subscribe',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                ],
              ),
              if (_pushError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
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
            title: 'Free Games',
            subtitle: 'Receive notifications for new free games',
            trailing: Switch(
              value: subscribedTopics.contains(PushTopics.freeGames),
              onChanged: (value) {
                _toggleTopic(PushTopics.freeGames, value);
              },
            ),
          ),
        ],
        ], // end of else (isAvailable)
      ],
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
            trailing,
          ],
        ),
      ),
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
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Icon(
                  icon,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _settings.syncIntervalMinutes,
          isDense: true,
          dropdownColor: AppColors.surface,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
          icon: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          onChanged: _settings.autoSync
              ? (value) {
                  if (value != null) {
                    _updateSettings(_settings.copyWith(syncIntervalMinutes: value));
                  }
                }
              : null,
          items: const [
            DropdownMenuItem(value: 15, child: Text('15 min')),
            DropdownMenuItem(value: 30, child: Text('30 min')),
            DropdownMenuItem(value: 60, child: Text('1 hour')),
            DropdownMenuItem(value: 120, child: Text('2 hours')),
            DropdownMenuItem(value: 360, child: Text('6 hours')),
            DropdownMenuItem(value: 720, child: Text('12 hours')),
            DropdownMenuItem(value: 1440, child: Text('24 hours')),
          ],
        ),
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
        _filteredCountries = CountryUtils.getCountriesForCodes(widget.countries);
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
                      borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusSmall),
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
