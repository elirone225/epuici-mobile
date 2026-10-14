import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/stockage_local.dart';
import '../widgets/animations.dart';
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
      appBar: const AppBarEpuici(titre: Text('Live & VOD')),
      body: _contenu(),
    );
  }

  Widget _contenu() {
    if (_chargement) {
      return const ListeSquelettes(nombre: 2);
    }

    if (_erreur.isNotEmpty) {
      return EtatVide(
        icone: Icons.wifi_off_rounded,
        message: _erreur,
        libelleAction: 'Réessayer',
        onAction: _charger,
      );
    }

    return RefreshIndicator(
      color: EpuiciColors.primaire,
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Apparition(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _lecteurDirect(),
            ),
          ),
          if (!_aucuneEglise)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
            child: Row(
              children: [
                const Icon(Icons.video_library_rounded, color: EpuiciColors.primaire, size: 22),
                const SizedBox(width: 8),
                Text('Vidéos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 19)),
                const SizedBox(width: 8),
                if (_videos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: EpuiciColors.primaire.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_videos.length}',
                      style: const TextStyle(
                        color: EpuiciColors.primaire,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_videos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Aucune vidéo pour le moment.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          for (var i = 0; i < _videos.length; i++)
            Apparition(index: i + 1, child: _carteVideo(_videos[i])),
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
            ? Stack(
                children: [
                  Positioned.fill(
                    child: LecteurIntegre(
                      key: ValueKey('direct-$_lienDirect'),
                      lien: _lienDirect,
                      // Le direct démarre dès que le fidèle ouvre l'onglet.
                      lectureAuto: true,
                    ),
                  ),
                  // Logo et nom de l'église en haut à gauche du direct.
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 60,
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: _SignatureEglise(nom: _nomEglise),
                      ),
                    ),
                  ),
                ],
              )
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

// Logo EPUICI + nom de l'église, incrusté sur le lecteur pendant le direct.
class _SignatureEglise extends StatelessWidget {
  final String nom;

  const _SignatureEglise({required this.nom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo.png', width: 26, height: 26),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              nom,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
