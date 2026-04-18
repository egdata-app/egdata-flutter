import 'dart:async';
import 'dart:convert';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/epic_auth_service.dart';
import '../services/sync_queue_service.dart';
import '../utils/webview_utils.dart';

class EpicSyncDialog extends StatefulWidget {
  final EpicAuthService authService;
  final SyncQueueService syncQueueService;
  final VoidCallback? onNavigateToDashboard;

  const EpicSyncDialog({
    super.key,
    required this.authService,
    required this.syncQueueService,
    this.onNavigateToDashboard,
  });

  @override
  State<EpicSyncDialog> createState() => _EpicSyncDialogState();
}

class _EpicSyncDialogState extends State<EpicSyncDialog> {
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    widget.syncQueueService.addListener(_onQueueChanged);
  }

  @override
  void dispose() {
    widget.syncQueueService.removeListener(_onQueueChanged);
    super.dispose();
  }

  Future<void> _checkAuth() async {
    await widget.authService.loadTokens();
    if (mounted) setState(() {});
  }

  void _onQueueChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _login() async {
    setState(() {
      _isLoggingIn = true;
    });

    try {
      final webview = await WebviewWindow.create(
        configuration: CreateConfiguration(
          windowHeight: 700,
          windowWidth: 500,
          title: 'Login to Epic Games',
          userDataFolderWindows: await getWebViewUserDataFolder(),
        ),
      );

      const clientId = '34a02cf8f4414e29b15921876da36f9a';
      const loginUrl = 'https://www.epicgames.com/id/login';
      const redirectApiUrl =
          'https://www.epicgames.com/id/api/redirect'
          '?clientId=$clientId'
          '&responseType=code';

      webview.launch(loginUrl);

      Timer? pollingTimer;
      bool isClosing = false;
      bool redirectTriggered = false;

      Future<void> processRedirectResponse() async {
        if (isClosing || redirectTriggered) return;
        redirectTriggered = true;

        try {
          final content = await webview.evaluateJavaScript(
            'document.body.innerText',
          );
          if (content != null) {
            final rawContent = content.startsWith('"') && content.endsWith('"')
                ? jsonDecode(content) as String
                : content;

            final decoded = jsonDecode(rawContent);
            if (decoded is Map) {
              final code = decoded['authorizationCode'] ?? decoded['code'];
              if (code != null && code is String && code.isNotEmpty) {
                debugPrint('Got authorization code from /id/api/redirect');

                isClosing = true;
                pollingTimer?.cancel();
                webview.close();

                final success = await widget.authService.exchangeCode(
                  code,
                  isAuthorizationCode: true,
                );

                if (success) {
                  if (mounted) setState(() => _isLoggingIn = false);
                } else {
                  if (mounted) setState(() => _isLoggingIn = false);
                }
                return;
              }
            }
          }
        } catch (e) {
          debugPrint('Failed to parse redirect response: $e');
        }
        redirectTriggered = false;
      }

      webview.addOnUrlRequestCallback((url) {
        if (isClosing) return;

        if (url.contains('/id/api/redirect')) {
          Future.delayed(
            const Duration(milliseconds: 500),
            processRedirectResponse,
          );
        }
      });

      pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (
        timer,
      ) async {
        if (!mounted || !_isLoggingIn || isClosing) {
          timer.cancel();
          return;
        }
        try {
          final url = await webview.evaluateJavaScript('window.location.href');
          if (url == null) return;

          final cleanUrl = url.startsWith('"') && url.endsWith('"')
              ? jsonDecode(url) as String
              : url;

          if (cleanUrl.contains('/id/api/redirect')) {
            await processRedirectResponse();
            return;
          }

          if (!redirectTriggered &&
              !cleanUrl.contains('/id/login') &&
              !cleanUrl.contains('/id/authorize') &&
              cleanUrl.contains('epicgames.com') &&
              !cleanUrl.contains('/id/')) {
            webview.launch(redirectApiUrl);
          }
        } catch (_) {
          timer.cancel();
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = widget.authService.isAuthenticated;
    final queue = widget.syncQueueService;
    final isRunning = queue.isRunning;

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        side: BorderSide(color: AppColors.border),
      ),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cloud_sync,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                const Text(
                  'Epic Cloud Sync',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isRunning)
              Text(
                'Sync runs in the background. You can close this dialog.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              )
            else
              const Text(
                'Sync your Epic Games library manifests directly to egdata.app without installing the games.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            const SizedBox(height: 24),
            if (!isAuthenticated) ...[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Login Required',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You need to log in with Epic Games to use Cloud Sync.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (widget.onNavigateToDashboard != null)
                      ElevatedButton(
                        onPressed: widget.onNavigateToDashboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Go to Dashboard to Login'),
                      )
                    else
                      ElevatedButton(
                        onPressed: _isLoggingIn ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: _isLoggingIn
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text('Login with Epic Games'),
                      ),
                  ],
                ),
              ),
            ] else ...[
              if (isRunning) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        queue.statusMessage,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Text(
                      '${queue.completed}/${queue.total}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: queue.total > 0 ? queue.completed / queue.total : null,
                  backgroundColor: AppColors.surfaceLight,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: queue.cancel,
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
              ] else if (queue.status == SyncQueueStatus.completed ||
                  queue.status == SyncQueueStatus.failed ||
                  queue.status == SyncQueueStatus.cancelled) ...[
                Row(
                  children: [
                    Icon(
                      queue.status == SyncQueueStatus.completed
                          ? Icons.check_circle
                          : Icons.error,
                      color: queue.status == SyncQueueStatus.completed
                          ? Colors.green
                          : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        queue.statusMessage,
                        style: TextStyle(
                          color: queue.status == SyncQueueStatus.completed
                              ? Colors.green
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    queue.reset();
                    queue.startSync();
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Start Full Cloud Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: widget.authService.logout,
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Logout'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: queue.startSync,
                  icon: const Icon(Icons.sync),
                  label: const Text('Start Full Cloud Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: widget.authService.logout,
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Logout'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Sync Logs',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: queue.logs.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        queue.logs[index],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
