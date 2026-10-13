import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

// Implémentation web : on gère l'élément <video> nous-mêmes, au lieu du
// paquet video_player standard.
//
// Le paquet video_player_web ne construit le HtmlElementView (donc n'attache
// vraiment l'élément <video> au DOM visible) qu'une fois la vidéo chargée —
// mais certains navigateurs mobiles suspendent le chargement d'un <video>
// qui n'est jamais réellement affiché à l'écran, ce qui bloque
// indéfiniment ce chargement (chargement infini côté app, sans jamais
// d'erreur ni de succès). Ici, la vue est construite dès la création,
// avant même que la vidéo soit prête, pour que le navigateur la traite
// normalement.
class LecteurVideoControleur {
  LecteurVideoControleur(String url) : _id = _compteur++ {
    _element = web.HTMLVideoElement()
      ..src = url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.border = 'none'
      ..autoplay = false
      ..controls = false
      ..playsInline = true
      ..muted = true;

    ui_web.platformViewRegistry.registerViewFactory(
      'lecteur-video-$_id',
      (int viewId) => _element,
    );
  }

  static int _compteur = 0;

  final int _id;
  late final web.HTMLVideoElement _element;
  final Completer<void> _pret = Completer<void>();
  bool _resolu = false;
  bool _enLecture = false;

  Future<void> initialiser() {
    _element.onLoadedMetadata.listen((_) {
      if (!_resolu) {
        _resolu = true;
        _pret.complete();
      }
    });
    _element.onError.listen((_) {
      if (!_resolu) {
        _resolu = true;
        _pret.completeError(Exception('Erreur de lecture vidéo.'));
      }
    });
    _element.load();
    return _pret.future;
  }

  Future<void> setVolume(double volume) async {
    _element.muted = volume == 0;
    if (volume > 0) _element.volume = volume;
  }

  Future<void> setLooping(bool value) async {
    _element.loop = value;
  }

  Future<void> play() async {
    _enLecture = true;
    try {
      await _element.play().toDart;
    } catch (_) {
      // Lecture refusée par une politique du navigateur : sans effet ici
      // car la vidéo est déjà coupée par défaut (autoplay autorisé).
    }
  }

  Future<void> pause() async {
    _enLecture = false;
    _element.pause();
  }

  Future<void> seekToZero() async {
    _element.currentTime = 0;
  }

  Future<void> dispose() async {
    _element.pause();
    _element.removeAttribute('src');
    _element.load();
  }

  bool get estInitialise => _resolu;
  bool get enLecture => _enLecture;
  double get largeur => _element.videoWidth.toDouble();
  double get hauteur => _element.videoHeight.toDouble();

  Widget construireVue() => HtmlElementView(viewType: 'lecteur-video-$_id');
}
