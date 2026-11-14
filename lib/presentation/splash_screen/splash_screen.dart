import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/supabase_service.dart';
import '../../services/revenuecat_service.dart';
import '../../services/auth_redirects.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'dart:async';
import '../../core/app_export.dart';

/// Splash Screen with Authentication - Branded login experience
/// Displays app logo with authentication options (Google & Email)
/// Provides seamless sign-in/sign-up flow with elegant design
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showAuthOptions = false;
  bool _showEmailForm = false;
  bool _isSignUp = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _listenToAuthChanges();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_showAuthOptions) {
        setState(() => _showAuthOptions = true);
      }
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _listenToAuthChanges() {
    if (!SupabaseService.isInitialized) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ SplashScreen: Supabase not initialized, skipping auth listener',
        );
      }
      return;
    }

    _authSubscription = SupabaseService.instance.client.auth.onAuthStateChange
        .listen((data) {
          if (!mounted) return;
          // Only react to explicit sign-in — ignore tokenRefreshed, initialSession, etc.
          if (data.event == AuthChangeEvent.signedIn && data.session != null) {
            unawaited(RevenueCatService.logIn(data.session!.user.id));
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: theme.colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: _showEmailForm
                ? _buildEmailAuthForm(theme, l10n)
                : _buildMainAuthScreen(theme, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildMainAuthScreen(ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          children: [
            SizedBox(height: 8.h),
            _buildBrandingSection(theme, l10n),
            SizedBox(height: _showAuthOptions ? 6.h : 12.h),
            if (_showAuthOptions) ...[
              _buildAuthOptionsSection(theme, l10n),
            ] else ...[
              _buildLoadingIndicator(theme),
            ],
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingSection(ThemeData theme, AppLocalizations l10n) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildLogo(theme),
          SizedBox(height: 3.h),
          Text(
            l10n.appName,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20.sp,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            l10n.appTagline,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
              fontSize: 14.sp,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/splash-screen.png',
            width: 90.w,
            height: 90.w,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildAuthOptionsSection(ThemeData theme, AppLocalizations l10n) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildGoogleSignInButton(theme, l10n),
            SizedBox(height: 3.h),
            _buildDivider(theme, l10n),
            SizedBox(height: 3.h),
            _buildEmailSignInButton(theme, l10n),
            SizedBox(height: 3.h),
            _buildTermsText(theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(ThemeData theme, AppLocalizations l10n) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isLoading ? null : _handleGoogleSignIn,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/google_logo.svg',
                width: 6.w,
                height: 6.w,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 3.w),
              Text(
                l10n.continueGoogle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailSignInButton(ThemeData theme, AppLocalizations l10n) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : () => setState(() => _showEmailForm = true),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.5),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                color: theme.colorScheme.onPrimary,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                l10n.continueEmail,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            l10n.orDivider,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsText(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        l10n.termsPrivacyAgreement,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          fontSize: 11.sp,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildEmailAuthForm(ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(6.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),
            _buildBackButton(theme),
            SizedBox(height: 4.h),
            _buildFormHeader(theme, l10n),
            SizedBox(height: 4.h),
            if (_isSignUp) ...[
              _buildTextField(
                controller: _nameController,
                label: l10n.labelFullName,
                icon: Icons.person_outline,
                theme: theme,
                validator: (value) {
                  if (value?.isEmpty ?? true) return l10n.nameRequired;
                  return null;
                },
              ),
              SizedBox(height: 2.h),
            ],
            _buildTextField(
              controller: _emailController,
              label: l10n.email,
              icon: Icons.email_outlined,
              theme: theme,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) return l10n.emailRequired;
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value!)) {
                  return l10n.emailInvalid;
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            _buildTextField(
              controller: _passwordController,
              label: l10n.password,
              icon: Icons.lock_outline,
              theme: theme,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return l10n.passwordRequired;
                if (value!.length < 6) {
                  return l10n.passwordMinLengthMsg;
                }
                return null;
              },
            ),
            if (!_isSignUp) ...[
              SizedBox(height: 1.h),
              _buildForgotPasswordButton(theme, l10n),
            ],
            SizedBox(height: 2.h),
            _buildSubmitButton(theme, l10n),
            SizedBox(height: 2.h),
            _buildToggleAuthMode(theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(ThemeData theme) {
    return IconButton(
      onPressed: () => setState(() {
        _showEmailForm = false;
        _formKey.currentState?.reset();
      }),
      icon: Icon(
        Icons.arrow_back,
        color: theme.colorScheme.onPrimary,
        size: 6.w,
      ),
    );
  }

  Widget _buildFormHeader(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSignUp ? l10n.createAccountTitle : l10n.welcomeBackTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          _isSignUp ? l10n.signupSubtitle : l10n.signinSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 14.sp),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          fontSize: 13.sp,
        ),
        prefixIcon: Icon(
          icon,
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          size: 5.w,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.onPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton(ThemeData theme, AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading ? null : _handleForgotPassword,
        child: Text(
          l10n.forgotPassword,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorSnackBar('Please enter your email address first');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }

    if (!_ensureAuthServiceAvailable()) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: appAuthCallbackUri,
      );
      _showSuccessSnackBar('Password reset email sent!');
    } catch (e) {
      _showErrorSnackBar('Failed to send reset email: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSubmitButton(ThemeData theme, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleEmailAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.onPrimary,
          foregroundColor: theme.colorScheme.primary,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? SizedBox(
                height: 5.w,
                width: 5.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              )
            : Text(
                _isSignUp ? l10n.signupBtn : l10n.signinBtn,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleAuthMode(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: TextButton(
        onPressed: () => setState(() {
          _isSignUp = !_isSignUp;
          _formKey.currentState?.reset();
        }),
        child: RichText(
          text: TextSpan(
            text: _isSignUp ? l10n.alreadyHaveAccount : l10n.dontHaveAccount,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              fontSize: 13.sp,
            ),
            children: [
              TextSpan(
                text: _isSignUp ? l10n.signinBtn : l10n.signupBtn,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return SizedBox(
      width: 32.w,
      height: 32.w,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          theme.colorScheme.onPrimary.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context);
    if (!_ensureAuthServiceAvailable()) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: appAuthCallbackUri,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(l10n.googleSigninFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEmailAuth() async {
    final l10n = AppLocalizations.of(context);
    if (!_ensureAuthServiceAvailable()) return;

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await signUpWithEmailRedirect(
          auth: SupabaseService.instance.client.auth,
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          _showSuccessSnackBar(l10n.confirmEmailMsg);
        }
      } else {
        await SupabaseService.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showErrorSnackBar(e.message);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(_isSignUp ? l10n.signupFailed : l10n.signinFailed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _ensureAuthServiceAvailable() {
    if (SupabaseService.isInitialized) return true;
    _showErrorSnackBar(AppLocalizations.of(context).authServiceUnavailable);
    return false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
