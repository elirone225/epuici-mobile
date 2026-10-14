// Interprète les liens vidéo donnés par l'admin d'église (YouTube, Facebook
// ou fichier vidéo direct) pour les intégrer dans l'app.
class LienVideo {
  LienVideo._();

  static final _motifsYoutube = [
    RegExp(r'youtu\.be/([\w-]{11})'),
    RegExp(r'youtube\.com/(?:watch\?(?:.*&)?v=|embed/|live/|shorts/|v/)([\w-]{11})'),
  ];
  static final _chaineYoutubeLive =
      RegExp(r'youtube\.com/channel/(UC[\w-]+)/live');

  static String? idYoutube(String lien) {
    for (final motif in _motifsYoutube) {
      final correspondance = motif.firstMatch(lien);
      if (correspondance != null) return correspondance.group(1);
    }
    return null;
  }

  static bool estFichierVideo(String lien) =>
      RegExp(r'\.(mp4|webm|ogg|mov|m3u8)(\?|#|$)', caseSensitive: false)
          .hasMatch(lien);

  static bool estFacebook(String lien) =>
      RegExp(r'(facebook\.com|fb\.watch)', caseSensitive: false).hasMatch(lien);

  // Adresse à charger dans l'iframe du lecteur.
  static String urlIntegration(String lien, {bool lectureAuto = false}) {
    final auto = lectureAuto ? '1' : '0';

    // youtube-nocookie : lecteur "confidentialité renforcée" qui n'utilise pas
    // le compte Google du téléphone. Avec le lecteur classique, un compte
    // restreint (compte pro, compte enfant...) affichait la page Google
    // "Service non disponible" à la place de la vidéo.
    final id = idYoutube(lien);
    if (id != null) {
      final debut = _debutEnSecondes(lien);
      return 'https://www.youtube-nocookie.com/embed/$id'
          '?autoplay=$auto&playsinline=1&rel=0${debut > 0 ? '&start=$debut' : ''}';
    }

    final chaine = _chaineYoutubeLive.firstMatch(lien)?.group(1);
    if (chaine != null) {
      return 'https://www.youtube-nocookie.com/embed/live_stream'
          '?channel=$chaine&autoplay=$auto&playsinline=1';
    }

    if (estFacebook(lien)) {
      return 'https://www.facebook.com/plugins/video.php'
          '?href=${Uri.encodeComponent(lien)}&show_text=false&autoplay=${lectureAuto ? 'true' : 'false'}';
    }

    return lien;
  }

  // Position de départ d'un lien partagé "à partir de" (ex : ?t=26 ou ?t=1m30s).
  static int _debutEnSecondes(String lien) {
    final t = RegExp(r'[?&]t=(\d+h)?(\d+m)?(\d+)s?').firstMatch(lien);
    if (t == null) return 0;
    int partie(String? valeur) =>
        valeur == null ? 0 : int.parse(valeur.substring(0, valeur.length - 1));
    return partie(t.group(1)) * 3600 + partie(t.group(2)) * 60 + int.parse(t.group(3)!);
  }

  // Miniature affichée avant la lecture : YouTube, ou vidéo envoyée sur
  // Cloudinary (qui génère une image si on remplace l'extension par .jpg).
  static String? miniature(String lien) {
    final id = idYoutube(lien);
    if (id != null) return 'https://img.youtube.com/vi/$id/hqdefault.jpg';

    if (lien.contains('res.cloudinary.com') && lien.contains('/video/upload/')) {
      return lien.replaceFirst(RegExp(r'\.\w+$'), '.jpg');
    }
    return null;
  }
}
