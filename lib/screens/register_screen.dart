import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/social_auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';
import '../utils/password_validator.dart';
import 'package:tripoli_explorer/l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ok = await authProvider.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (ok) {
        if (authProvider.needsEmailVerification) {
          context.go('/verify-email');
        } else {
          final onboardingDone = authProvider.onboardingCompleted;
          context.go(onboardingDone ? '/explore' : '/language');
        }
      } else {
        final msg = authProvider.lastError ??
            'Registration failed. Email may already be in use.';
        AppSnackBars.showError(context, msg);
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
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
          context
              .go(authProvider.onboardingCompleted ? '/explore' : '/language');
        } else {
          AppSnackBars.showError(
              context, authProvider.lastError ?? 'Sign-up failed');
        }
      }
    } else if (result.error != null &&
        result.error != 'Sign-in cancelled' &&
        mounted) {
      AppSnackBars.showError(context, result.error!);
    }
  }

  Future<void> _handleAppleSignUp() async {
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
          context
              .go(authProvider.onboardingCompleted ? '/explore' : '/language');
        } else {
          AppSnackBars.showError(
              context, authProvider.lastError ?? 'Sign-up failed');
        }
      }
    } else if (result.error != null &&
        result.error != 'Sign-in cancelled' &&
        mounted) {
      AppSnackBars.showError(context, result.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Decorative background with inverted colors
          _buildBackground(context),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppTheme.surfaceVariant.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildRegisterCard(context),
                  const SizedBox(height: 24),
                  _buildSignInLink(context),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
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
            // Inverted gradient: accent first, then primary
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.accentColor.withValues(alpha: 0.12),
                AppTheme.backgroundColor,
                AppTheme.primaryColor.withValues(alpha: 0.10),
                AppTheme.successColor.withValues(alpha: 0.06),
                AppTheme.secondaryColor.withValues(alpha: 0.04),
              ],
              stops: const [0.0, 0.3, 0.55, 0.75, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Large animated blob top-right - accent color (inverted)
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
                        AppTheme.accentColor
                            .withValues(alpha: 0.18 * glowIntensity),
                        AppTheme.accentColor
                            .withValues(alpha: 0.12 * glowIntensity),
                        AppTheme.accentColor
                            .withValues(alpha: 0.06 * glowIntensity),
                        AppTheme.accentColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor
                            .withValues(alpha: 0.15 * glowIntensity),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              // Large animated blob bottom-left - primary color (inverted)
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
                        AppTheme.primaryColor
                            .withValues(alpha: 0.16 * glowIntensity),
                        AppTheme.primaryColor
                            .withValues(alpha: 0.10 * glowIntensity),
                        AppTheme.primaryColor
                            .withValues(alpha: 0.05 * glowIntensity),
                        AppTheme.primaryColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor
                            .withValues(alpha: 0.12 * glowIntensity),
                        blurRadius: 35,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              // Medium circle mid-right - success color (inverted)
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
                        AppTheme.successColor.withValues(alpha: 0.14),
                        AppTheme.successColor.withValues(alpha: 0.08),
                        AppTheme.successColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
              // Small accent circle top-center - secondary color (inverted)
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
                        AppTheme.secondaryColor.withValues(alpha: 0.12),
                        AppTheme.secondaryColor.withValues(alpha: 0.06),
                        AppTheme.secondaryColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.08),
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
              // Enhanced mesh overlay with inverted colors
              Positioned.fill(
                child: CustomPaint(
                  painter: _EnhancedMeshPainter(
                    primaryColor: AppTheme.accentColor.withValues(alpha: 0.03),
                    accentColor: AppTheme.primaryColor.withValues(alpha: 0.02),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join Visit Tripoli to save places, plan trips, and discover the Pearl of the North.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleGoogleSignUp,
              icon: const FaIcon(FontAwesomeIcons.google, size: 20),
              label: Text(AppLocalizations.of(context)!.signUpWithGoogle),
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
                    onPressed: _isLoading ? null : _handleAppleSignUp,
                    icon: const FaIcon(FontAwesomeIcons.apple, size: 20),
                    label: Text(AppLocalizations.of(context)!.signUpWithApple),
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
                  'or create with email',
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
                _buildInput(
                  controller: _nameController,
                  label: 'Full name',
                  hint: 'e.g. Ahmed Al-Sharif',
                  icon: Icons.person_outline_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your name';
                    final name = v.trim();
                    if (name.length < 2) return 'Name must be at least 2 characters';
                    if (name.length > 40) return 'Name must be 40 characters or fewer';
                    // Allow letters (including Arabic/accented), spaces, hyphens, apostrophes
                    final validChars = RegExp(r"^[\p{L}\s'\-]+$", unicode: true);
                    if (!validChars.hasMatch(name)) return 'Name can only contain letters, spaces, hyphens and apostrophes';
                    // Must have at least 2 letters
                    final letterCount = name.runes.where((r) => RegExp(r'\p{L}', unicode: true).hasMatch(String.fromCharCode(r))).length;
                    if (letterCount < 2) return 'Enter a valid full name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildInput(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildInput(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '8+ chars, upper, lower, number, special (!@#\$)',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    return PasswordValidator.validate(v);
                  },
                ),
                const SizedBox(height: 16),
                _buildInput(
                  controller: _confirmPasswordController,
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleRegister,
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create account',
                            style: TextStyle(
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

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildSignInLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Sign in',
            style: TextStyle(
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
