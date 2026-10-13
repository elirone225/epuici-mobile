// Sélectionne l'implémentation selon la plateforme de compilation :
// seule la PWA (web) se met à jour en rechargeant la page.
export 'mise_a_jour_natif.dart'
    if (dart.library.js_interop) 'mise_a_jour_web.dart';
