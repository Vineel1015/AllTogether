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
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
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

/// After login, checks whether preferences exist and routes accordingly.
class _MainAppRouter extends ConsumerWidget {
  const _MainAppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPreferencesProvider);

    return prefsAsync.when(
      data: (prefs) => prefs != null
          ? const AppScaffold()
          : const CustomizationsScreen(isOnboarding: true),
      loading: () => const Scaffold(body: LoadingIndicator()),
      // On error, show the main app and let the user access preferences later.
      error: (_, __) => const AppScaffold(),
    );
  }
}
