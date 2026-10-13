import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

// Implémentation Android/iOS/desktop : le paquet video_player standard
// fonctionne correctement sur ces plateformes (pas le bug d'attache DOM
// propre au web géré dans lecteur_video_web.dart).
class LecteurVideoControleur {
  LecteurVideoControleur(String url)
      : _controleur = VideoPlayerController.networkUrl(Uri.parse(url));

  final VideoPlayerController _controleur;

  Future<void> initialiser() => _controleur.initialize();

  Future<void> setVolume(double volume) => _controleur.setVolume(volume);

  Future<void> setLooping(bool value) => _controleur.setLooping(value);

  Future<void> play() => _controleur.play();

  Future<void> pause() => _controleur.pause();

  Future<void> seekToZero() => _controleur.seekTo(Duration.zero);

  Future<void> dispose() => _controleur.dispose();

  bool get estInitialise => _controleur.value.isInitialized;
  bool get enLecture => _controleur.value.isPlaying;
  double get largeur => _controleur.value.size.width;
  double get hauteur => _controleur.value.size.height;

  Widget construireVue() => VideoPlayer(_controleur);
}
