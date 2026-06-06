import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'core/database/database_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Point d'entrée principal de l'application.
/// Configure SQLite (FFI pour Windows/Linux/macOS), initialise la base de
/// données, configure la fenêtre native Desktop, puis lance l'application.
void main() async {
  // Assure que les bindings Flutter sont prêts avant toute opération asynchrone.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser SQLite FFI pour les plateformes Desktop (Windows, Linux, macOS).
  // sqflite ne supporte pas nativement le Desktop, on utilise sqflite_common_ffi.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Ouvre (ou crée) la base de données SQLite au démarrage de l'application.
  // Cela garantit que toutes les tables existent avant que l'UI se charge.
  await DatabaseService.instance.database;

  // Configure la fenêtre native de l'application (taille, titre, barre de titre).
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // Définit les options de la fenêtre principale.
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),          // Taille initiale de la fenêtre
      minimumSize: Size(1024, 600),   // Taille minimale autorisée
      center: true,                   // Centre la fenêtre à l'écran
      backgroundColor: Colors.transparent,
      skipTaskbar: false,             // Affiche l'app dans la barre des tâches
      titleBarStyle: TitleBarStyle.hidden, // Cache la barre de titre native (custom)
      title: 'Gestion Centre d\'Anglais',
    );

    // Attend que la fenêtre soit prête, puis l'affiche et lui donne le focus.
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Lance l'application Flutter en enveloppant le widget racine dans ProviderScope.
  // ProviderScope est indispensable pour que Riverpod fonctionne dans toute l'app.
  runApp(
    const ProviderScope(
      child: EnglishCenterApp(),
    ),
  );
}

/// Widget racine de l'application.
/// Il s'agit d'un [ConsumerWidget] (Riverpod) car il doit accéder au provider
/// du routeur pour configurer la navigation.
class EnglishCenterApp extends ConsumerWidget {
  const EnglishCenterApp({super.key});

  /// Construit le widget MaterialApp.router qui utilise go_router pour la navigation.
  /// - [routerProvider] : fournit la configuration complète des routes de l'app.
  /// - [AppTheme.lightTheme] : applique le thème visuel global (couleurs, polices, etc.).
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observe le provider du routeur. Toute modification du routeur reconstruit ce widget.
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Centre d\'Anglais',
      debugShowCheckedModeBanner: false, // Supprime le bandeau rouge "DEBUG"
      theme: AppTheme.lightTheme,        // Thème visuel professionnel personnalisé
      routerConfig: router,              // Configuration du routeur go_router
    );
  }
}
