import 'package:shared_preferences/shared_preferences.dart';

class FeeSettingsService {
  FeeSettingsService._();
  static final FeeSettingsService instance = FeeSettingsService._();

  static const String _keyInscription = 'fee_inscription';
  static const String _keyMonthly = 'fee_monthly';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  double getInscriptionFee() {
    return _prefs?.getDouble(_keyInscription) ?? 50.0;
  }

  Future<void> setInscriptionFee(double amount) async {
    await _prefs?.setDouble(_keyInscription, amount);
  }

  double getMonthlyFee() {
    return _prefs?.getDouble(_keyMonthly) ?? 20.0;
  }

  Future<void> setMonthlyFee(double amount) async {
    await _prefs?.setDouble(_keyMonthly, amount);
  }
}
