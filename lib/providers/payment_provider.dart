import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/dao/payment_dao.dart';
import '../services/fee_settings_service.dart';
import '../services/dao/class_dao.dart';
import '../services/dao/enrollment_dao.dart';
import '../models/english_class.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentDao _dao = PaymentDao();
  final ClassDao _classDao = ClassDao();
  final EnrollmentDao _enrollmentDao = EnrollmentDao();

  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _inscriptionPayments = [];
  bool _isLoading = false;
  String _currentPeriod = _currentMonthString();
  double _calendarMonthRevenue = 0.0;
  String _statusFilter = 'all'; // 'all', 'fully_paid', 'unpaid'
  String _promotionFilter = 'all'; // 'all' or specific classId
  List<EnglishClass> _availableClasses = [];
  Map<String, String> _studentClassMap = {};

  List<Map<String, dynamic>> get payments => _payments;
  List<Map<String, dynamic>> get inscriptionPayments => _inscriptionPayments;
  bool get isLoading => _isLoading;
  String get currentPeriod => _currentPeriod;
  double get calendarMonthRevenue => _calendarMonthRevenue;
  String get statusFilter => _statusFilter;
  String get promotionFilter => _promotionFilter;
  List<EnglishClass> get availableClasses => _availableClasses;
  Map<String, String> get studentClassMap => _studentClassMap;

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setPromotionFilter(String filter) {
    _promotionFilter = filter;
    notifyListeners();
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------
  static String _currentMonthString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static String periodLabel(String period) {
    // 'YYYY-MM' → 'Mois YYYY'
    final parts = period.split('-');
    if (parts.length != 2) return period;
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    final monthIdx = int.tryParse(parts[1]) ?? 1;
    return '${months[monthIdx - 1]} ${parts[0]}';
  }

  // -----------------------------------------------------------------------
  // Navigation
  // -----------------------------------------------------------------------
  void previousMonth() {
    final parts = _currentPeriod.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]);
    month--;
    if (month < 1) { month = 12; year--; }
    _currentPeriod = '$year-${month.toString().padLeft(2, '0')}';
    loadPayments();
  }

  void nextMonth() {
    final parts = _currentPeriod.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]);
    month++;
    if (month > 12) { month = 1; year++; }
    _currentPeriod = '$year-${month.toString().padLeft(2, '0')}';
    loadPayments();
  }

  // -----------------------------------------------------------------------
  // Load
  // -----------------------------------------------------------------------
  Future<void> loadPayments() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dao.ensureInvoicesForMonth(_currentPeriod, FeeSettingsService.instance.getMonthlyFee());
      _payments = await _dao.getPaymentsForMonth(_currentPeriod);
      _inscriptionPayments = await _dao.getAllInscriptionPayments();
      
      final parts = _currentPeriod.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      _calendarMonthRevenue = await _dao.getRevenueForCalendarMonth(year, month);
      
      _availableClasses = await _classDao.getAllClasses();
      _studentClassMap = await _enrollmentDao.getActiveEnrollmentsMap();
    } catch (e) {
      debugPrint('PaymentProvider.loadPayments error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------------
  // Collect a payment. Returns the updated Payment object.
  // -----------------------------------------------------------------------
  Future<Payment> collectPayment(
    String paymentId, {
    String? paymentMethod,
    String? notes,
  }) async {
    final updated = await _dao.markAsPaid(paymentId, paymentMethod: paymentMethod, notes: notes);
    await loadPayments();
    return updated;
  }

  // -----------------------------------------------------------------------
  // Revert to unpaid.
  // -----------------------------------------------------------------------
  Future<void> revertToUnpaid(String paymentId) async {
    await _dao.markAsUnpaid(paymentId);
    await loadPayments();
  }

  // -----------------------------------------------------------------------
  // Check fully paid status
  // -----------------------------------------------------------------------
  bool isFullyPaid(String studentId) {
    // Check monthly
    final monthly = _payments.firstWhere(
      (p) => p['studentId'] == studentId && p['feeType'] == 'monthly' && p['periodMonth'] == _currentPeriod,
      orElse: () => <String, dynamic>{},
    );
    final isMonthlyPaid = monthly.isNotEmpty && monthly['status'] == 'paid';
    
    // Check inscription
    final inscription = _inscriptionPayments.firstWhere(
      (p) => p['studentId'] == studentId,
      orElse: () => <String, dynamic>{},
    );
    final isInscriptionPaid = inscription.isNotEmpty && inscription['status'] == 'paid';

    return isMonthlyPaid && isInscriptionPaid;
  }

  // -----------------------------------------------------------------------
  // Stats helpers for Dashboard.
  // -----------------------------------------------------------------------
  double get totalRevenue => _calendarMonthRevenue;

  int get paidCount => _payments.where((p) => p['feeType'] == 'monthly' && isFullyPaid(p['studentId'] as String)).length;

  int get totalMonthlyCount => _payments.where((p) => p['feeType'] == 'monthly').length;

  int get unpaidCount => totalMonthlyCount - paidCount;

  // -----------------------------------------------------------------------
  // Process a new payment (Inscription or Monthly)
  // -----------------------------------------------------------------------
  Future<void> processPayment(
    String studentId,
    String feeType,
    double amount,
    String? periodMonth,
    {String? paymentMethod}
  ) async {
    if (feeType == 'inscription') {
      await _dao.createInscriptionPayment(studentId, amount, paymentMethod: paymentMethod);
    } else if (feeType == 'monthly') {
      final period = periodMonth ?? _currentPeriod;
      await _dao.createMonthlyPayment(studentId, period, amount, paymentMethod: paymentMethod);
    }
    await loadPayments();
  }

  // -----------------------------------------------------------------------
  // Check if monthly fee is already paid for a specific student in the current period
  // -----------------------------------------------------------------------
  bool isMonthlyPaidForCurrentPeriod(String studentId) {
    try {
      final payment = _payments.firstWhere(
        (p) => p['studentId'] == studentId && p['feeType'] == 'monthly' && p['periodMonth'] == _currentPeriod,
      );
      return payment['status'] == 'paid';
    } catch (_) {
      return false; // not found
    }
  }
}
