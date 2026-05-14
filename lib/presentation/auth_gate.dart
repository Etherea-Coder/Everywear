import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import './home_screen/home_screen.dart';
import './welcome_philosophy/welcome_philosophy.dart';
import './splash_screen/splash_screen.dart';
import './password_reset/password_reset_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AuthGate - Decides where to send the user after authentication
/// 
/// If onboarding_completed is true -> HomeScreen
/// If onboarding_completed is false or null -> WelcomePhilosophy (Onboarding)
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

        // User is authenticated, now check onboarding status
        return ref.watch(userProfileProvider).when(
          data: (profile) {
            final isComplete = profile?['onboarding_completed'] ?? false;
            
            if (isComplete) {
              return const HomeScreen();
            } else {
              return const WelcomePhilosophy();
            }
          },
          loading: () => const _GateLoadingScreen(),
          error: (err, stack) {
            // If profile check fails, default to onboarding to be safe
            return const WelcomePhilosophy();
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
