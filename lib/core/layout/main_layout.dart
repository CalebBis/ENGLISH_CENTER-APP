import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sidebar.dart';
import '../widgets/window_title_bar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Obtenir l'emplacement actuel pour la mise en évidence dans la barre latérale
    final String location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: Column(
        children: [
          const WindowTitleBar(),
          Expanded(
            child: Row(
              children: [
                Sidebar(currentPath: location),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
