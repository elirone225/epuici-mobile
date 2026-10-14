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

    final id = idYoutube(lien);
    if (id != null) {
      return 'https://www.youtube.com/embed/$id?autoplay=$auto&playsinline=1&rel=0';
    }

    final chaine = _chaineYoutubeLive.firstMatch(lien)?.group(1);
    if (chaine != null) {
      return 'https://www.youtube.com/embed/live_stream?channel=$chaine&autoplay=$auto&playsinline=1';
    }

    if (estFacebook(lien)) {
      return 'https://www.facebook.com/plugins/video.php'
          '?href=${Uri.encodeComponent(lien)}&show_text=false&autoplay=${lectureAuto ? 'true' : 'false'}';
    }

    return lien;
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
