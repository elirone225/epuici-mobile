import 'package:shared_preferences/shared_preferences.dart';

class StockageLocal {
  static const _cleVillagesSuivis = 'villages_suivis';
  static const _cleToken = 'akye_token';
  static const _cleOnboardingFait = 'onboarding_fait';

  static Future<void> enregistrerVillagesSuivis(List<String> idsVillages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_cleVillagesSuivis, idsVillages);
    await prefs.setBool(_cleOnboardingFait, true);
  }

  static Future<List<String>> obtenirVillagesSuivis() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_cleVillagesSuivis) ?? [];
  }

  static Future<bool> onboardingDejaFait() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cleOnboardingFait) ?? false;
  }

  static Future<void> enregistrerToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleToken, token);
  }

  static Future<String?> obtenirToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cleToken);
  }

  static Future<bool> estConnecte() async {
    final token = await obtenirToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> deconnecter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cleToken);
  }
}
