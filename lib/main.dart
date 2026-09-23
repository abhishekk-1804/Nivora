import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/today/presentation/today_screen.dart';
import 'features/report/presentation/report_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'core/notifications/notification_service.dart';
import 'core/diagnostics/error_logger.dart';
import 'dart:ui';
import 'core/widgets/nivora_logo.dart';
import 'core/services/auth_service.dart';
import 'core/constants/preference_keys.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/preferences_provider.dart';
import 'core/providers/database_provider.dart';

void main() async {
  // We are removing FlutterNativeSplash.preserve() to fix the deadlock with biometric prompt.
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce zero network font fetching at runtime
  GoogleFonts.config.allowRuntimeFetching = false;

  // 1. Flutter Framework Errors (Render/Widget build errors)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ErrorLogger.error(
      'FlutterError: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
  };

  // 2. Platform / Asynchronous Errors
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLogger.error('PlatformDispatcher Error: $error', error, stack);
    return true;
  };

  try {
    debugPrint('[INIT] Starting Initialization Sequence...');

    debugPrint('[INIT] Initializing Notifications...');
    await NotificationService.init();
    debugPrint('[INIT] Notifications Initialized successfully.');

    ErrorLogger.info('App Initialized');
  } catch (e, stack) {
    debugPrint('[INIT ERROR] Initialization failed: $e');
    ErrorLogger.error('Initialization Error', e, stack);
  }
  // NOTE: FlutterNativeSplash.remove() is intentionally NOT called here.
  // It is called inside SplashScreen.initState() so the handoff is seamless.

  // Load SharedPreferences synchronously before app starts
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const NivoraApp(),
    ),
  );
}

// Used to manage the transition from splash screen to main content
// Needs to be outside any specific feature so main.dart can observe it.
class SplashScreenDoneNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setDone() => state = true;
}

final splashScreenDoneProvider =
    NotifierProvider<SplashScreenDoneNotifier, bool>(SplashScreenDoneNotifier.new);

class NivoraApp extends ConsumerStatefulWidget {
  const NivoraApp({super.key});

  @override
  ConsumerState<NivoraApp> createState() => _NivoraAppState();
}

class _NivoraAppState extends ConsumerState<NivoraApp> with WidgetsBindingObserver {
  bool _obscureUI = false; // Default to false until we know app lock is enabled
  bool _isAuthenticating = false;
  bool _deviceSecurityMissing = false;

  DateTime? _backgroundedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppLockSetting();
  }

  Future<void> _loadAppLockSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final isLocked = prefs.getBool(PreferenceKeys.appLockEnabled) ?? false;
    final hasOnboarded = prefs.getBool(PreferenceKeys.hasOnboarded) ?? false;
    if (!mounted) return;

    // Only prompt biometrics if onboarding is complete; never lock mid-onboarding.
    if (isLocked && hasOnboarded) {
      setState(() => _obscureUI = true);
      // We don't call _authenticate() immediately here.
      // We wait for the splash screen to finish via splashScreenDoneProvider.
    }
  }

  Future<void> _authenticate() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final appLockEnabled = prefs.getBool(PreferenceKeys.appLockEnabled) ?? false;
    final hasOnboarded = prefs.getBool(PreferenceKeys.hasOnboarded) ?? false;

    if (_isAuthenticating || !appLockEnabled || !hasOnboarded) return;

    setState(() {
      _isAuthenticating = true;
      _obscureUI = true;
    });

    final result = await AuthService.authenticate();

    if (mounted) {
      setState(() {
        _obscureUI = result != AuthResult.success;
        _deviceSecurityMissing = result == AuthResult.missingSecurity;
      });
      
      // Delay resetting the authenticating flag by 500ms.
      // This absorbs any rogue AppLifecycleState.inactive events that the OS 
      // might fire while dismissing the native biometric prompt window, 
      // preventing the app from instantly locking itself again.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isAuthenticating = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prefs = ref.read(sharedPreferencesProvider);
    final appLockEnabled = prefs.getBool(PreferenceKeys.appLockEnabled) ?? false;
    final hasOnboarded = prefs.getBool(PreferenceKeys.hasOnboarded) ?? false;

    if (!appLockEnabled || !hasOnboarded) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (!_isAuthenticating) {
        _backgroundedTime = DateTime.now();
        setState(() {
          _obscureUI = true;
        });
      } else if (state == AppLifecycleState.paused) {
        AuthService.stopAuthentication();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Rehydrate routine notifications (moving window)
      ref.read(routineDaoProvider).getActiveRoutines().then((routines) {
        NotificationService.rehydrateRoutineNotifications(routines);
      });

      if (_isAuthenticating) return;

      if (_backgroundedTime != null) {
        final diff = DateTime.now().difference(_backgroundedTime!);
        _backgroundedTime = null; // Clear it so we don't trigger again when the prompt closes
        
        // Only lock if backgrounded for more than 10 seconds
        if (diff.inSeconds > 10) {
          _authenticate();
        } else {
          setState(() {
            _obscureUI = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(splashScreenDoneProvider, (previous, current) {
      final prefs = ref.read(sharedPreferencesProvider);
      final appLockEnabled = prefs.getBool(PreferenceKeys.appLockEnabled) ?? false;
      final hasOnboarded = prefs.getBool(PreferenceKeys.hasOnboarded) ?? false;
      
      if (current == true && appLockEnabled && hasOnboarded) {
        // Wait for the pushReplacement animation (500ms) to finish before showing prompt.
        // Android cancels BiometricPrompt if launched during a window transition!
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _authenticate();
        });
      }
    });

    final isSplashDone = ref.watch(splashScreenDoneProvider);
    final shouldObscure = _obscureUI && isSplashDone;

    return MaterialApp(
      title: 'Nivora',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // SplashScreen is always the entry point; it reads SharedPreferences
      // and routes to OnboardingScreen or MainNavigation after the 2-second hold.
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            if (shouldObscure)
              GestureDetector(
                onTap: () {
                  if (!_isAuthenticating) {
                    _authenticate();
                  }
                },
                child: Container(
                  color: AppColors.warmIvory,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const NivoraLogo(size: 80),
                        if (!_isAuthenticating) ...[
                          const SizedBox(height: 24),
                          if (_deviceSecurityMissing)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Device Security Disabled: Please set up a phone passcode to unlock Nivora.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            const Text(
                              'Tap to unlock',
                              style: TextStyle(
                                color: AppColors.charcoalInk,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TodayScreen(onNavigateToSettings: () => setState(() => _currentIndex = 2)),
      const ReportScreen(),
      const SettingsScreen(),
    ];

    // Ensure notifications are requested for users who upgraded 
    // from an older version and skipped onboarding.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final granted = await NotificationService.requestPermission();
      if (granted) {
        // Re-schedule everything now that we have permission
        ref.read(routineDaoProvider).getActiveRoutines().then((routines) {
          NotificationService.rehydrateRoutineNotifications(routines);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.warmIvory,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.softLavender.withValues(alpha: 0.3),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: AppLocalizations.of(context)!.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined),
            selectedIcon: const Icon(Icons.analytics),
            label: AppLocalizations.of(context)!.tabInsights,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settingsTitle,
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias for tests
typedef ImyraApp = NivoraApp;
