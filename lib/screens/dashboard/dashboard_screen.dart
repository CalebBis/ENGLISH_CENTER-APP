import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../teachers/teacher_list_screen.dart';
import '../classes/class_list_screen.dart';
import '../students/student_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de Bord')),
      drawer: _buildDrawer(context),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bienvenue!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Tableau de bord du centre d\'anglais'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Statistiques Clés', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildStatCard('Étudiants Actifs', '${provider.totalStudents}', Colors.blue, Icons.people),
                    _buildStatCard('Nouveaux', '${provider.newStudentsThisMonth}', Colors.green, Icons.person_add),
                    _buildStatCard('Présence', '${provider.attendanceRate.toInt()}%', Colors.orange, Icons.check_circle),
                    _buildStatCard('Impayés', '${provider.unpaidCount}', Colors.red, Icons.warning),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2196F3)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(radius: 32, child: Icon(Icons.person, size: 40)),
                SizedBox(height: 12),
                Text('Admin User',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'Tableau de Bord', () => Navigator.pop(context)),
          _buildDrawerItem(Icons.people, 'Étudiants', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentListScreen()),
            );
          }),
          _buildDrawerItem(Icons.school, 'Classes', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClassListScreen()),
            );
          }),
          _buildDrawerItem(Icons.person_pin, 'Enseignants', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeacherListScreen()),
            );
          }),
          _buildDrawerItem(Icons.payment, 'Paiements', () => Navigator.pop(context)),
          _buildDrawerItem(Icons.check_circle, 'Présence', () => Navigator.pop(context)),
          _buildDrawerItem(Icons.assessment, 'Examens', () => Navigator.pop(context)),
          _buildDrawerItem(Icons.bar_chart, 'Rapports', () => Navigator.pop(context)),
          const Divider(),
          _buildDrawerItem(Icons.settings, 'Paramètres', () => Navigator.pop(context)),
          _buildDrawerItem(Icons.logout, 'Déconnexion', () => Navigator.pop(context)),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }
}
