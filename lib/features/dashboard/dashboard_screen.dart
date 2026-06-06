import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_providers.dart';
import 'package:intl/intl.dart';

/// Écran principal du tableau de bord (Dashboard).
///
/// Affiche en temps réel les statistiques clés du centre d'anglais,
/// récupérées depuis SQLite via [dashboardStatsProvider].
///
/// C'est un [ConsumerWidget] car il doit observer le provider de statistiques
/// et se reconstruire automatiquement quand les données changent.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// Construit le tableau de bord complet.
  ///
  /// - Observe [dashboardStatsProvider] pour les statistiques.
  /// - Affiche un [CircularProgressIndicator] pendant le chargement.
  /// - Affiche les cartes statistiques une fois les données disponibles.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observe le provider asynchrone des statistiques.
    // Se reconstruit à chaque changement (ajout d'étudiant, paiement, etc.).
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- EN-TÊTE : Titre + Bouton de rafraîchissement ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tableau de bord',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              /// Bouton d'actualisation manuelle des statistiques.
              /// [ref.refresh] force le rechargement du provider sans attendre
              /// une modification de la base de données.
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.refresh(dashboardStatsProvider),
              ),
            ],
          ),

          const SizedBox(height: 32),

          /// --- GRILLE DE STATISTIQUES ---
          /// Affichage réactif selon l'état du provider :
          statsAsync.when(
            /// CAS : données chargées → affiche les 8 cartes de statistiques.
            data: (stats) {
              // Formateur monétaire USD : "$1,234.56"
              final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

              return Column(
                children: [
                  /// Première rangée : statistiques sur les personnes.
                  Row(
                    children: [
                      Expanded(child: _StatCard(title: 'Total Étudiants', value: '${stats.totalStudents}', icon: Icons.people, color: Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(title: 'Étudiants Actifs', value: '${stats.activeStudents}', icon: Icons.person_pin_circle, color: Colors.teal)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(title: 'Classes', value: '${stats.totalClasses}', icon: Icons.class_, color: Colors.orange)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(title: 'Enseignants', value: '${stats.totalTeachers}', icon: Icons.school, color: Colors.deepPurple)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  /// Deuxième rangée : statistiques financières et de présence.
                  Row(
                    children: [
                      Expanded(child: _StatCard(title: 'Revenus Mensuels', value: currencyFormat.format(stats.monthlyRevenue), icon: Icons.attach_money, color: Colors.green)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(title: 'Revenus Annuels', value: currencyFormat.format(stats.annualRevenue), icon: Icons.account_balance_wallet, color: Colors.indigo)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(title: 'Paiements', value: '${stats.totalPayments}', icon: Icons.receipt_long, color: Colors.cyan)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(title: 'Taux de Présence', value: '${stats.attendanceRate.toStringAsFixed(1)}%', icon: Icons.fact_check, color: Colors.purple)),
                    ],
                  ),
                ],
              );
            },

            /// CAS : chargement → affiche un indicateur de progression circulaire.
            loading: () => const Center(child: CircularProgressIndicator()),

            /// CAS : erreur → affiche le message d'erreur.
            error: (e, st) => Center(child: Text('Erreur: $e')),
          ),

          const SizedBox(height: 32),

          /// Zone réservée pour de futurs graphiques d'activité récente.
          const Expanded(
            child: Card(
              child: Center(
                child: Text('Espace réservé pour l\'Activité Récente / Graphiques'),
              ),
            ),
          )
        ],
      ),
    );
  }
}

/// Widget de carte statistique réutilisable pour le tableau de bord.
///
/// Affiche une icône colorée à gauche et la valeur + le titre de la statistique à droite.
///
/// Paramètres :
/// - [title] : libellé de la statistique (ex: "Total Étudiants").
/// - [value] : valeur à afficher (ex: "42" ou "$1,500.00").
/// - [icon]  : icône Material représentant visuellement la statistique.
/// - [color] : couleur accent de la carte (icône + fond de cercle).
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  /// Construit une carte avec :
  /// - Un cercle coloré avec l'icône à gauche.
  /// - Le titre en gris clair et la valeur en gras à droite.
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            /// Cercle coloré contenant l'icône de la statistique.
            /// La couleur de fond est la couleur principale avec 10% d'opacité.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Fond très léger de la même couleur
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),

            const SizedBox(width: 16),

            /// Zone de texte avec le titre et la valeur.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Titre de la statistique en gris clair.
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),

                  /// Valeur principale en gras.
                  /// [FittedBox] réduit automatiquement la taille du texte si la valeur
                  /// est trop longue pour tenir dans la carte (ex: "$1,234,567.89").
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
