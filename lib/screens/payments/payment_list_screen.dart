import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/student.dart';
import '../../services/printer_service.dart';
import 'student_payment_detail_screen.dart';
import 'report_preview_screen.dart';
import '../../config/constants.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PaymentProvider>().loadPayments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _studentFullName(Map<String, dynamic> row) {
    final postName = (row['postName'] as String?) ?? '';
    final last = row['lastName'] as String;
    final first = row['firstName'] as String;
    if (postName.isEmpty) return '$last $first';
    return '$last $postName $first';
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> all, PaymentProvider provider) {
    var list = all;
    
    // search filter
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((p) => _studentFullName(p).toLowerCase().contains(q)).toList();
    }
    
    // promotion filter (based on actual classId from _studentClassMap)
    if (provider.promotionFilter != 'all') {
      list = list.where((p) {
        final studentId = p['studentId'] as String;
        final classId = provider.studentClassMap[studentId];
        return classId == provider.promotionFilter;
      }).toList();
    }
    
    // status filter
    if (provider.statusFilter != 'all') {
      final fullyPaid = provider.statusFilter == 'fully_paid';
      list = list.where((p) {
        final isFP = provider.isFullyPaid(p['studentId'] as String);
        return fullyPaid ? isFP : !isFP;
      }).toList();
    }
    
    return list;
  }

  // ─── Open Payment Detail ──────────────────────────────────────────────────
  
  void _openPaymentDetail(Student student) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentPaymentDetailScreen(student: student),
      ),
    );
    if (!mounted) return;
    context.read<PaymentProvider>().loadPayments();
  }

  // ─── Print Report ─────────────────────────────────────────────────────────

  void _printReport(PaymentProvider provider) {
    double totalUnpaid = 0;
    final monthlyRows = provider.payments.where((p) => p['feeType'] == 'monthly').toList();
    for (var row in monthlyRows) {
      if (!provider.isFullyPaid(row['studentId'] as String)) {
        totalUnpaid += (row['amount'] as num).toDouble();
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          monthLabel: PaymentProvider.periodLabel(provider.currentPeriod),
          rows: monthlyRows,
          provider: provider,
          totalCollected: provider.totalRevenue,
          unpaidCount: provider.unpaidCount,
          totalUnpaidAmount: totalUnpaid,
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, provider, _) {
        final filtered = _filtered(provider.payments, provider);
        final paidCount = provider.paidCount;
        final totalCount = provider.totalMonthlyCount;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paiements', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  PaymentProvider.periodLabel(provider.currentPeriod),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Mois précédent',
                onPressed: provider.previousMonth,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Mois suivant',
                onPressed: provider.nextMonth,
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Stats banner ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        label: 'Payés',
                        value: '$paidCount / $totalCount',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        label: 'Revenus',
                        value: '${provider.totalRevenue.toStringAsFixed(2)} \$',
                        icon: Icons.attach_money,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        label: 'Impayés',
                        value: '${provider.unpaidCount}',
                        icon: Icons.warning_amber,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Filters ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un étudiant…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.school),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: provider.promotionFilter,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('Toutes les promotions')),
                        ...provider.availableClasses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (val) {
                        if (val != null) provider.setPromotionFilter(val);
                      },
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Tous'),
                            selected: provider.statusFilter == 'all',
                            onSelected: (val) { if (val) provider.setStatusFilter('all'); },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Payé intégralement'),
                            selected: provider.statusFilter == 'fully_paid',
                            onSelected: (val) { if (val) provider.setStatusFilter('fully_paid'); },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Impayé'),
                            selected: provider.statusFilter == 'unpaid',
                            onSelected: (val) { if (val) provider.setStatusFilter('unpaid'); },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── List ─────────────────────────────────────────────────────
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(child: Text('Aucun paiement trouvé.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final row = filtered[index];
                              final name = _studentFullName(row);
                              final isFullyPaid = provider.isFullyPaid(row['studentId'] as String);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    final student = Student(
                                      id: row['studentId'] as String,
                                      firstName: row['firstName'] as String,
                                      lastName: row['lastName'] as String,
                                      postName: (row['postName'] as String?) ?? '',
                                      email: '',
                                      phone: (row['phone'] as String?) ?? '',
                                      currentLevel: row['currentLevel'] as String? ?? '',
                                      enrollmentDate: DateTime.now(),
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    );
                                    _openPaymentDetail(student);
                                  },
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isFullyPaid ? Colors.green : Colors.red,
                                      child: Icon(
                                        isFullyPaid ? Icons.check : Icons.close,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      isFullyPaid ? 'Payé intégralement' : 'Impayé',
                                      style: TextStyle(color: isFullyPaid ? Colors.green : Colors.red),
                                    ),
                                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 8,
                )
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.print),
              label: const Text('Imprimer le rapport', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              onPressed: () => _printReport(provider),
            ),
          ),
        );
      },
    );
  }
}

// ─── Small stat chip ─────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: color)),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

