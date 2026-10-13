import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/pub_reportage_model.dart';
import '../services/api_service.dart';
import '../services/stockage_local.dart';
import '../widgets/lecteur_video.dart';
import 'ecran_connexion.dart';

// Fil vertical plein écran des vidéos "Pub et Reportage" publiées par le
// Super Admin (défilement type TikTok : une vidéo par page, swipe vertical).
class EcranPubReportage extends StatefulWidget {
  // Indique si cet onglet est actuellement affiché par la navigation
  // principale (qui garde tous les onglets vivants via IndexedStack).
  // Permet de couper la lecture quand l'utilisateur va sur un autre onglet.
  final bool actif;

  const EcranPubReportage({super.key, this.actif = true});

  @override
  State<EcranPubReportage> createState() => _EcranPubReportageState();
}

class _EcranPubReportageState extends State<EcranPubReportage> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  List<PubReportage> _videos = [];
  bool _chargement = true;
  int _indexPageActive = 0;
  bool _appAuPremierPlan = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _charger();
  }

  Future<void> _charger() async {
    try {
      final videos = await ApiService.listerPubReportages();
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _appAuPremierPlan = state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lectureAutorisee = widget.actif && _appAuPremierPlan;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _videos.isEmpty
              ? const Center(
                  child: Text(
                    'Aucune vidéo pour le moment.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _videos.length,
                  onPageChanged: (index) => setState(() => _indexPageActive = index),
                  itemBuilder: (context, index) => _PageVideo(
                    video: _videos[index],
                    actif: lectureAutorisee && index == _indexPageActive,
                  ),
                ),
    );
  }
}

class _PageVideo extends StatefulWidget {
  final PubReportage video;
  final bool actif;

  const _PageVideo({required this.video, required this.actif});

  @override
  State<_PageVideo> createState() => _PageVideoState();
}

class _PageVideoState extends State<_PageVideo> {
  LecteurVideoControleur? _controleur;
  bool _initialise = false;
  bool _erreur = false;
  late PubReportage _video;
  bool _dejaLike = false;
  bool _vueEnregistree = false;
  bool _sonCoupe = false;

  @override
  void initState() {
    super.initState();
    _video = widget.video;
    _initialiser();
  }

