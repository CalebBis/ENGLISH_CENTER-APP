import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Bluetooth printing is only available on Android/iOS.
// On Windows (desktop), the service gracefully reports unsupported.
// Conditionally import the bluetooth packages only on mobile.

// ignore: depend_on_referenced_packages
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart'
    if (dart.library.html) 'package:english_center_app/services/printer_stub.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

import '../models/payment.dart';
import '../models/student.dart';
import '../providers/payment_provider.dart';

// ───────────────────────────────────────────────────────────────────────────
// Result type
// ───────────────────────────────────────────────────────────────────────────
class PrintResult {
  final bool success;
  final String message;
  const PrintResult._(this.success, this.message);
  factory PrintResult.ok() => const PrintResult._(true, 'Impression réussie.');
  factory PrintResult.error(String msg) => PrintResult._(false, msg);
}

// ───────────────────────────────────────────────────────────────────────────
// PrinterService — Singleton
// ───────────────────────────────────────────────────────────────────────────
class PrinterService {
  PrinterService._();
  static final PrinterService instance = PrinterService._();

  // True only on mobile platforms.
  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  
  // True on Windows.
  bool get _isWindows => !kIsWeb && Platform.isWindows;

  SerialPort? _serialPort;

  // ─── Persistence ────────────────────────────────────────────────────────

