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

  // ─── Connection ─────────────────────────────────────────────────────────

  Future<PrintResult> connect(String macAddress) async {
    if (!_isMobile) {
      return PrintResult.error('Impression Bluetooth non disponible sur cette plateforme.');
    }
    try {
      final connected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      if (connected) {
        await saveMac(macAddress);
        return PrintResult.ok();
      }
      return PrintResult.error('Connexion échouée. Vérifiez que l\'imprimante est allumée et appairée.');
    } catch (e) {
      return PrintResult.error('Erreur de connexion : $e');
    }
  }

  Future<void> disconnect() async {
    if (!_isMobile) return;
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
  }

  Future<bool> isConnected() async {
    if (!_isMobile) return false;
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return false;
    }
  }

  // ─── Receipt printing ───────────────────────────────────────────────────

  /// Prints a 58mm payment receipt.
  /// Returns [PrintResult] so the UI can react without crashing.
  Future<PrintResult> printPaymentReceipt({
    required Student student,
    required Payment payment,
  }) async {
    if (!_isMobile) {
      return PrintResult.error('Impression Bluetooth non disponible sur Windows. '
          'Cette fonctionnalité est réservée à l\'application Android.');
    }

    final connected = await isConnected();
    if (!connected) {
      // Try to reconnect with saved MAC
      final mac = await getSavedMac();
      if (mac == null) {
        return PrintResult.error('Aucune imprimante configurée. '
            'Allez dans Paramètres > Imprimante pour en choisir une.');
      }
      final result = await connect(mac);
      if (!result.success) {
        return PrintResult.error('Imprimante non connectée. ${result.message}');
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
      bytes += generator.text('Étudiant : ${student.fullName}');
      bytes += generator.text(
        'Période  : ${PaymentProvider.periodLabel(payment.periodMonth)}',
      );
      bytes += generator.text(
        'Montant  : ${payment.amount.toStringAsFixed(2)} \$',
        styles: const PosStyles(bold: true),
      );

      // Format payment date nicely
      final d = payment.paymentDate;
      final dateStr =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      bytes += generator.text('Date     : $dateStr');

      if (payment.paymentMethod != null && payment.paymentMethod!.isNotEmpty) {
        bytes += generator.text('Méthode  : ${payment.paymentMethod}');
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

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result
          ? PrintResult.ok()
          : PrintResult.error('L\'imprimante n\'a pas pu traiter les données.');
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
    if (!_isMobile) {
      return PrintResult.error('Impression Bluetooth non disponible sur Windows.');
    }

    final connected = await isConnected();
    if (!connected) {
      final mac = await getSavedMac();
      if (mac == null) return PrintResult.error('Aucune imprimante configurée.');
      final result = await connect(mac);
      if (!result.success) return PrintResult.error('Imprimante non connectée.');
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

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result ? PrintResult.ok() : PrintResult.error('Erreur d\'impression.');
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
    if (!_isMobile) {
      return PrintResult.error('Impression Bluetooth non disponible sur Windows.');
    }

    final connected = await isConnected();
    if (!connected) {
      final mac = await getSavedMac();
      if (mac == null) return PrintResult.error('Aucune imprimante configurée.');
      final result = await connect(mac);
      if (!result.success) return PrintResult.error('Imprimante non connectée.');
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

      bytes += generator.text('Etudiant : ${student.fullName}');
      bytes += generator.text(separator);

      for (var fee in paidFees) {
        final label = fee['label'] as String;
        final amount = fee['amount'] as double;
        final lblStr = label.length > 20 ? label.substring(0, 20) : label.padRight(20);
        final amtStr = '${amount.toStringAsFixed(0)} \$'.padLeft(9);
        bytes += generator.text('$lblStr $amtStr');
      }

      bytes += generator.text(separator);
      bytes += generator.text('Total : ${totalAmount.toStringAsFixed(2)} \$', styles: const PosStyles(bold: true));
      bytes += generator.text(separator);
      bytes += generator.text('Merci !', styles: const PosStyles(bold: true, align: PosAlign.center));
      bytes += generator.feed(2);
      bytes += generator.cut();

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result ? PrintResult.ok() : PrintResult.error('Erreur d\'impression.');
    } catch (e) {
      return PrintResult.error('Erreur lors de l\'impression : $e');
    }
  }
}
