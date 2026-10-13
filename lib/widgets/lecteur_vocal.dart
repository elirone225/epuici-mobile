import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';

// Lecteur d'un message vocal dans une bulle de discussion.
// Un seul vocal joue à la fois : lancer un vocal met en pause le précédent.
class LecteurVocal extends StatefulWidget {
  final String url;
  final int? dureeSecondes;
  final bool moi; // bulle bleue (texte blanc) ou blanche

  const LecteurVocal({super.key, required this.url, this.dureeSecondes, required this.moi});

  @override
  State<LecteurVocal> createState() => _LecteurVocalState();
}

class _LecteurVocalState extends State<LecteurVocal> {
  static AudioPlayer? _lecteurEnCours;

  final _lecteur = AudioPlayer();
  final List<StreamSubscription> _abonnements = [];
  PlayerState _etat = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration? _duree;
  bool _chargement = false;

  @override
  void initState() {
    super.initState();
    if (widget.dureeSecondes != null) _duree = Duration(seconds: widget.dureeSecondes!);
    _abonnements.addAll([
      _lecteur.onPlayerStateChanged.listen((etat) {
        if (mounted) setState(() => _etat = etat);
      }),
      _lecteur.onPositionChanged.listen((position) {
        if (mounted) setState(() => _position = position);
      }),
      _lecteur.onDurationChanged.listen((duree) {
        if (mounted && duree > Duration.zero) setState(() => _duree = duree);
      }),
      _lecteur.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _position = Duration.zero);
      }),
    ]);
  }

  @override
  void dispose() {
    for (final abonnement in _abonnements) {
      abonnement.cancel();
    }
    if (_lecteurEnCours == _lecteur) _lecteurEnCours = null;
    _lecteur.dispose();
    super.dispose();
  }

  Future<void> _basculer() async {
    if (_etat == PlayerState.playing) {
      await _lecteur.pause();
      return;
    }
    if (_lecteurEnCours != null && _lecteurEnCours != _lecteur) {
      await _lecteurEnCours!.pause();
    }
    _lecteurEnCours = _lecteur;

    if (_etat == PlayerState.paused) {
      await _lecteur.resume();
      return;
    }
    setState(() => _chargement = true);
    try {
      await _lecteur.play(UrlSource(widget.url, mimeType: 'audio/mpeg'));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lire ce message vocal.')),
        );
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  String _format(Duration d) {
    final minutes = d.inMinutes;
    final secondes = d.inSeconds % 60;
    return '$minutes:${secondes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final couleur = widget.moi ? Colors.white : EpuiciColors.primaire;
    final dureeTotale = _duree ?? Duration.zero;
    final maxMs = dureeTotale.inMilliseconds > 0 ? dureeTotale.inMilliseconds.toDouble() : 1.0;
    final valeur = _position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();
    final enLecture = _etat == PlayerState.playing;
    final afficherPosition = enLecture || _etat == PlayerState.paused;

    return SizedBox(
      width: 230,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: _chargement
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2, color: couleur),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(enLecture ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 32),
                    color: couleur,
                    onPressed: _basculer,
                  ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: couleur,
                    inactiveTrackColor: couleur.withValues(alpha: 0.3),
                    thumbColor: couleur,
                  ),
                  child: Slider(
                    min: 0,
                    max: maxMs,
                    value: valeur,
                    onChanged: dureeTotale > Duration.zero
                        ? (v) => _lecteur.seek(Duration(milliseconds: v.round()))
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    _format(afficherPosition ? _position : dureeTotale),
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.moi ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
