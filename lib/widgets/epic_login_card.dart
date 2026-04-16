import 'package:flutter/material.dart';
import '../main.dart';
import '../services/epic_auth_service.dart';

class EpicLoginCard extends StatefulWidget {
  final EpicAuthService? authService;

  const EpicLoginCard({
    super.key,
    this.authService,
  });

  @override
  State<EpicLoginCard> createState() => _EpicLoginCardState();
}

class _EpicLoginCardState extends State<EpicLoginCard> {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (widget.authService == null) return;
    await widget.authService!.loadTokens();
    if (mounted) {
      setState(() {
        _isAuthenticated = widget.authService!.isAuthenticated;
        _accountId = widget.authService!.accountId;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (widget.authService == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await widget.authService!.login();
      if (success) {
        await _checkAuth();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    if (widget.authService == null) return;

    setState(() => _isLoading = true);

    try {
      await widget.authService!.logout();
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _accountId = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatAccountId(String? accountId) {
    if (accountId == null) return 'Unknown';
    if (accountId.length <= 8) return accountId;
    // Show first 4 and last 4 characters
    return '${accountId.substring(0, 4)}...${accountId.substring(accountId.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isAuthenticated
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.textMuted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                ),
                child: Icon(
                  _isAuthenticated ? Icons.check_circle_rounded : Icons.login_rounded,
                  size: 20,
                  color: _isAuthenticated ? AppColors.success : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Epic Games',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isAuthenticated ? 'Logged in' : 'Not logged in',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _isAuthenticated ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isAuthenticated && _accountId != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _formatAccountId(_accountId),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (!_isAuthenticated)
            Text(
              'Login to sync your Epic library and access cloud features.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (_isAuthenticated ? _handleLogout : _handleLogin),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAuthenticated ? AppColors.surfaceLight : AppColors.primary,
                foregroundColor: _isAuthenticated ? AppColors.textPrimary : Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: _isAuthenticated
                      ? BorderSide(color: AppColors.border)
                      : BorderSide.none,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      _isAuthenticated ? 'Logout' : 'Login with Epic Games',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
