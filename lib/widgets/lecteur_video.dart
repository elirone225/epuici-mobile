// Sélectionne l'implémentation selon la plateforme de compilation.
// Voir lecteur_video_web.dart pour le pourquoi de cette séparation.
export 'lecteur_video_natif.dart'
    if (dart.library.js_interop) 'lecteur_video_web.dart';
