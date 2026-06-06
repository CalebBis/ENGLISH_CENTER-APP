import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_providers.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tableau de bord',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.refresh(dashboardStatsProvider),
              ),
            ],
          ),
          const SizedBox(height: 32),
          statsAsync.when(
            data: (stats) {
              final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
              return Column(
                children: [
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Erreur: $e')),
          ),
          const SizedBox(height: 32),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
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
