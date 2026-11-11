import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'storage/profile_store.dart';
import 'ui/home/home_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/results/results_screen.dart';
import 'ui/session/session_screen.dart';
import 'ui/theme/theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final hasProfile = ref.read(profileProvider) != null;
      final onboarding = state.matchedLocation == '/onboarding';
      if (!hasProfile && !onboarding) return '/onboarding';
      if (hasProfile && onboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/session', builder: (_, _) => const SessionScreen()),
      GoRoute(path: '/results', builder: (_, _) => const ResultsScreen()),
    ],
  );
});

class LockInApp extends ConsumerWidget {
  const LockInApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(settingsProvider.select((s) => s.reduceMotion));
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return MaterialApp.router(
      title: 'Lock In',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // Honour the system setting OR the in-app toggle.
        return MediaQuery(
          data: mq.copyWith(disableAnimations: mq.disableAnimations || reduceMotion),
          child: child!,
        );
      },
    );
  }
}
