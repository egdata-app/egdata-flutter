import 'dart:io';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/settings.dart';

class SettingsPage extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  const SettingsPage({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _updateSettings(AppSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'SYNC',
                    children: [
                      _buildSettingTile(
                        title: 'Auto Sync',
                        subtitle: 'Automatically upload manifests at regular intervals',
                        trailing: Switch(
                          value: _settings.autoSync,
                          onChanged: (value) {
                            _updateSettings(_settings.copyWith(autoSync: value));
                          },
                          activeTrackColor: AppColors.primary,
                          activeThumbColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                    title: 'STARTUP',
                    children: [
                      // Launch at startup only available on Windows
                      // macOS requires LaunchAtLogin native setup
                      if (Platform.isWindows)
                        _buildSettingTile(
                          title: 'Launch at Startup',
                          subtitle: 'Start EGData Client when you log in',
                          trailing: Switch(
                            value: _settings.launchAtStartup,
                            onChanged: (value) {
                              _updateSettings(_settings.copyWith(launchAtStartup: value));
                            },
                            activeTrackColor: AppColors.primary,
                            activeThumbColor: Colors.white,
                          ),
                        ),
                      if (Platform.isWindows) const SizedBox(height: 2),
                      _buildSettingTile(
                        title: 'Minimize to Tray',
                        subtitle: 'Keep running in system tray when window is closed',
                        trailing: Switch(
                          value: _settings.minimizeToTray,
                          onChanged: (value) {
                            _updateSettings(_settings.copyWith(minimizeToTray: value));
                          },
                          activeTrackColor: AppColors.primary,
                          activeThumbColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'NOTIFICATIONS',
                    children: [
                      _buildSettingTile(
                        title: 'Free Games',
                        subtitle: 'Notify when free games become available',
                        trailing: Switch(
                          value: _settings.notifyFreeGames,
                          onChanged: (value) {
                            _updateSettings(_settings.copyWith(notifyFreeGames: value));
                          },
                          activeTrackColor: AppColors.primary,
                          activeThumbColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildSettingTile(
                        title: 'Releases',
                        subtitle: 'Notify when upcoming games release',
                        trailing: Switch(
                          value: _settings.notifyReleases,
                          onChanged: (value) {
                            _updateSettings(_settings.copyWith(notifyReleases: value));
                          },
                          activeTrackColor: AppColors.primary,
                          activeThumbColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildSettingTile(
                        title: 'Sales',
                        subtitle: 'Notify when games go on sale',
                        trailing: Switch(
                          value: _settings.notifySales,
                          onChanged: (value) {
                            _updateSettings(_settings.copyWith(notifySales: value));
                          },
                          activeTrackColor: AppColors.primary,
                          activeThumbColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildSettingTile(
                        title: 'Followed Games',
                        subtitle: 'Notify when followed games are updated',
                        trailing: Switch(
                          value: _settings.notifyFollowedUpdates,
                          onChanged: (value) {
                            _updateSettings(_settings.copyWith(notifyFollowedUpdates: value));
                          },
                          activeTrackColor: AppColors.primary,
                          activeThumbColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'ABOUT',
                    children: [
                      _buildSettingTile(
                        title: 'EGData Client',
                        subtitle: 'Version 0.1.0',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FLUTTER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildSettingTile(
                        title: 'Purpose',
                        subtitle: 'Helps preserve Epic Games Store manifest data for research',
                        trailing: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.textMuted,
                          size: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: const Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Configure app behavior',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
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
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: children,
          ),
        ),
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
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
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
                      fontSize: 12,
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

  Widget _buildIntervalDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
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
          ),
          icon: const Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: AppColors.textSecondary,
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
}
