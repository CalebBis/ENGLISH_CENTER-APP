import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../services/fee_settings_service.dart';
import '../../services/printer_service.dart';
import '../../models/student.dart';
import 'dart:math';

class StudentPaymentDetailScreen extends StatefulWidget {
  final Student student;

  const StudentPaymentDetailScreen({super.key, required this.student});

  @override
  State<StudentPaymentDetailScreen> createState() => _StudentPaymentDetailScreenState();
}

class _StudentPaymentDetailScreenState extends State<StudentPaymentDetailScreen> {
  bool _payInscription = false;
  bool _payMonthly = false;
  double _inscriptionFee = 0.0;
  double _monthlyFee = 0.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  void _loadFees() async {
    final iFee = await FeeSettingsService.instance.getInscriptionFee();
    final mFee = await FeeSettingsService.instance.getMonthlyFee();
    if (mounted) {
      setState(() {
        _inscriptionFee = iFee;
        _monthlyFee = mFee;
      });
    }
  }

  double get _totalAmount {
    double total = 0;
    if (_payInscription) total += _inscriptionFee;
    if (_payMonthly) total += _monthlyFee;
    return total;
  }

  Future<void> _processPayment(PaymentProvider provider, bool isMonthlyPaid, bool isInscriptionPaid) async {
    if (_totalAmount <= 0) return;
    setState(() => _isProcessing = true);

    try {
      List<Map<String, dynamic>> paidFees = [];

      if (_payInscription && !isInscriptionPaid) {
        await provider.processPayment(
          widget.student.id,
          'inscription',
          _inscriptionFee,
          'ONESHOT',
          paymentMethod: 'Espèces',
        );
        paidFees.add({'label': 'Frais d\'inscription', 'amount': _inscriptionFee});
      }

      if (_payMonthly && !isMonthlyPaid) {
        await provider.processPayment(
          widget.student.id,
          'monthly',
          _monthlyFee,
          provider.currentPeriod,
          paymentMethod: 'Espèces',
        );
        paidFees.add({'label': 'Mensuel (${PaymentProvider.periodLabel(provider.currentPeriod)})', 'amount': _monthlyFee});
      }

      final invoiceNumber = '${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}-${Random().nextInt(999)}';

      final printResult = await PrinterService.instance.printInvoiceReceipt(
        student: widget.student,
        paidFees: paidFees,
        totalAmount: _totalAmount,
        invoiceNumber: invoiceNumber,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement réussi. ${printResult.message}'),
          backgroundColor: printResult.success ? Colors.green : Colors.orange,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildPaidBadge(String dateStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Text(
            'Payé le $dateStr',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final d = DateTime.parse(isoString);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du paiement'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, _) {
          final inscription = provider.inscriptionPayments.firstWhere(
            (p) => p['studentId'] == widget.student.id,
            orElse: () => <String, dynamic>{},
          );
          final isInscriptionPaid = inscription.isNotEmpty && inscription['status'] == 'paid';
          final inscriptionDate = isInscriptionPaid ? _formatDate(inscription['paymentDate'] as String) : '';

          final monthly = provider.payments.firstWhere(
            (p) => p['studentId'] == widget.student.id && p['feeType'] == 'monthly' && p['periodMonth'] == provider.currentPeriod,
            orElse: () => <String, dynamic>{},
          );
          final isMonthlyPaid = monthly.isNotEmpty && monthly['status'] == 'paid';
          final monthlyDate = isMonthlyPaid ? _formatDate(monthly['paymentDate'] as String) : '';

          final allPaid = isInscriptionPaid && isMonthlyPaid;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Student Info Card ──────────────────────────
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(Icons.person, size: 30, color: Colors.blue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.student.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('Niveau : ${widget.student.currentLevel.isEmpty ? "Non défini" : widget.student.currentLevel}', style: TextStyle(color: Colors.grey.shade700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(widget.student.phone.isEmpty ? 'Non renseigné' : widget.student.phone),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(widget.student.email.isEmpty ? 'Non renseigné' : widget.student.email),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Inscrit le : ${_formatDate(widget.student.enrollmentDate.toIso8601String())}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Fees Section ───────────────────────────────
              const Text('Frais à régler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    // Inscription Fee
                    if (isInscriptionPaid)
                      ListTile(
                        title: const Text('Frais d\'inscription'),
                        subtitle: Text('${_inscriptionFee.toStringAsFixed(2)} \$'),
                        trailing: _buildPaidBadge(inscriptionDate),
                      )
                    else
                      CheckboxListTile(
                        title: const Text('Frais d\'inscription'),
                        subtitle: Text('${_inscriptionFee.toStringAsFixed(2)} \$'),
                        value: _payInscription,
                        activeColor: Colors.blue,
                        onChanged: (val) => setState(() => _payInscription = val ?? false),
                      ),
                    
                    const Divider(height: 1),

                    // Monthly Fee
                    if (isMonthlyPaid)
                      ListTile(
                        title: Text('Frais mensuel (${PaymentProvider.periodLabel(provider.currentPeriod)})'),
                        subtitle: Text('${_monthlyFee.toStringAsFixed(2)} \$'),
                        trailing: _buildPaidBadge(monthlyDate),
                      )
                    else
                      CheckboxListTile(
                        title: Text('Frais mensuel (${PaymentProvider.periodLabel(provider.currentPeriod)})'),
                        subtitle: Text('${_monthlyFee.toStringAsFixed(2)} \$'),
                        value: _payMonthly,
                        activeColor: Colors.blue,
                        onChanged: (val) => setState(() => _payMonthly = val ?? false),
                      ),
                  ],
                ),
              ),
              
              if (allPaid)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text('Tous les frais sont réglés pour ce mois.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<PaymentProvider>(
        builder: (context, provider, _) {
          final inscription = provider.inscriptionPayments.firstWhere((p) => p['studentId'] == widget.student.id, orElse: () => <String, dynamic>{});
          final isInscriptionPaid = inscription.isNotEmpty && inscription['status'] == 'paid';
          final monthly = provider.payments.firstWhere((p) => p['studentId'] == widget.student.id && p['feeType'] == 'monthly' && p['periodMonth'] == provider.currentPeriod, orElse: () => <String, dynamic>{});
          final isMonthlyPaid = monthly.isNotEmpty && monthly['status'] == 'paid';
          final allPaid = isInscriptionPaid && isMonthlyPaid;

          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 8)
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
              ),
              icon: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.payment),
              label: Text(
                allPaid ? 'Tous les frais sont réglés' : (_isProcessing ? 'Traitement...' : 'Payer ${_totalAmount.toStringAsFixed(2)} \$'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: (_totalAmount > 0 && !_isProcessing && !allPaid)
                  ? () => _processPayment(provider, isMonthlyPaid, isInscriptionPaid)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
