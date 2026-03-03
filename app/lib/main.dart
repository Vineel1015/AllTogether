import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/api_constants.dart';
import 'core/utils/cache_utils.dart';
import 'core/widgets/loading_indicator.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/customizations/providers/preferences_provider.dart';
import 'features/customizations/screens/customizations_screen.dart';
import 'shared/app_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Supabase ─────────────────────────────────────────────────────────────
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );

  // ── Hive local cache ──────────────────────────────────────────────────────
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<String>(ApiConstants.mealPlanCacheBox),
    Hive.openBox<String>(ApiConstants.foodItemCacheBox),
    Hive.openBox<String>(ApiConstants.placesCacheBox),
    Hive.openBox<String>(ApiConstants.climatiqCacheBox),
  ]);

  // Evict expired cache entries in the background (non-blocking).
  unawaited(evictExpiredEntries(Hive.box<String>(ApiConstants.foodItemCacheBox)));

  runApp(const ProviderScope(child: AllTogetherApp()));
}

class AllTogetherApp extends StatelessWidget {
  const AllTogetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AllTogether',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4C0089), // Dark Blue
          primary: const Color(0xFF4C0089),   // Dark Blue → FilledButton bg
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFB0CE6F), // June Bud → banners/chips
          onPrimaryContainer: const Color(0xFF1A003D),
          secondary: const Color(0xFFB0CE6F), // June Bud
          onSecondary: const Color(0xFF1A003D),
          surface: Colors.white,
          error: const Color(0xFFFF5E33),     // Portland Orange → errors
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFEFE8D3), // White Chocolate
        useMaterial3: true,
        fontFamily: 'AlteHaasGrotesk',

        // ── Buttons ──────────────────────────────────────────────────────────
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),

        // ── Cards ─────────────────────────────────────────────────────────────
        cardTheme: const CardThemeData(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),

        // ── Inputs ────────────────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),

        // ── AppBar ────────────────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Routes between login, onboarding, and the main app based on auth state.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (authState) {
        final session = authState.session;
        if (session == null) return const LoginScreen();
        return const _MainAppRouter();
      },
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (_, __) => const LoginScreen(),
    );
  }
}

/// Plain background shown while the onboarding preferences modal is open.
///
/// [CustomizationsScreen] opens the modal automatically; this widget provides
/// the scaffold underneath it so the navigator is valid.
class _OnboardingGate extends StatelessWidget {
  const _OnboardingGate();

  @override
  Widget build(BuildContext context) {
    return const CustomizationsScreen(isOnboarding: true);
  }
}

/// After login, checks whether preferences exist and routes accordingly.
class _MainAppRouter extends ConsumerWidget {
  const _MainAppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPreferencesProvider);

    return prefsAsync.when(
      data: (prefs) => prefs != null
          ? const AppScaffold()
          : const _OnboardingGate(),
      loading: () => const Scaffold(body: LoadingIndicator()),
      // On error, show the main app and let the user access preferences later.
      error: (_, __) => const AppScaffold(),
    );
  }
}
