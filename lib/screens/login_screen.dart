import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/trips_provider.dart';
import '../services/api_service.dart';
import '../services/social_auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/auth_error_banner.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  /// After login, go to redirect param (e.g. /profile) if allowed, else explore/language.
  void _goAfterLogin(AuthProvider authProvider) {
    // Load trips from database so they appear after login
    try {
      Provider.of<TripsProvider>(context, listen: false).loadTrips(forceRefresh: true);
    } catch (_) {}
    final redirect =
        GoRouterState.of(context).uri.queryParameters['redirect']?.trim();
    const allowedRedirects = ['/profile', '/trips', '/community'];
    final path = redirect != null &&
            redirect.isNotEmpty &&
            redirect.startsWith('/') &&
            allowedRedirects
                .any((p) => redirect == p || redirect.startsWith('$p?'))
        ? redirect
        : null;
    if (path != null) {
      context.go(path);
      return;
    }
    final onboardingDone = authProvider.onboardingCompleted;
    context.go(onboardingDone ? '/explore' : '/language');
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _backgroundController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resendVerification(String email) async {
    if (email.isEmpty) return;
    try {
      await ApiService.instance.requestVerificationEmail(email);
      if (mounted) {
        AppSnackBars.showSuccess(
            context, 'Verification email sent. Check your inbox.');
      }
    } on ApiException catch (e) {
      if (mounted) AppSnackBars.showError(context, e.body);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ok = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (ok) {
        _goAfterLogin(authProvider);
      } else {
        final msg =
            authProvider.lastError ?? AppLocalizations.of(context)!.loginFailed;
        setState(() => _errorMessage = msg);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final result = await SocialAuthService.instance.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isSuccess && result.idToken != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ok = await authProvider.loginWithGoogle(result.idToken!);
      if (mounted) {
        if (ok) {
          _goAfterLogin(authProvider);
        } else {
          final err = authProvider.lastError ?? 'Sign-in failed';
          AppSnackBars.showError(context, err);
        }
      }
    } else if (result.error != null &&
        result.error != 'Sign-in cancelled' &&
        mounted) {
      AppSnackBars.showError(context, result.error!);
    }
  }

  Future<void> _handleAppleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final result = await SocialAuthService.instance.signInWithApple();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isSuccess && result.idToken != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ok = await authProvider.loginWithApple(
        result.idToken!,
        email: result.email,
        name: result.name,
      );
      if (mounted) {
        if (ok) {
          _goAfterLogin(authProvider);
        } else {
          AppSnackBars.showError(
              context, authProvider.lastError ?? 'Sign-in failed');
        }
      }
    } else if (result.error != null &&
        result.error != 'Sign-in cancelled' &&
        mounted) {
      AppSnackBars.showError(context, result.error!);
    }
  }

  void _handleGuestLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loginAsGuest();
    if (!mounted) return;
    // Guests only see language/interests once (stored locally)
    context.go(authProvider.onboardingCompleted ? '/explore' : '/language');
  }

  Widget _buildGuestOption(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: _isLoading ? null : _handleGuestLogin,
        icon: const Icon(Icons.person_outline_rounded, size: 20),
        label: Text(AppLocalizations.of(context)!.continueAsGuest),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.textSecondary,
        ),
      ),
    );
  }

  static double _horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 16;
    if (w < 400) return 20;
    return 24;
  }

  static double _verticalSpacing(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    if (h < 600) return 12;
    if (h < 700) return 16;
    return 20;
  }

  static double _contentMaxWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w > 500) return 440;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final padding = _horizontalPadding(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom +
        MediaQuery.of(context).viewInsets.bottom +
        24;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(context),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _contentMaxWidth(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/intro');
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppTheme.surfaceVariant.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      _buildHeader(context),
                      const SizedBox(height: 32),
                      _buildLoginCard(context),
                      SizedBox(height: _verticalSpacing(context) * 1.25),
                      _buildRegisterLink(context),
                      SizedBox(height: _verticalSpacing(context)),
                      _buildGuestOption(context),
                      SizedBox(height: bottomPadding),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final t = _backgroundController.value;

    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        final sin1 = (t * 2 * 3.14159);
        final sin2 = ((t + 0.3) * 2 * 3.14159);
        final sin3 = ((t + 0.6) * 2 * 3.14159);

        final offset1 = Offset(
          size.width * 0.15 * (0.5 + 0.5 * (1 + sin1).abs()),
          size.height * 0.12 * (0.5 + 0.5 * (1 + sin2).abs()),
        );
        final offset2 = Offset(
          size.width * 0.12 * (0.5 + 0.5 * (1 + sin2).abs()),
          size.height * 0.15 * (0.5 + 0.5 * (1 + sin3).abs()),
        );
        final offset3 = Offset(
          size.width * 0.08 * (0.5 + 0.5 * (1 + sin3).abs()),
          size.height * 0.1 * (0.5 + 0.5 * (1 + sin1).abs()),
        );

        final glowIntensity = 0.5 + 0.3 * (1 + sin1).abs() / 2;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.12),
                AppTheme.backgroundColor,
                AppTheme.accentColor.withValues(alpha: 0.10),
                AppTheme.secondaryColor.withValues(alpha: 0.06),
                AppTheme.successColor.withValues(alpha: 0.04),
              ],
              stops: const [0.0, 0.3, 0.55, 0.75, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Large animated blob top-right with glow
              Positioned(
                top: -120 + offset1.dy,
                right: -100 + offset1.dx,
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryColor
                            .withValues(alpha: 0.18 * glowIntensity),
                        AppTheme.primaryColor
                            .withValues(alpha: 0.12 * glowIntensity),
                        AppTheme.primaryColor
                            .withValues(alpha: 0.06 * glowIntensity),
                        AppTheme.primaryColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor
                            .withValues(alpha: 0.15 * glowIntensity),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              // Large animated blob bottom-left with glow
              Positioned(
                bottom: -140 + offset2.dy,
                left: -120 + offset2.dx,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentColor
                            .withValues(alpha: 0.16 * glowIntensity),
                        AppTheme.accentColor
                            .withValues(alpha: 0.10 * glowIntensity),
                        AppTheme.accentColor
                            .withValues(alpha: 0.05 * glowIntensity),
                        AppTheme.accentColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor
                            .withValues(alpha: 0.12 * glowIntensity),
                        blurRadius: 35,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              // Medium circle mid-right with glow
              Positioned(
                top: size.height * 0.25 + offset1.dy * 0.5,
                right: 30 + offset1.dx * 0.3,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.secondaryColor.withValues(alpha: 0.14),
                        AppTheme.secondaryColor.withValues(alpha: 0.08),
                        AppTheme.secondaryColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
              // Small accent circle top-center
              Positioned(
                top: size.height * 0.15,
                left: size.width * 0.5 - 40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.successColor.withValues(alpha: 0.12),
                        AppTheme.successColor.withValues(alpha: 0.06),
                        AppTheme.successColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withValues(alpha: 0.08),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              // Additional small accent circle
              Positioned(
                top: size.height * 0.6 + offset3.dy,
                left: size.width * 0.2 + offset3.dx,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.warningColor.withValues(alpha: 0.10),
                        AppTheme.warningColor.withValues(alpha: 0.0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warningColor.withValues(alpha: 0.06),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Enhanced mesh overlay with gradient
              Positioned.fill(
                child: CustomPaint(
                  painter: _EnhancedMeshPainter(
                    primaryColor: AppTheme.primaryColor.withValues(alpha: 0.03),
                    accentColor: AppTheme.accentColor.withValues(alpha: 0.02),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.welcomeBack,
          style: (isCompact ? theme.headlineSmall : theme.headlineMedium)
              ?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.signInToContinue,
          style: theme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.5,
            fontSize: isCompact ? 14 : null,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final cardPadding = MediaQuery.sizeOf(context).width < 360 ? 16.0 : 24.0;
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            AuthErrorBanner(
              message: _errorMessage!,
              onDismiss: () => setState(() => _errorMessage = null),
              actionLabel: _errorMessage!.toLowerCase().contains('verify')
                  ? 'Resend'
                  : null,
              onAction: _errorMessage!.toLowerCase().contains('verify')
                  ? () => _resendVerification(_emailController.text.trim())
                  : null,
            ),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleGoogleLogin,
              icon: const FaIcon(FontAwesomeIcons.google, size: 20),
              label: Text(AppLocalizations.of(context)!.continueWithGoogle),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          FutureBuilder<bool>(
            future: SocialAuthService.isAppleSignInAvailable,
            builder: (context, snap) {
              if (snap.data != true) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _handleAppleLogin,
                    icon: const FaIcon(FontAwesomeIcons.apple, size: 20),
                    label: Text(AppLocalizations.of(context)!.signInWithApple),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider(color: AppTheme.borderColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  AppLocalizations.of(context)!.or,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
              const Expanded(child: Divider(color: AppTheme.borderColor)),
            ],
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.email,
                    hintText: AppLocalizations.of(context)!.emailHint,
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterEmail;
                    }
                    if (!value.contains('@')) {
                      return AppLocalizations.of(context)!
                          .pleaseEnterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                    hintText: AppLocalizations.of(context)!.passwordHint,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 300 ||
                        MediaQuery.sizeOf(context).width < 340;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() => _rememberMe = value ?? false);
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.rememberMe,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => context.push('/forgot-password'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.forgotPassword,
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(
                                      () => _rememberMe = value ?? false);
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.rememberMe,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => context.push('/forgot-password'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.forgotPassword,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.signIn,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.dontHaveAccount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => context.push('/register'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            AppLocalizations.of(context)!.createAccount,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EnhancedMeshPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _EnhancedMeshPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 80.0;

    // Diagonal lines for more visual interest
    final diagonalPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;

    // Vertical and horizontal grid
    final gridPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;

    // Draw diagonal lines
    for (double i = -size.height;
        i < size.width + size.height;
        i += spacing * 1.5) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        diagonalPaint,
      );
    }

    // Draw grid
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
