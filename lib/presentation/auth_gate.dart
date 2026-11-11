import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import './home_screen/home_screen.dart';
import './welcome_philosophy/welcome_philosophy.dart';
import './splash_screen/splash_screen.dart';
import './password_reset/password_reset_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_session_service.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          return const PasswordResetScreen();
        }

        if (state.session == null) {
          return const SplashScreen();
        }

        final profileAsync = ref.watch(userProfileProvider);

        return profileAsync.when(
          data: (profile) {
            final isComplete = profile?['onboarding_completed'] ?? false;
            if (isComplete) return const HomeScreen();
            return const WelcomePhilosophy();
          },
          loading: () => const _GateLoadingScreen(),
          error: (err, stack) => _ProfileLoadError(
            onRetry: () {
              ref.invalidate(userProfileProvider);
            },
          ),
        );
      },
      loading: () => const _GateLoadingScreen(),
      error: (err, stack) => const SplashScreen(),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Your profile could not be loaded. Check your connection and retry.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await AuthSessionService.signOutCurrentUser();
                },
                child: Text(
                  'Sign out',
                  style: TextStyle(color: colors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateLoadingScreen extends StatelessWidget {
  const _GateLoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D5A27),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Aligning your style...',
              style: TextStyle(
                color: Colors.white.withAlpha(204),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
