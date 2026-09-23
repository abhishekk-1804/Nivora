import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/preference_keys.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nivora_logo.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../../main.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // Guard flag - prevents double-navigation if widget rebuilds unexpectedly.
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Hold the branded splash for exactly 2 seconds for brand impression.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final prefs = await SharedPreferences.getInstance();
    final hasOnboarded = prefs.getBool(PreferenceKeys.hasOnboarded) ?? false;

    if (!mounted) return;

    // Signal that splash screen is done so NivoraApp can trigger App Lock
    ref.read(splashScreenDoneProvider.notifier).setDone();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            hasOnboarded ? const MainNavigation() : const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.warmIvory,
        extendBody: true,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // ── Nivora geometric logo (Static to perfectly match Native OS Splash) ──
            const Center(
              child: NivoraLogo(size: 72),
            ),

            // ── "Nivora" wordmark in elegant italic serif ─────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 110), // Offset from center
                child: const Text(
                  'nivora health',
                  style: TextStyle(
                    fontFamily: 'FleurDeLeah',
                    fontSize: 56,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandAction,
                    height: 1.0,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 600),
                    )
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                    ),
              ),
            ),
          ],
        ));
  }
}
