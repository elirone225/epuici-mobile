// Sélectionne l'implémentation selon la plateforme de compilation
// (l'app est distribuée en PWA : la version web est celle utilisée).
export 'lecteur_integre_natif.dart'
    if (dart.library.js_interop) 'lecteur_integre_web.dart';