  Future<String?> getSavedMac() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_printer_mac');
  }

  Future<void> saveMac(String mac) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_printer_mac', mac);
  }

  Future<void> clearMac() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_printer_mac');
  }

  Future<String?> getSavedPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_printer_port');
  }

  Future<void> savePort(String portName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_printer_port', portName);
  }

  Future<void> clearPort() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_printer_port');
  }

  // ─── Device discovery ───────────────────────────────────────────────────

  /// Returns a list of paired Bluetooth devices.
  /// On non-mobile platforms returns an empty list.
  Future<List<BluetoothInfo>> getPairedDevices() async {
    if (!_isMobile) return [];
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      debugPrint('PrinterService.getPairedDevices: $e');
      return [];
    }
  }

  /// Returns a list of available COM ports for Windows.
  List<String> listAvailablePorts() {
    if (!_isWindows) return [];
    try {
      return SerialPort.availablePorts;
    } catch (e) {
      debugPrint('PrinterService.listAvailablePorts: $e');
      return [];
    }
  }

  // ─── Connection ─────────────────────────────────────────────────────────

  Future<PrintResult> connect(String identifier) async {
    if (_isMobile) {
      try {
        final connected = await PrintBluetoothThermal.connect(macPrinterAddress: identifier);
        if (connected) {
          await saveMac(identifier);
          return PrintResult.ok();
        }
        return PrintResult.error('Connexion échouée. Vérifiez que l\'imprimante est allumée et appairée.');
      } catch (e) {
        return PrintResult.error('Erreur de connexion : $e');
      }
    } else if (_isWindows) {
      try {
        if (_serialPort != null && _serialPort!.isOpen) {
          _serialPort!.close();
        }
        _serialPort = SerialPort(identifier);
        if (_serialPort!.openReadWrite()) {
          // Standard configuration for POS thermal printers (9600 baud)
          final config = SerialPortConfig()
            ..baudRate = 9600
            ..bits = 8
            ..parity = SerialPortParity.none
            ..stopBits = 1
            ..setFlowControl(SerialPortFlowControl.none);
          _serialPort!.config = config;
          
          await savePort(identifier);
          return PrintResult.ok();
        } else {
          return PrintResult.error('Impossible d\'ouvrir le port $identifier.');
        }
      } catch (e) {
        return PrintResult.error('Erreur de connexion au port COM : $e');
      }
    }
    return PrintResult.error('Impression non disponible sur cette plateforme.');
  }

  Future<void> disconnect() async {
    if (_isMobile) {
      try {
        await PrintBluetoothThermal.disconnect;
      } catch (_) {}
    } else if (_isWindows) {
      try {
        if (_serialPort != null && _serialPort!.isOpen) {
          _serialPort!.close();
        }
      } catch (_) {}
    }
  }

  Future<bool> isConnected() async {
    if (_isMobile) {
      try {
        return await PrintBluetoothThermal.connectionStatus;
      } catch (_) {
        return false;
      }
    } else if (_isWindows) {
      return _serialPort != null && _serialPort!.isOpen;
    }
    return false;
  }

  // ─── Common write method ────────────────────────────────────────────────

  Future<PrintResult> _writeBytes(List<int> bytes) async {
    if (_isMobile) {
      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result ? PrintResult.ok() : PrintResult.error('L\'imprimante n\'a pas pu traiter les données.');
    } else if (_isWindows) {
      if (_serialPort != null && _serialPort!.isOpen) {
        try {
          final written = _serialPort!.write(Uint8List.fromList(bytes));
          if (written == bytes.length) {
            return PrintResult.ok();
          }
          return PrintResult.error('Écriture incomplète sur le port série.');
        } catch (e) {
          return PrintResult.error('Erreur d\'écriture sur le port série : $e');
        }
      }
      return PrintResult.error('Le port série n\'est pas ouvert.');
    }
    return PrintResult.error('Plateforme non supportée.');
  }

  // ─── Formatting Helpers (32 chars for 58mm paper) ───────────────────────

  List<String> _wrapLine(String text, {int maxWidth = 32}) {
    List<String> lines = [];
    int start = 0;
    while (start < text.length) {
      int end = start + maxWidth;
      if (end > text.length) end = text.length;
      lines.add(text.substring(start, end));
      start = end;
    }
    return lines;
  }

  String _alignColumns(String left, String right, {int maxWidth = 32}) {
    if (left.length + right.length > maxWidth - 1) {
      int leftSpace = maxWidth - right.length - 1;
      if (leftSpace < 0) return left.substring(0, maxWidth);
      left = left.substring(0, leftSpace);
    }
    int spacesCount = maxWidth - left.length - right.length;
    return left + (' ' * spacesCount) + right;
  }

  // ─── Receipt printing ───────────────────────────────────────────────────

  /// Prints a 58mm payment receipt.
  /// Returns [PrintResult] so the UI can react without crashing.
  Future<PrintResult> printPaymentReceipt({
    required Student student,
    required Payment payment,
  }) async {
    if (!_isMobile && !_isWindows) {
      return PrintResult.error('Impression non disponible sur cette plateforme.');
    }

    final connected = await isConnected();
    if (!connected) {
      if (_isMobile) {
        final mac = await getSavedMac();
        if (mac == null) return PrintResult.error('Aucune imprimante configurée.');
        final result = await connect(mac);
        if (!result.success) return result;
      } else if (_isWindows) {
        final port = await getSavedPort();
        if (port == null) return PrintResult.error('Aucune imprimante configurée.');
        final result = await connect(port);
        if (!result.success) return result;
      }
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      const separator = '--------------------------------';

      // ── Header ──────────────────────────────────────────────────────────
      bytes += generator.text(
        'English Center',
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          align: PosAlign.center,
        ),
      );
      bytes += generator.text(
        'Reçu de Paiement',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(separator);

      // ── Body ─────────────────────────────────────────────────────────────
      for (var line in _wrapLine('Étudiant : ${student.fullName}')) {
        bytes += generator.text(line);
      }
      for (var line in _wrapLine('Période  : ${PaymentProvider.periodLabel(payment.periodMonth)}')) {
        bytes += generator.text(line);
      }
      
      bytes += generator.text(
        _alignColumns('Montant', '${payment.amount.toStringAsFixed(2)} \$'),
        styles: const PosStyles(bold: true),
      );

      // Format payment date nicely
      final d = payment.paymentDate;
      final dateStr =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      for (var line in _wrapLine('Date     : $dateStr')) {
        bytes += generator.text(line);
      }

      if (payment.paymentMethod != null && payment.paymentMethod!.isNotEmpty) {
        for (var line in _wrapLine('Méthode  : ${payment.paymentMethod}')) {
          bytes += generator.text(line);
        }
      }

      // ── Footer ───────────────────────────────────────────────────────────
      bytes += generator.text(separator);
      bytes += generator.text(
        'Merci !',
        styles: const PosStyles(
          bold: true,
          align: PosAlign.center,
        ),
      );
      bytes += generator.feed(2);
      bytes += generator.cut();

      return await _writeBytes(bytes);
    } catch (e) {
      return PrintResult.error('Erreur lors de l\'impression : $e');
    }
  }

  // ─── Monthly report printing ──────────────────────────────────────────────

  Future<PrintResult> printMonthlyReport({
    required String monthLabel,
    required List<Map<String, dynamic>> rows,
    required double totalCollected,
    required int unpaidCount,
    required double totalUnpaidAmount,
    required PaymentProvider provider,
  }) async {
    if (!_isMobile && !_isWindows) {
      return PrintResult.error('Impression non disponible sur cette plateforme.');
    }

    final connected = await isConnected();
    if (!connected) {
      if (_isMobile) {
        final mac = await getSavedMac();
        if (mac == null) return PrintResult.error('Aucune imprimante configurée.');
        final result = await connect(mac);
        if (!result.success) return result;
      } else if (_isWindows) {
        final port = await getSavedPort();
        if (port == null) return PrintResult.error('Aucune imprimante configurée.');
        final result = await connect(port);
        if (!result.success) return result;
      }
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      const separator = '--------------------------------';

      bytes += generator.text('English Center', styles: const PosStyles(bold: true, align: PosAlign.center));
      bytes += generator.text('Rapport de Paiements', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Mois : $monthLabel', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(separator);

      for (var row in rows) {
        final isPaid = provider.isFullyPaid(row['studentId'] as String);
        final lastName = row['lastName'] as String;
        final nameStr = lastName.length > 15 ? lastName.substring(0, 15) : lastName.padRight(15);
        final statusStr = isPaid ? 'Paye' : 'Impaye';
        final amtStr = isPaid ? '${row['amount']} \$'.padLeft(8) : '0.0 \$'.padLeft(8);
        bytes += generator.text('$nameStr $statusStr $amtStr');
      }

      bytes += generator.text(separator);
      bytes += generator.text('Total encaisse : ${totalCollected.toStringAsFixed(2)} \$', styles: const PosStyles(bold: true));
      bytes += generator.text('Nb impayes     : $unpaidCount');
      bytes += generator.text('Montant impaye : ${totalUnpaidAmount.toStringAsFixed(2)} \$');
      bytes += generator.text(separator);
      bytes += generator.feed(2);
      bytes += generator.cut();

      return await _writeBytes(bytes);
    } catch (e) {
      return PrintResult.error('Erreur lors de l\'impression : $e');
    }
  }

  // ─── Multiple fee invoice printing ────────────────────────────────────────

  Future<PrintResult> printInvoiceReceipt({
    required Student student,
    required List<Map<String, dynamic>> paidFees,
    required double totalAmount,
    required String invoiceNumber,
  }) async {
    if (!_isMobile && !_isWindows) {
      return PrintResult.error('Impression non disponible sur cette plateforme.');
    }

    final connected = await isConnected();
    if (!connected) {
      if (_isMobile) {
        final mac = await getSavedMac();
        if (mac == null) return PrintResult.error('Aucune imprimante configurée.');
        final result = await connect(mac);
        if (!result.success) return result;
      } else if (_isWindows) {
        final port = await getSavedPort();
        if (port == null) return PrintResult.error('Aucune imprimante configurée.');
        final result = await connect(port);
        if (!result.success) return result;
      }
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      const separator = '--------------------------------';

      bytes += generator.text('English Center', styles: const PosStyles(bold: true, align: PosAlign.center));
      bytes += generator.text('Facture #$invoiceNumber', styles: const PosStyles(align: PosAlign.center));
      
      final d = DateTime.now();
      final dateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      bytes += generator.text('Date : $dateStr', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(separator);

      for (var line in _wrapLine('Etudiant : ${student.fullName}')) {
        bytes += generator.text(line);
      }
      bytes += generator.text(separator);

      for (var fee in paidFees) {
        final label = fee['label'] as String;
        final amount = fee['amount'] as double;
        bytes += generator.text(_alignColumns(label, '${amount.toStringAsFixed(0)} \$'));
      }

      bytes += generator.text(separator);
      bytes += generator.text(
        _alignColumns('Total', '${totalAmount.toStringAsFixed(2)} \$'), 
        styles: const PosStyles(bold: true)
      );
      bytes += generator.text(separator);
      bytes += generator.text('Merci !', styles: const PosStyles(bold: true, align: PosAlign.center));
      bytes += generator.feed(2);
      bytes += generator.cut();

      return await _writeBytes(bytes);
    } catch (e) {
      return PrintResult.error('Erreur lors de l\'impression : $e');
    }
  }
}