  Future<void> _initialiser() async {
    final controleur = LecteurVideoControleur(_video.videoUrl);
    _controleur = controleur;
    try {
      await controleur.initialiser().timeout(const Duration(seconds: 20));
      await controleur.setLooping(true);
      await controleur.setVolume(_sonCoupe ? 0 : 1);
      if (!mounted) return;
      setState(() => _initialise = true);
      if (widget.actif) controleur.play();
      _enregistrerVueSiNecessaire();
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = true);
    }
  }

  void _enregistrerVueSiNecessaire() {
    if (_vueEnregistree || !_initialise || !widget.actif) return;
    _vueEnregistree = true;
    ApiService.enregistrerVuePubReportage(_video.id).then((nouvellesVues) {
      if (!mounted) return;
      setState(() => _video = _video.copierAvec(vues: nouvellesVues));
    }).catchError((_) {});
  }

  void _basculerSon() {
    final controleur = _controleur;
    if (controleur == null || !_initialise) return;
    setState(() {
      _sonCoupe = !_sonCoupe;
      controleur.setVolume(_sonCoupe ? 0 : 1);
    });
  }

  Future<void> _reessayer() async {
    setState(() {
      _erreur = false;
      _initialise = false;
    });
    await _controleur?.dispose();
    await _initialiser();
  }

  @override
  void didUpdateWidget(covariant _PageVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controleur = _controleur;
    if (controleur == null || !_initialise) return;

    if (widget.actif && !oldWidget.actif) {
      controleur.play();
      _enregistrerVueSiNecessaire();
    } else if (!widget.actif && oldWidget.actif) {
      controleur.pause();
      controleur.seekToZero();
    }
  }

  void _basculerLecture() {
    final controleur = _controleur;
    if (controleur == null || !_initialise) return;
    setState(() {
      controleur.enLecture ? controleur.pause() : controleur.play();
    });
  }

  Future<void> _liker() async {
    if (_dejaLike) return;
    setState(() => _dejaLike = true);
    try {
      final nouveauxLikes = await ApiService.likerPubReportage(_video.id);
      if (!mounted) return;
      setState(() => _video = _video.copierAvec(likes: nouveauxLikes));
    } catch (e) {
      if (!mounted) return;
      setState(() => _dejaLike = false);
    }
  }

  void _ouvrirCommentaires() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeuilleCommentaires(
        pubReportageId: _video.id,
        onCommentaireAjoute: () {
          if (!mounted) return;
          setState(() => _video = _video.copierAvec(nombreCommentaires: _video.nombreCommentaires + 1));
        },
      ),
    );
  }

  @override
  void dispose() {
    _controleur?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controleur = _controleur;

    return GestureDetector(
      onTap: _basculerLecture,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Le lecteur est monté dès que le contrôleur existe, même avant la
          // fin du chargement (juste invisible via opacité). Sur mobile,
          // certains navigateurs mettent en pause le chargement d'un élément
          // vidéo qui n'est jamais réellement attaché/affiché à l'écran, ce
          // qui bloquait indéfiniment le chargement quand le widget n'était
          // monté qu'une fois l'initialisation terminée.
          if (controleur != null)
            Opacity(
              opacity: _initialise ? 1 : 0,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controleur.estInitialise ? controleur.largeur : 100,
                  height: controleur.estInitialise ? controleur.hauteur : 100,
                  child: controleur.construireVue(),
                ),
              ),
            ),

          if (_erreur)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white54, size: 40),
                  const SizedBox(height: 12),
                  const Text('Impossible de lire cette vidéo.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _reessayer,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else if (!_initialise)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          if (_initialise && controleur != null && !controleur.enLecture)
            const Center(
              child: Icon(Icons.play_arrow, color: Colors.white70, size: 72),
            ),

          if (_initialise)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _basculerSon,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _sonCoupe ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

          // Dégradé sombre en bas pour la lisibilité du texte
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                ),
              ),
            ),
          ),

          // Colonne d'actions à droite : liker, commenter
          Positioned(
            right: 12,
            bottom: 90,
            child: Column(
              children: [
                _BoutonAction(
                  icone: Icons.remove_red_eye_outlined,
                  couleur: Colors.white,
                  libelle: '${_video.vues}',
                ),
                const SizedBox(height: 22),
                _BoutonAction(
                  icone: _dejaLike ? Icons.favorite : Icons.favorite_border,
                  couleur: _dejaLike ? Colors.red : Colors.white,
                  libelle: '${_video.likes}',
                  onTap: _liker,
                ),
                const SizedBox(height: 22),
                _BoutonAction(
                  icone: Icons.chat_bubble_outline,
                  couleur: Colors.white,
                  libelle: '${_video.nombreCommentaires}',
                  onTap: _ouvrirCommentaires,
                ),
              ],
            ),
          ),

          Positioned(
            left: 16,
            right: 80,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: EpuiciColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _video.labelType,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _video.titre,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (_video.description != null && _video.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _video.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ],
                if (_video.villageNom != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(_video.villageNom!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoutonAction extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String libelle;
  final VoidCallback? onTap;

  const _BoutonAction({
    required this.icone,
    required this.couleur,
    required this.libelle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icone, color: couleur, size: 32),
          const SizedBox(height: 4),
          Text(libelle, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final double taille;

  const _Avatar({required this.url, required this.taille});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: taille / 2,
        backgroundColor: EpuiciColors.primaire.withValues(alpha: 0.1),
        child: Icon(Icons.person, size: taille * 0.55, color: EpuiciColors.primaire),
      );
    }
    return CircleAvatar(
      radius: taille / 2,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: CachedNetworkImageProvider(url!),
    );
  }
}

class _FeuilleCommentaires extends StatefulWidget {
  final String pubReportageId;
  final VoidCallback onCommentaireAjoute;

  const _FeuilleCommentaires({required this.pubReportageId, required this.onCommentaireAjoute});

  @override
  State<_FeuilleCommentaires> createState() => _FeuilleCommentairesState();
}

class _FeuilleCommentairesState extends State<_FeuilleCommentaires> {
  final TextEditingController _controleurTexte = TextEditingController();
  final FocusNode _focusTexte = FocusNode();
  List<PubReportageCommentaire> _commentaires = [];
  bool _chargement = true;
  bool _envoi = false;
  PubReportageCommentaire? _repondreA;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  // Regroupe les commentaires : chaque commentaire racine est suivi de
  // toutes ses réponses (même les réponses à une réponse), les plus
  // anciennes en premier, pour un affichage en fil simple à lire.
  List<PubReportageCommentaire> get _commentairesOrdonnes {
    final parId = {for (final c in _commentaires) c.id: c};

    String racineDe(PubReportageCommentaire c) {
      var actuel = c;
      final vus = <String>{};
      while (actuel.repondreAId != null &&
          parId.containsKey(actuel.repondreAId) &&
          vus.add(actuel.id)) {
        actuel = parId[actuel.repondreAId]!;
      }
      return actuel.id;
    }

    final racines = _commentaires.where((c) => c.repondreAId == null).toList();
    final resultat = <PubReportageCommentaire>[];
    for (final racine in racines) {
      resultat.add(racine);
      final enfants = _commentaires
          .where((c) => c.id != racine.id && racineDe(c) == racine.id)
          .toList()
        ..sort((a, b) => a.creeLe.compareTo(b.creeLe));
      resultat.addAll(enfants);
    }

    // Filet de sécurité : un commentaire dont le parent n'existe plus.
    final idsInclus = resultat.map((c) => c.id).toSet();
    resultat.addAll(_commentaires.where((c) => !idsInclus.contains(c.id)));
    return resultat;
  }

  Future<void> _charger() async {
    try {
      final commentaires = await ApiService.listerCommentairesPubReportage(widget.pubReportageId);
      if (!mounted) return;
      setState(() {
        _commentaires = commentaires;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _envoyer() async {
    final texte = _controleurTexte.text.trim();
    if (texte.isEmpty) return;

    if (!await StockageLocal.estConnecte()) {
      if (!mounted) return;
      _demanderConnexion();
      return;
    }

    setState(() => _envoi = true);
    try {
      final commentaire = await ApiService.ajouterCommentairePubReportage(
        id: widget.pubReportageId,
        texte: texte,
        repondreA: _repondreA?.id,
      );
      if (!mounted) return;
      setState(() {
        _commentaires.insert(0, commentaire);
        _controleurTexte.clear();
        _repondreA = null;
      });
      widget.onCommentaireAjoute();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _repondre(PubReportageCommentaire commentaire) {
    setState(() => _repondreA = commentaire);
    _focusTexte.requestFocus();
  }

  void _demanderConnexion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text('Vous devez avoir un compte et être connecté pour commenter.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EcranConnexion()),
              );
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controleurTexte.dispose();
    _focusTexte.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentaires = _commentairesOrdonnes;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Commentaires', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              const Divider(height: 1),
              Expanded(
                child: _chargement
                    ? const Center(child: CircularProgressIndicator(color: EpuiciColors.primaire))
                    : commentaires.isEmpty
                        ? const Center(
                            child: Text('Soyez le premier à commenter.', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: commentaires.length,
                            itemBuilder: (context, index) {
                              final c = commentaires[index];
                              final estReponse = c.repondreAId != null;
                              return Padding(
                                padding: EdgeInsets.only(top: 8, bottom: 8, left: estReponse ? 36 : 0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _Avatar(url: c.auteurPhoto, taille: estReponse ? 26 : 32),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(c.auteurNom, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                              const SizedBox(width: 8),
                                              Text(c.tempsEcoule(), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                            ],
                                          ),
                                          if (c.repondreANom != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'en réponse à ${c.repondreANom}',
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
                                            ),
                                          ],
                                          const SizedBox(height: 2),
                                          Text(c.texte, style: const TextStyle(fontSize: 14)),
                                          const SizedBox(height: 2),
                                          GestureDetector(
                                            onTap: () => _repondre(c),
                                            child: Text(
                                              'Répondre',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_repondreA != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Réponse à ${_repondreA!.auteurNom}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _repondreA = null),
                                child: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controleurTexte,
                              focusNode: _focusTexte,
                              decoration: InputDecoration(
                                hintText: _repondreA != null
                                    ? 'Répondre à ${_repondreA!.auteurNom}...'
                                    : 'Ajouter un commentaire...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _envoi ? null : _envoyer,
                            icon: _envoi
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: EpuiciColors.primaire),
                                  )
                                : const Icon(Icons.send, color: EpuiciColors.primaire),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
