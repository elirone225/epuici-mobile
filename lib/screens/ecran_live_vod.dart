import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/stockage_local.dart';
import '../widgets/lecteur_integre.dart';
import '../widgets/lien_video.dart';
import 'ecran_choix_villages.dart';

// Onglet "Live & VOD" : en haut le lecteur du direct de l'église suivie
// ("Direct terminé" tant que son admin n'a pas donné de lien), puis les vidéos
// ajoutées par le Super Admin, communes à tous les fidèles.
class EcranLiveVod extends StatefulWidget {
  // Vrai quand l'onglet est affiché : les lecteurs sont retirés sinon, pour
  // couper le son quand le fidèle change d'onglet.
  final bool actif;

  const EcranLiveVod({super.key, required this.actif});

  @override
  State<EcranLiveVod> createState() => _EcranLiveVodState();
}

class _EcranLiveVodState extends State<EcranLiveVod> {
  bool _chargement = true;
  String _erreur = '';
  bool _aucuneEglise = false;
  String _nomEglise = '';
  String _lienDirect = '';
  bool _directEnCours = false;
  List<Map<String, dynamic>> _videos = [];
  // Vidéo en cours de lecture (une seule à la fois).
  String? _videoEnLecture;

  @override
  void initState() {
    super.initState();
    if (widget.actif) _charger();
  }

  @override
  void didUpdateWidget(covariant EcranLiveVod ancien) {
    super.didUpdateWidget(ancien);
    if (widget.actif && !ancien.actif) {
      // Retour sur l'onglet : on rafraîchit l'état du direct.
      _charger();
    } else if (!widget.actif && ancien.actif) {
      setState(() => _videoEnLecture = null);
    }
  }

  Future<void> _charger() async {
    final ids = await StockageLocal.obtenirVillagesSuivis();

    try {
      if (ids.isEmpty) {
        // Pas d'église : pas de direct, mais les vidéos du Super Admin
        // restent visibles par tous.
        final videos = await ApiService.listerVideosVod();
        if (!mounted) return;
        setState(() {
          _aucuneEglise = true;
          _erreur = '';
          _directEnCours = false;
          _videos = videos;
          _chargement = false;
        });
        return;
      }

      final donnees = await ApiService.obtenirLiveVod(ids.first);
      if (!mounted) return;
      final direct = donnees['direct'] ?? {};
      setState(() {
        _aucuneEglise = false;
        _erreur = '';
        _nomEglise = donnees['village']?['nom'] ?? '';
        _lienDirect = direct['lien'] ?? '';
        _directEnCours = direct['enCours'] == true;
        _videos = List<Map<String, dynamic>>.from(donnees['videos'] ?? []);
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Impossible de charger le direct et les vidéos. Vérifiez votre connexion.';
        _chargement = false;
      });
    }
  }

  Future<void> _choisirEglise() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EcranChoixVillages(modeModification: true),
      ),
    );
    setState(() => _chargement = true);
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live & VOD')),
      body: _contenu(),
    );
  }

  Widget _contenu() {
    if (_chargement) {
      return const Center(
        child: CircularProgressIndicator(color: EpuiciColors.primaire),
      );
    }

    if (_erreur.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_erreur, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: _charger, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: EpuiciColors.primaire,
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _lecteurDirect(),
          if (!_aucuneEglise)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _BadgeDirect(enCours: _directEnCours),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _nomEglise,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_directEnCours && _lienDirect.isNotEmpty)
                    _BoutonOuvrirExterne(lien: _lienDirect),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Vidéos', style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_videos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Aucune vidéo pour le moment.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          for (final video in _videos) _carteVideo(video),
        ],
      ),
    );
  }

  Widget _lecteurDirect() {
    final afficherLecteur = _directEnCours && _lienDirect.isNotEmpty && widget.actif;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Colors.black,
        child: afficherLecteur
            ? LecteurIntegre(key: ValueKey('direct-$_lienDirect'), lien: _lienDirect)
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.live_tv_outlined,
                        color: Colors.white.withValues(alpha: 0.6), size: 44),
                    const SizedBox(height: 10),
                    const Text(
                      'Direct terminé',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Le direct dépend de l'église du fidèle.
                    if (_aucuneEglise)
                      TextButton(
                        onPressed: _choisirEglise,
                        child: const Text(
                          'Choisir mon église pour suivre ses directs',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _carteVideo(Map<String, dynamic> video) {
    final id = video['_id']?.toString() ?? '';
    final lien = video['lien']?.toString() ?? '';
    final titre = video['titre']?.toString() ?? '';
    final enLecture = _videoEnLecture == id && widget.actif;
    final miniature = LienVideo.miniature(lien);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: enLecture
                  ? LecteurIntegre(key: ValueKey(id), lien: lien, lectureAuto: true)
                  : GestureDetector(
                      onTap: () => setState(() => _videoEnLecture = id),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (miniature != null)
                            CachedNetworkImage(
                              imageUrl: miniature,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) =>
                                  const ColoredBox(color: Colors.black87),
                            )
                          else
                            const ColoredBox(color: Colors.black87),
                          Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow,
                                  color: Colors.white, size: 36),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  titre,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              if (enLecture && !LienVideo.estFichierVideo(lien))
                _BoutonOuvrirExterne(lien: lien),
            ],
          ),
        ],
      ),
    );
  }
}

// Ouvre la vidéo dans l'application YouTube / Facebook si le lecteur intégré
// ne peut pas la lire.
class _BoutonOuvrirExterne extends StatelessWidget {
  final String lien;

  const _BoutonOuvrirExterne({required this.lien});

  @override
  Widget build(BuildContext context) {
    final libelle = LienVideo.estFacebook(lien) ? 'Facebook' : 'YouTube';
    return TextButton.icon(
      onPressed: () => ouvrirLienExterne(lien),
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text('Regarder sur $libelle'),
      style: TextButton.styleFrom(
        foregroundColor: EpuiciColors.primaire,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _BadgeDirect extends StatelessWidget {
  final bool enCours;

  const _BadgeDirect({required this.enCours});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: enCours ? Colors.red : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: enCours ? Colors.white : Colors.grey.shade600),
          const SizedBox(width: 5),
          Text(
            enCours ? 'EN DIRECT' : 'HORS DIRECT',
            style: TextStyle(
              color: enCours ? Colors.white : Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
