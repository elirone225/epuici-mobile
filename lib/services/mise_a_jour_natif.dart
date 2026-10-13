import 'package:flutter/foundation.dart';

// Hors web, rien à faire : les mises à jour passent par le store / l'APK.
class MiseAJour {
  static final ValueNotifier<bool> disponible = ValueNotifier(false);

  static Future<void> verifier({bool rechargerSiNouvelle = true}) async {}

  static void recharger() {}
}
