import 'package:flutter/material.dart';

import '../services/drive_discovery_service.dart';
import '../services/sync_queue_service.dart';
import '../theme/desktop_theme.dart';

class DesktopToolsPage extends StatelessWidget {
  final SyncQueueService? syncQueueService;
  final DriveDiscoveryService? driveDiscoveryService;
  final VoidCallback onOpenSyncCenter;
  final VoidCallback onOpenDiskDiscovery;
  final VoidCallback onToggleConsole;

  const DesktopToolsPage({
    super.key,
    required this.syncQueueService,
    required this.driveDiscoveryService,
    required this.onOpenSyncCenter,
    required this.onOpenDiskDiscovery,
    required this.onToggleConsole,
  });

  @override
  Widget build(BuildContext context) {
    final recoveryCount = driveDiscoveryService?.recoveryCandidates.length ?? 0;
    final queued = syncQueueService?.queue.length ?? 0;
    return ColoredBox(
      color: DesktopTheme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(36, 30, 32, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tools',
              style: TextStyle(
                color: DesktopTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Recovery, manifests, and diagnostics—available when you need them.',
              style: TextStyle(color: DesktopTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 26),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 850
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: width,
                      child: _toolCard(
                        icon: Icons.storage_rounded,
                        color: DesktopTheme.primary,
                        title: 'Disk Discovery',
                        detail: recoveryCount == 0
                            ? 'Monitor drives and find existing installations.'
                            : '$recoveryCount installation${recoveryCount == 1 ? '' : 's'} ready to review.',
                        action: 'Open recovery',
                        onTap: onOpenDiskDiscovery,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _toolCard(
                        icon: Icons.sync_alt_rounded,
                        color: DesktopTheme.success,
                        title: 'Sync Center',
                        detail: queued == 0
                            ? 'Upload and repair Epic manifest contribution data.'
                            : '$queued manifest item${queued == 1 ? '' : 's'} in the current queue.',
                        action: 'Open Sync Center',
                        onTap: onOpenSyncCenter,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _toolCard(
                        icon: Icons.monitor_heart_outlined,
                        color: DesktopTheme.warning,
                        title: 'Diagnostics',
                        detail:
                            'Inspect scan logs, metadata hydration, and process detection.',
                        action: 'Toggle diagnostics',
                        onTap: onToggleConsole,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolCard({
    required IconData icon,
    required Color color,
    required String title,
    required String detail,
    required String action,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: DesktopTheme.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: DesktopTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(
              color: DesktopTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward, size: 17),
            label: Text(action),
          ),
        ],
      ),
    );
  }
}
