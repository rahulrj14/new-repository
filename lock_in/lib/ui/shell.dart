import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../storage/profile_store.dart';
import 'theme/tokens.dart';

/// Bottom tabs: Home, Streak, Me.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressValueProvider);
    final newSkins = p.unseenSkins.isNotEmpty;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x14111827),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.local_fire_department_rounded),
              label: p.streak.days > 0 ? '${p.streak.days} days' : 'Streak',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: newSkins,
                backgroundColor: LockColors.coral,
                child: const Icon(Icons.face_rounded),
              ),
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }
}
