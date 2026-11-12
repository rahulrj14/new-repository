import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'storage/profile_store.dart';
import 'ui/home/home_tab.dart';
import 'ui/me/me_tab.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/results/results_screen.dart';
import 'ui/session/session_screen.dart';
import 'ui/share/share_screen.dart';
import 'ui/shell.dart';
import 'ui/squad/host_screen.dart';
import 'ui/squad/join_screen.dart';
import 'ui/streak/streak_tab.dart';
import 'ui/wrapped/wrapped_screen.dart';
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomeTab())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/streak', builder: (_, _) => const StreakTab()),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/me', builder: (_, _) => const MeTab())],
          ),
        ],
      ),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/session', builder: (_, _) => const SessionScreen()),
      GoRoute(path: '/results', builder: (_, _) => const ResultsScreen()),
      GoRoute(path: '/share', builder: (_, _) => const ShareScreen()),
      GoRoute(path: '/squad/host', builder: (_, _) => const HostScreen()),
      GoRoute(path: '/squad/join', builder: (_, _) => const JoinScreen()),
      GoRoute(path: '/wrapped', builder: (_, _) => const WrappedScreen()),
    ],
  );
});

class LockInApp extends ConsumerWidget {
  const LockInApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(
      settingsProvider.select((s) => s.reduceMotion),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp.router(
        title: 'Lock In',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        themeMode: ThemeMode.light,
        routerConfig: ref.watch(routerProvider),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          // Honour the system setting OR the in-app toggle.
          return MediaQuery(
            data: mq.copyWith(
              disableAnimations: mq.disableAnimations || reduceMotion,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
