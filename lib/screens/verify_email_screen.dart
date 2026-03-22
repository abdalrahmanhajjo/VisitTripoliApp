import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _resent = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startInitialCooldown();
  }

  void _startInitialCooldown() {
    // First resend allowed after 30 sec from register (backend enforces)
    _cooldownSeconds = 30;
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    if (_cooldownSeconds <= 0) {
      if (mounted) setState(() {});
      return;
    }
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      AppSnackBars.showError(
        context,
        AppLocalizations.of(context)!.invalidOrExpiredCode,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.resendVerification,
          textColor: Colors.white,
          onPressed: () => _resend(),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resp = await ApiService.instance.verifyEmail(code);
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.replaceSessionFromVerify(
        resp['token'] as String,
        resp['user'] as Map<String, dynamic>,
      );
      if (mounted) {
        final user = resp['user'] as Map<String, dynamic>;
        context
            .go(user['onboardingCompleted'] == true ? '/explore' : '/language');
      }
    } on ApiException catch (e) {
      if (mounted) {
        final isInvalidCode = e.body.contains('Invalid') || e.body.contains('expired');
        AppSnackBars.showError(
          context,
          e.body,
          action: isInvalidCode
              ? SnackBarAction(
                  label: AppLocalizations.of(context)!.resendVerification,
                  textColor: Colors.white,
                  onPressed: () => _resend(),
                )
              : null,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.authToken;
    final email = authProvider.userEmail;
    if (token == null || email == null) return;
    if (_cooldownSeconds > 0) return;

    setState(() => _isLoading = true);
    try {
      final cooldown = await ApiService.instance.resendVerification(token);
      if (mounted) {
        setState(() {
          _resent = true;
          _cooldownSeconds = cooldown;
          _isLoading = false;
        });
        _startCooldownTimer();
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 429 && e.retryAfter != null) {
          setState(() {
            _cooldownSeconds = e.retryAfter!;
            _isLoading = false;
          });
          _startCooldownTimer();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.body), backgroundColor: AppTheme.errorColor),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final email = authProvider.userEmail ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.mail_outline_rounded,
                  size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              Text(
                l10n.verifyEmailTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.verifyEmailSubtitle(email),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: l10n.enterCode,
                  hintText: '123456',
                  prefixIcon: const Icon(Icons.pin_outlined,
                      size: 20, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(l10n.verifyEmailBtn),
                ),
              ),
              const SizedBox(height: 16),
              if (_resent)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppTheme.successColor, size: 24),
                      const SizedBox(width: 12),
                      Text(l10n.verificationSent,
                          style: const TextStyle(color: AppTheme.successColor)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed:
                      (_isLoading || _cooldownSeconds > 0) ? null : _resend,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _cooldownSeconds > 0
                      ? Text(l10n.resendCodeIn(_cooldownSeconds))
                      : Text(l10n.resendVerification),
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.signIn,
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
