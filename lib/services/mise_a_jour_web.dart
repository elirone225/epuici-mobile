import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

// Une PWA installée peut rester ouverte en mémoire des jours entiers sur le
// téléphone, avec l'ancienne version. À chaque retour au premier plan, on
// compare le version.json publié (généré par `flutter build web` à partir de
// la version du pubspec.yaml) avec celui du démarrage, et on recharge la page
// s'il a changé.
class MiseAJour {
  static String? _versionChargee;
  static bool _verificationEnCours = false;

  static Future<void> verifier() async {
    if (_verificationEnCours) return;
    _verificationEnCours = true;
    try {
      final url = Uri.base.resolve('version.json').replace(
        queryParameters: {'t': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final reponse = await http.get(url);
      if (reponse.statusCode != 200) return;

      final donnees = jsonDecode(reponse.body);
      final version = '${donnees['version']}+${donnees['build_number']}';

      if (_versionChargee == null) {
        _versionChargee = version;
      } else if (version != _versionChargee) {
        web.window.location.reload();
      }
    } catch (_) {
      // Hors connexion ou fichier absent : on réessaiera au prochain retour
    } finally {
      _verificationEnCours = false;
    }
  }
}
