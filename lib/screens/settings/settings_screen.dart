import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../services/printer_service.dart';
import '../../services/fee_settings_service.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool emailNotifications = true;

  // Printer
  String? _savedMac;
  String? _savedName;
  bool _printerConnected = false;
  bool _loadingPrinter = false;
  List<BluetoothInfo> _pairedDevices = [];
  bool _loadingDevices = false;

  // True only on mobile
  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  late TextEditingController _inscriptionController;
  late TextEditingController _monthlyController;

  @override
  void initState() {
    super.initState();
    _inscriptionController = TextEditingController(
        text: FeeSettingsService.instance.getInscriptionFee().toString());
    _monthlyController = TextEditingController(
        text: FeeSettingsService.instance.getMonthlyFee().toString());
    _loadPrinterStatus();
  }

  @override
  void dispose() {
    _inscriptionController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  Future<void> _loadPrinterStatus() async {
    final mac = await PrinterService.instance.getSavedMac();
    final connected = await PrinterService.instance.isConnected();
    if (mounted) {
      setState(() {
        _savedMac = mac;
        _printerConnected = connected;
      });
    }
  }

  Future<void> _searchDevices() async {
    if (!_isMobile) {
      _showUnsupportedSnack();
      return;
    }
    setState(() { _loadingDevices = true; _pairedDevices = []; });
    final devices = await PrinterService.instance.getPairedDevices();
    if (mounted) setState(() { _pairedDevices = devices; _loadingDevices = false; });
  }

  Future<void> _connectDevice(BluetoothInfo info) async {
    setState(() => _loadingPrinter = true);
    final result = await PrinterService.instance.connect(info.macAdress);
    if (mounted) {
      setState(() {
        _loadingPrinter = false;
        if (result.success) {
          _savedMac = info.macAdress;
          _savedName = info.name;
          _printerConnected = true;
          _pairedDevices = [];
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ));
    }
  }

  void _showUnsupportedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('L\'impression Bluetooth est disponible uniquement sur Android/iOS.'),
      backgroundColor: Colors.orange,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tarifs ─────────────────────────────────────────────────────
            const Text('Tarifs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _inscriptionController,
                      decoration: const InputDecoration(labelText: 'Frais d\'inscription (\$)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) FeeSettingsService.instance.setInscriptionFee(parsed);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _monthlyController,
                      decoration: const InputDecoration(labelText: 'Frais mensuel (\$)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) FeeSettingsService.instance.setMonthlyFee(parsed);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Apparence ──────────────────────────────────────────────────
            Card(
              child: SwitchListTile(
                title: const Text('Mode Sombre'),
                value: darkMode,
                onChanged: (value) => setState(() => darkMode = value),
              ),
            ),
            const SizedBox(height: 24),

            // ── Notifications ──────────────────────────────────────────────
            const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('Email'),
                value: emailNotifications,
                onChanged: (value) => setState(() => emailNotifications = value),
              ),
            ),
            const SizedBox(height: 24),

            // ── Imprimante ─────────────────────────────────────────────────
            const Text('Imprimante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _printerConnected ? Icons.print : Icons.print_disabled,
                          color: _printerConnected ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _savedMac != null
                                    ? (_savedName ?? _savedMac!)
                                    : 'Aucune imprimante configurée',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _printerConnected ? 'Connectée' : 'Non connectée',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _printerConnected ? Colors.green : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_savedMac != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Supprimer la configuration',
                            onPressed: () async {
                              await PrinterService.instance.disconnect();
                              await PrinterService.instance.clearMac();
                              if (mounted) setState(() { _savedMac = null; _printerConnected = false; });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loadingDevices ? null : _searchDevices,
                        icon: _loadingDevices
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.bluetooth_searching),
                        label: const Text('Rechercher les imprimantes appairées'),
                      ),
                    ),
                    if (!_isMobile) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '⚠ L\'impression Bluetooth est disponible uniquement sur Android/iOS.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Paired device list
            if (_pairedDevices.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: _pairedDevices.map((device) {
                    return ListTile(
                      leading: const Icon(Icons.print, color: Colors.blue),
                      title: Text(device.name),
                      subtitle: Text(device.macAdress),
                      trailing: _loadingPrinter
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : ElevatedButton(
                              onPressed: () => _connectDevice(device),
                              child: const Text('Connecter'),
                            ),
                    );
                  }).toList(),
                ),
              ),
            ],

            if (_pairedDevices.isEmpty && !_loadingDevices && _isMobile) ...[
              const SizedBox(height: 8),
              const Text(
                'Aucun appareil trouvé. Assurez-vous que votre imprimante est allumée et appairée dans les paramètres Bluetooth de votre téléphone.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 24),

            // ── Compte ─────────────────────────────────────────────────────
            const Text('Compte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
