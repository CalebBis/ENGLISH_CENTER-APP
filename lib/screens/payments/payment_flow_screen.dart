import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/fee_settings_service.dart';
import '../../models/student.dart';

class PaymentFlowScreen extends StatefulWidget {
  final Student? preSelectedStudent;

  const PaymentFlowScreen({Key? key, this.preSelectedStudent}) : super(key: key);

  @override
  State<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends State<PaymentFlowScreen> {
  int _currentStep = 0;
  Student? _selectedStudent;
  String? _selectedFeeType; // 'inscription' or 'monthly'
  double? _feeAmount;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedStudent != null) {
      _selectedStudent = widget.preSelectedStudent;
      _currentStep = 1; // Skip step 1
    }
    Future.microtask(() {
      if (mounted && _currentStep == 0) {
        context.read<StudentProvider>().loadStudents();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep == 1 && widget.preSelectedStudent != null) {
      Navigator.pop(context);
    } else {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitPayment() async {
    if (_selectedStudent == null || _selectedFeeType == null || _feeAmount == null) return;

    final provider = context.read<PaymentProvider>();
    try {
      await provider.processPayment(
        _selectedStudent!.id,
        _selectedFeeType!,
        _feeAmount!,
        null, // Uses current period for monthly
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement enregistré avec succès'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Effectuer un paiement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 0 || (_currentStep == 1 && widget.preSelectedStudent != null)) {
              Navigator.pop(context);
            } else {
              _previousStep();
            }
          },
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_currentStep + 1) / 3),
          Expanded(
            child: _buildCurrentStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1StudentSelection();
      case 1:
        return _buildStep2FeeSelection();
      case 2:
        return _buildStep3Confirmation();
      default:
        return const SizedBox();
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Select Student
  // ---------------------------------------------------------------------------
  Widget _buildStep1StudentSelection() {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        final students = provider.students.where((s) {
          final q = _searchQuery.toLowerCase();
          return s.fullName.toLowerCase().contains(q);
        }).toList();

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Étape 1 : Sélectionnez un étudiant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Rechercher un étudiant',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text(s.firstName[0])),
                          title: Text(s.fullName),
                          subtitle: Text(s.phone),
                          onTap: () {
                            setState(() {
                              _selectedStudent = s;
                              _nextStep();
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Select Fee Type
  // ---------------------------------------------------------------------------
  Widget _buildStep2FeeSelection() {
    final inscriptionFee = FeeSettingsService.instance.getInscriptionFee();
    final monthlyFee = FeeSettingsService.instance.getMonthlyFee();

    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        final isMonthlyPaid = paymentProvider.isMonthlyPaidForCurrentPeriod(_selectedStudent!.id);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Étape 2 : Type de frais pour ${_selectedStudent!.fullName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              // Inscription Card
              Card(
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.school, color: Colors.blue, size: 36),
                  title: const Text('Frais d\'inscription'),
                  subtitle: Text('${inscriptionFee.toStringAsFixed(2)} \$ (Frais unique)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      _selectedFeeType = 'inscription';
                      _feeAmount = inscriptionFee;
                      _nextStep();
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Monthly Card
              Card(
                elevation: isMonthlyPaid ? 0 : 4,
                color: isMonthlyPaid ? Colors.grey.shade200 : null,
                child: ListTile(
                  leading: Icon(Icons.calendar_month, color: isMonthlyPaid ? Colors.grey : Colors.green, size: 36),
                  title: Text('Frais mensuel', style: TextStyle(color: isMonthlyPaid ? Colors.grey : null)),
                  subtitle: Text('${monthlyFee.toStringAsFixed(2)} \$ (Mois en cours)', style: TextStyle(color: isMonthlyPaid ? Colors.grey : null)),
                  trailing: isMonthlyPaid ? const Text('Déjà payé', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)) : const Icon(Icons.chevron_right),
                  onTap: isMonthlyPaid
                      ? null
                      : () {
                          setState(() {
                            _selectedFeeType = 'monthly';
                            _feeAmount = monthlyFee;
                            _nextStep();
                          });
                        },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Confirmation
  // ---------------------------------------------------------------------------
  Widget _buildStep3Confirmation() {
    final feeLabel = _selectedFeeType == 'inscription' ? 'Frais d\'inscription' : 'Frais mensuel';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Étape 3 : Récapitulatif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(_selectedStudent!.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(feeLabel, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      Text('${_feeAmount!.toStringAsFixed(2)} \$', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirmer le paiement', style: TextStyle(fontSize: 18)),
            onPressed: _submitPayment,
          ),
        ],
      ),
    );
  }
}
