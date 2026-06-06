import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatelessWidget {
  final String currentPath;

  const Sidebar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 250,
      color: colorScheme.surface,
      child: Column(
        children: [
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.language, size: 40, color: colorScheme.primary),
                const SizedBox(height: 8),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard,
                  title: 'Tableau de bord',
                  isSelected: currentPath == '/dashboard',
                  onTap: () => context.go('/dashboard'),
                ),
                _SidebarItem(
                  icon: Icons.people,
                  title: 'Étudiants',
                  isSelected: currentPath == '/students',
                  onTap: () => context.go('/students'),
                ),
                _SidebarItem(
                  icon: Icons.class_,
                  title: 'Classes & Niveaux',
                  isSelected: currentPath == '/classes',
                  onTap: () => context.go('/classes'),
                ),
                _SidebarItem(
                  icon: Icons.person_pin,
                  title: 'Enseignants',
                  isSelected: currentPath == '/teachers',
                  onTap: () => context.go('/teachers'),
                ),
                _SidebarItem(
                  icon: Icons.payment,
                  title: 'Paiements',
                  isSelected: currentPath == '/payments',
                  onTap: () => context.go('/payments'),
                ),
                _SidebarItem(
                  icon: Icons.fact_check,
                  title: 'Présences',
                  isSelected: currentPath == '/attendance',
                  onTap: () => context.go('/attendance'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: () => context.go('/login'),
            ),
          ),
        ],
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
