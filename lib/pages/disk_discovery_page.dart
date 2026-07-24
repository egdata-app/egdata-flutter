import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/drive_discovery.dart';
import '../services/drive_discovery_service.dart';
import '../services/epic_recovery_service.dart';
import '../theme/desktop_theme.dart';

class DiskDiscoveryPage extends StatefulWidget {
  final DriveDiscoveryService service;
  final EpicRecoveryService recoveryService;
  final VoidCallback onBack;

  const DiskDiscoveryPage({
    super.key,
    required this.service,
    required this.recoveryService,
    required this.onBack,
  });

  @override
  State<DiskDiscoveryPage> createState() => _DiskDiscoveryPageState();
}

class _DiskDiscoveryPageState extends State<DiskDiscoveryPage> {
  final Set<String> _selected = {};
  List<DetectedUnknownInstall> _unknown = const [];
  DriveScanCancellation? _scanCancellation;
  bool _scanning = false;
  bool _restoring = false;
  String? _scanPath;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceChanged);
    _selectValidated();
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChanged);
    _scanCancellation?.cancel();
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    setState(_selectValidated);
  }

  void _selectValidated() {
    final validIds = widget.service.recoveryCandidates
        .where((candidate) => candidate.canRestore)
        .map((candidate) => candidate.installationGuid)
        .toSet();
    _selected.removeWhere((id) => !validIds.contains(id));
    _selected.addAll(validIds);
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.service.recoveryCandidates;
    return ColoredBox(
      color: DesktopTheme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 24),
            _safetyNotice(),
            const SizedBox(height: 18),
            _sectionHeader(
              'Known installations',
              '${candidates.length} detected',
            ),
            const SizedBox(height: 10),
            if (candidates.isEmpty)
              _emptyKnown()
            else
              Container(
                decoration: DesktopTheme.panel(),
                child: Column(
                  children: [
                    for (var index = 0; index < candidates.length; index++) ...[
                      _candidateRow(candidates[index]),
                      if (index != candidates.length - 1)
                        const Divider(height: 1, color: DesktopTheme.border),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _selected.isEmpty || _restoring ? null : _restore,
                icon: _restoring
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore_rounded),
                label: Text(
                  _restoring
                      ? 'Restoring…'
                      : 'Restore selected (${_selected.length})',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: DesktopTheme.primaryStrong,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _sectionHeader('Never-seen installations', 'Detect only in v1'),
            const SizedBox(height: 10),
            _unknownScanner(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        IconButton(
          onPressed: widget.onBack,
          tooltip: 'Back to Tools',
          icon: const Icon(Icons.arrow_back),
          color: DesktopTheme.textPrimary,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disk Discovery',
                style: TextStyle(
                  color: DesktopTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Reconnect existing Epic installations without downloading them again.',
                style: TextStyle(
                  color: DesktopTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: widget.service.refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Check drives'),
        ),
      ],
    );
  }

  Widget _safetyNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesktopTheme.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(DesktopTheme.radiusMedium),
        border: Border.all(color: DesktopTheme.success.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_outlined, color: DesktopTheme.success),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'EGData changes only Epic launcher registration files. Game data is never moved or deleted. Backups are created before every restore.',
              style: TextStyle(color: DesktopTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String detail) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: DesktopTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          detail,
          style: const TextStyle(color: DesktopTheme.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _candidateRow(RecoveryCandidate candidate) {
    final selected = _selected.contains(candidate.installationGuid);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: candidate.canRestore
                ? (value) {
                    setState(() {
                      if (value == true) {
                        _selected.add(candidate.installationGuid);
                      } else {
                        _selected.remove(candidate.installationGuid);
                      }
                    });
                  }
                : null,
            activeColor: DesktopTheme.primaryStrong,
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DesktopTheme.surfaceRaised,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              candidate.canRestore
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: candidate.canRestore
                  ? DesktopTheme.success
                  : DesktopTheme.warning,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.displayName,
                  style: const TextStyle(
                    color: DesktopTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  candidate.discoveredInstallLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesktopTheme.textMuted,
                    fontSize: 11,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                if (candidate.validationError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    candidate.validationError!,
                    style: const TextStyle(
                      color: DesktopTheme.warning,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _badge(
            candidate.canRestore ? 'Validated' : 'Detected only',
            candidate.canRestore ? DesktopTheme.success : DesktopTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyKnown() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: DesktopTheme.panel(),
      child: const Column(
        children: [
          Icon(Icons.storage_rounded, color: DesktopTheme.textMuted, size: 38),
          SizedBox(height: 12),
          Text(
            'No recoverable games found',
            style: TextStyle(
              color: DesktopTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Known installations will appear automatically when their drive reconnects.',
            style: TextStyle(color: DesktopTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _unknownScanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: DesktopTheme.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Choose a drive or folder to look for .egstore installations. Unknown games are reported but never registered automatically.',
                  style: TextStyle(
                    color: DesktopTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (_scanning)
                OutlinedButton.icon(
                  onPressed: _cancelScan,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                )
              else
                OutlinedButton.icon(
                  onPressed: _scanFolder,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Scan folder'),
                ),
            ],
          ),
          if (_scanning) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(color: DesktopTheme.primary),
            if (_scanPath != null) ...[
              const SizedBox(height: 8),
              Text(
                _scanPath!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DesktopTheme.textMuted,
                  fontSize: 10,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ],
          ],
          if (_unknown.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final install in _unknown)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.folder_copy_outlined,
                  color: DesktopTheme.warning,
                ),
                title: Text(
                  install.displayName,
                  style: const TextStyle(color: DesktopTheme.textPrimary),
                ),
                subtitle: Text(
                  install.installLocation,
                  style: const TextStyle(
                    color: DesktopTheme.textMuted,
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10,
                  ),
                ),
                trailing: _badge('Detected only', DesktopTheme.warning),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final selected = widget.service.recoveryCandidates
        .where((candidate) => _selected.contains(candidate.installationGuid))
        .toList();
    final result = await widget.recoveryService.restore(selected);
    if (mounted) {
      setState(() => _restoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success
              ? DesktopTheme.success
              : DesktopTheme.danger,
        ),
      );
    }
    await widget.service.refresh();
  }

  Future<void> _scanFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose a drive or game folder',
    );
    if (path == null || !mounted) return;
    final cancellation = DriveScanCancellation();
    setState(() {
      _scanCancellation = cancellation;
      _unknown = const [];
      _scanPath = path;
      _scanning = true;
    });
    final results = await widget.service.scanFolder(
      path,
      cancellation: cancellation,
      onProgress: (value) {
        if (mounted) setState(() => _scanPath = value);
      },
    );
    if (!mounted) return;
    setState(() {
      _unknown = results;
      _scanning = false;
      _scanCancellation = null;
    });
  }

  void _cancelScan() {
    _scanCancellation?.cancel();
  }
}
