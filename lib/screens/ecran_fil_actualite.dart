import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/article_model.dart';
import '../models/village_model.dart';
import '../services/api_service.dart';
import '../services/stockage_local.dart';
import '../widgets/animations.dart';
import '../widgets/carrousel_photos.dart';
import 'ecran_choix_villages.dart';
import 'ecran_detail_article.dart';

class EcranFilActualite extends StatefulWidget {
  const EcranFilActualite({super.key});

  @override
  State<EcranFilActualite> createState() => _EcranFilActualiteState();
}

class _EcranFilActualiteState extends State<EcranFilActualite> {
  List<Village> _mesVillages = [];
  List<Article> _articles = [];
  List<String> _bannieresPub = [];
  bool _chargement = true;
  String _erreur = '';
  bool _aucuneEglise = false;
  int _ongletActif = 0; // 0 = "Pour vous" (tous), sinon index+1 = village précis

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = '';
    });
    try {
      final idsSuivis = await StockageLocal.obtenirVillagesSuivis();
      if (idsSuivis.isEmpty) {
        setState(() {
          _aucuneEglise = true;
          _mesVillages = [];
          _articles = [];
          _chargement = false;
        });
        return;
      }
      _aucuneEglise = false;
      final tousLesVillages = await ApiService.listerVillages();
      final mesVillages = tousLesVillages.where((v) => idsSuivis.contains(v.id)).toList();

      List<Article> articles;
      if (_ongletActif == 0) {
        articles = await ApiService.filDActualite(idsSuivis);
      } else {
        final village = mesVillages[_ongletActif - 1];
        articles = await ApiService.articlesParVillage(village.id);
      }

      // Les bandes pub ne doivent jamais empêcher l'affichage des articles
      List<String> bannieres;
      try {
        bannieres = await ApiService.listerBannieresPub();
      } catch (_) {
        bannieres = [];
      }

      setState(() {
        _mesVillages = mesVillages;
        _articles = articles;
        _bannieresPub = bannieres;
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur = "Impossible de charger les actualités.";
        _chargement = false;
      });
    }
  }

  void _changerOnglet(int index) {
    setState(() => _ongletActif = index);
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarEpuici(
        titre: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Image.asset('assets/images/logo.png', height: 30),
            ),
            const SizedBox(width: 10),
            const Text('EPUICI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _barreOnglets(),
          Expanded(child: _contenu()),
        ],
      ),
    );
  }

  Widget _barreOnglets() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        children: [
          _onglet('Pour vous', 0),
          ..._mesVillages.asMap().entries.map(
                (entree) => _onglet(entree.value.nom, entree.key + 1),
              ),
        ],
      ),
    );
  }

  Widget _onglet(String label, int index) {
    final actif = _ongletActif == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: GestureDetector(
        onTap: () => _changerOnglet(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: actif ? degradeEpuici : null,
            color: actif ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: actif ? Colors.transparent : Colors.grey.shade300),
            boxShadow: actif
                ? [
                    BoxShadow(
                      color: EpuiciColors.primaire.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: actif ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenu() {
    if (_chargement) {
      return const ListeSquelettes();
    }
    if (_aucuneEglise) {
      return EtatVide(
        icone: Icons.church_rounded,
        message: 'Choisissez votre église pour suivre ses actualités.',
        libelleAction: 'Choisir mon église',
        onAction: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const EcranChoixVillages(modeModification: true),
            ),
          );
          _charger();
        },
      );
    }
    if (_erreur.isNotEmpty) {
      return EtatVide(
        icone: Icons.wifi_off_rounded,
        message: _erreur,
        libelleAction: 'Réessayer',
        onAction: _charger,
      );
    }
    final aBandePub = _bannieresPub.isNotEmpty;

    if (_articles.isEmpty && !aBandePub) {
      return RefreshIndicator(
        onRefresh: _charger,
        color: EpuiciColors.primaire,
        child: const EtatVide(
          icone: Icons.newspaper_rounded,
          message: 'Aucune actualité pour le moment.\nTirez vers le bas pour actualiser.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _charger,
      color: EpuiciColors.primaire,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (aBandePub) Apparition(child: _bandePub()),
          if (_articles.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('Aucune actualité pour le moment.')),
            ),
          for (var i = 0; i < _articles.length; i++)
            Apparition(index: i + 1, child: _carteArticle(_articles[i])),
        ],
      ),
    );
  }

  // Bande pub au format banderole (4:1), placée avant les articles
  Widget _bandePub() {
    return LayoutBuilder(
      builder: (context, contraintes) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CarrouselPhotos(
            key: ValueKey(_bannieresPub.join(',')),
            photos: _bannieresPub,
            height: contraintes.maxWidth / 4,
          ),
        ),
      ),
    );
  }

  Widget _carteArticle(Article article) {
    return TapAnime(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EcranDetailArticle(articleId: article.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: EpuiciColors.primaire.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  if (article.villageNom != null)
                    Flexible(child: _etiquetteEglise(article.villageNom!)),
                  const Spacer(),
                  Icon(Icons.schedule_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text(
                    article.tempsEcoule(),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (article.photos.isNotEmpty)
              CarrouselPhotos(
                key: ValueKey(article.id),
                photos: article.photos,
                height: 190,
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.titre,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.contenu,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _pastille(Icons.favorite_rounded, '${article.likes}', Colors.pink.shade400),
                      const SizedBox(width: 8),
                      _pastille(Icons.visibility_rounded, '${article.vues}', EpuiciColors.primaire),
                      const Spacer(),
                      const Text(
                        'Lire la suite',
                        style: TextStyle(
                          color: EpuiciColors.primaire,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: EpuiciColors.primaire),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Église de l'article : petit logo + nom sur fond dégradé.
  Widget _etiquetteEglise(String nom) {
    return Container(
      padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
      decoration: BoxDecoration(
        gradient: degradeEpuici,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(1),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Image.asset('assets/images/logo.png', width: 18, height: 18),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              nom,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // Petit compteur arrondi (mentions j'aime, vues) sous un article.
  Widget _pastille(IconData icone, String valeur, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: couleur),
          const SizedBox(width: 4),
          Text(valeur, style: TextStyle(color: couleur, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
