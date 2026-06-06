import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: Theme.of(context).colorScheme.primary,
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.school, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            'Gestion Centre d\'Anglais',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Expanded(child: DragToMoveArea(child: SizedBox.expand())),
          Row(
            children: [
              WindowCaptionButton.minimize(
                brightness: Brightness.dark,
                onPressed: () async => await windowManager.minimize(),
              ),
              WindowCaptionButton.maximize(
                brightness: Brightness.dark,
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
              ),
              WindowCaptionButton.close(
                brightness: Brightness.dark,
                onPressed: () async => await windowManager.close(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
