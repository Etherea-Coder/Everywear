import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/providers.dart';
import './home_screen/home_screen.dart';
import './welcome_philosophy/welcome_philosophy.dart';
import './splash_screen/splash_screen.dart';
import './password_reset/password_reset_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(supabaseAuthProvider);
  if (user == null) return false;
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasSeenOnboarding:${user.id}') ?? false;
});

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
        final onboardLocalAsync = ref.watch(hasSeenOnboardingProvider);

        return profileAsync.when(
          data: (profile) {
            final isComplete = profile?['onboarding_completed'] ?? false;
            if (isComplete) return const HomeScreen();

            return onboardLocalAsync.when(
              data: (localComplete) {
                if (localComplete) return const HomeScreen();
                return const WelcomePhilosophy();
              },
              loading: () => const _GateLoadingScreen(),
              error: (_, __) => const WelcomePhilosophy(),
            );
          },
          loading: () => const _GateLoadingScreen(),
          error: (err, stack) {
            return onboardLocalAsync.when(
              data: (localComplete) {
                if (localComplete) return const HomeScreen();
                return const WelcomePhilosophy();
              },
              loading: () => const _GateLoadingScreen(),
              error: (_, __) => const WelcomePhilosophy(),
            );
          },
        );
      },
      loading: () => const _GateLoadingScreen(),
      error: (err, stack) => const SplashScreen(),
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
