import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

// Une PWA installée peut rester ouverte en mémoire des jours entiers sur le
// téléphone, avec l'ancienne version. On compare le version.json publié
// (généré par `flutter build web` à partir de la version du pubspec.yaml)
// avec celui du démarrage :
// - au retour sur l'app, on recharge directement (l'utilisateur n'est au
//   milieu de rien) ;
// - pendant l'utilisation, on signale seulement la mise à jour (bandeau).
class MiseAJour {
  static String? _versionChargee;
  static bool _verificationEnCours = false;

  // Passe à true quand une nouvelle version est publiée pendant l'utilisation
  static final ValueNotifier<bool> disponible = ValueNotifier(false);

  static Future<void> verifier({bool rechargerSiNouvelle = true}) async {
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
        if (rechargerSiNouvelle) {
          recharger();
        } else {
          disponible.value = true;
        }
      }
    } catch (_) {
      // Hors connexion ou fichier absent : on réessaiera plus tard
    } finally {
      _verificationEnCours = false;
    }
  }

  static void recharger() => web.window.location.reload();
}
