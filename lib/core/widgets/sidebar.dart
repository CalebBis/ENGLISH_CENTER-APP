import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Widget principal de la barre de navigation latérale (Sidebar).
///
/// Affiche :
/// - Le logo et le nom de l'application en haut.
/// - La liste des éléments de navigation (Dashboard, Étudiants, Classes, etc.).
/// - Un bouton de déconnexion en bas.
///
/// [currentPath] : le chemin de la route active, utilisé pour mettre en évidence
/// l'élément de navigation correspondant à la page courante.
class Sidebar extends StatelessWidget {
  /// Chemin de la route actuellement affichée (ex: '/dashboard', '/students').
  final String currentPath;

  const Sidebar({super.key, required this.currentPath});

  /// Construit la barre latérale complète.
  ///
  /// Structure verticale (Column) :
  /// 1. En-tête avec logo et titre.
  /// 2. Liste de navigation scrollable (Expanded + ListView).
  /// 3. Pied de page avec le bouton Déconnexion.
  @override
  Widget build(BuildContext context) {
    // Récupère les couleurs du thème actif pour adapter le rendu visuellement.
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 250, // Largeur fixe de la sidebar
      color: colorScheme.surface, // Fond blanc/clair selon le thème
      child: Column(
        children: [
          /// --- EN-TÊTE DE LA SIDEBAR ---
          /// Affiche l'icône de l'application et son nom.
          /// Une bordure inférieure le sépare du reste.
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Bordure basse séparant l'en-tête de la liste de navigation
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Icône représentant l'application (globe pour "langue").
                Icon(Icons.language, size: 40, color: colorScheme.primary),
                const SizedBox(height: 8),

                /// Nom de l'application affiché en gras.
                Text(
                  'Centre d\'Anglais',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          /// --- LISTE DE NAVIGATION ---
          /// S'étend pour occuper tout l'espace disponible entre l'en-tête et le pied de page.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                /// Élément de navigation vers le Tableau de bord.
                _SidebarItem(
                  icon: Icons.dashboard,
                  title: 'Tableau de bord',
                  isSelected: currentPath == '/dashboard',
                  onTap: () => context.go('/dashboard'),
                ),

                /// Élément de navigation vers la gestion des Étudiants.
                _SidebarItem(
                  icon: Icons.people,
                  title: 'Étudiants',
                  isSelected: currentPath == '/students',
                  onTap: () => context.go('/students'),
                ),

                /// Élément de navigation vers la gestion des Classes & Niveaux.
                _SidebarItem(
                  icon: Icons.class_,
                  title: 'Classes & Niveaux',
                  isSelected: currentPath == '/classes',
                  onTap: () => context.go('/classes'),
                ),

                /// Élément de navigation vers la gestion des Enseignants.
                _SidebarItem(
                  icon: Icons.person_pin,
                  title: 'Enseignants',
                  isSelected: currentPath == '/teachers',
                  onTap: () => context.go('/teachers'),
                ),

                /// Élément de navigation vers la gestion des Paiements.
                _SidebarItem(
                  icon: Icons.payment,
                  title: 'Paiements',
                  isSelected: currentPath == '/payments',
                  onTap: () => context.go('/payments'),
                ),

                /// Élément de navigation vers le registre des Présences.
                _SidebarItem(
                  icon: Icons.fact_check,
                  title: 'Présences',
                  isSelected: currentPath == '/attendance',
                  onTap: () => context.go('/attendance'),
                ),
              ],
            ),
          ),

          /// --- PIED DE PAGE : BOUTON DÉCONNEXION ---
          /// Séparé du reste par une bordure supérieure.
          /// Redirige vers la page de connexion quand l'utilisateur clique.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              /// Redirige vers la page de connexion (/login) pour déconnecter l'utilisateur.
              onTap: () => context.go('/login'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget interne représentant un élément cliquable de la liste de navigation.
///
/// Affiche une icône, un titre, et change de couleur/fond si l'élément est sélectionné.
///
/// Paramètres :
/// - [icon]       : l'icône à afficher à gauche du titre.
/// - [title]      : le texte du lien de navigation.
/// - [isSelected] : true si cet élément correspond à la page actuellement affichée.
/// - [onTap]      : action à exécuter quand l'utilisateur clique sur l'élément.
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  /// Construit un [ListTile] stylisé selon l'état de sélection.
  ///
  /// - Si [isSelected] : couleur primaire + fond coloré ([primaryContainer]).
  /// - Sinon : couleur neutre ([onSurfaceVariant]).
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      /// Icône colorée selon si l'élément est sélectionné ou non.
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),

      /// Titre avec style gras si sélectionné, normal sinon.
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),

      selected: isSelected,                           // Active la coloration de fond
      selectedTileColor: colorScheme.primaryContainer, // Couleur de fond de l'élément actif
      onTap: onTap,                                   // Navigation au clic
      contentPadding: const EdgeInsets.symmetric(horizontal: 24), // Marges internes
    );
  }
}
