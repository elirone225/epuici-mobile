import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'lien_video.dart';

// Lecteur web d'une vidéo YouTube / Facebook (iframe) ou d'un fichier vidéo
// direct (<video> avec contrôles natifs du navigateur).
class LecteurIntegre extends StatefulWidget {
  final String lien;
  final bool lectureAuto;

  const LecteurIntegre({super.key, required this.lien, this.lectureAuto = false});

  @override
  State<LecteurIntegre> createState() => _LecteurIntegreState();
}

class _LecteurIntegreState extends State<LecteurIntegre> {
  static int _compteur = 0;
  late final String _typeVue;

  @override
  void initState() {
    super.initState();
    _typeVue = 'lecteur-integre-${_compteur++}';
    final lien = widget.lien;
    final lectureAuto = widget.lectureAuto;

    ui_web.platformViewRegistry.registerViewFactory(_typeVue, (int _) {
      if (LienVideo.estFichierVideo(lien)) {
        return web.HTMLVideoElement()
          ..src = lien
          ..controls = true
          ..autoplay = lectureAuto
          ..playsInline = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'black';
      }
      return web.HTMLIFrameElement()
        ..src = LienVideo.urlIntegration(lien, lectureAuto: lectureAuto)
        ..allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen'
        ..allowFullscreen = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none';
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _typeVue);
}

// Ouvre le lien hors de l'app (application YouTube / Facebook ou nouvel
// onglet) : solution de secours si le lecteur intégré ne peut pas lire.
void ouvrirLienExterne(String lien) {
  web.window.open(lien, '_blank');
}
