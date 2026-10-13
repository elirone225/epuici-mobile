import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/article_model.dart';
import '../models/village_model.dart';
import '../services/api_service.dart';
import '../services/stockage_local.dart';
import '../widgets/carrousel_photos.dart';
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
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 32),
            const SizedBox(width: 8),
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
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: actif ? EpuiciColors.primaire : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
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
      return const Center(child: CircularProgressIndicator(color: EpuiciColors.primaire));
    }
    if (_erreur.isNotEmpty) {
      return Center(child: Text(_erreur));
    }
    final aBandePub = _bannieresPub.isNotEmpty;

    if (_articles.isEmpty && !aBandePub) {
      return const Center(child: Text('Aucune actualité pour le moment.'));
    }

    return RefreshIndicator(
      onRefresh: _charger,
      color: EpuiciColors.primaire,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (aBandePub) _bandePub(),
          if (_articles.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('Aucune actualité pour le moment.')),
            ),
          ..._articles.map(_carteArticle),
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
          borderRadius: BorderRadius.circular(14),
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
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EcranDetailArticle(articleId: article.id)),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                if (article.villageNom != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: EpuiciColors.primaire,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.villageNom!,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                const Spacer(),
                Text(article.tempsEcoule(), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          if (article.photos.isNotEmpty)
            CarrouselPhotos(
              key: ValueKey(article.id),
              photos: article.photos,
              height: 180,
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.titre,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  article.contenu,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 18, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${article.likes}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    const SizedBox(width: 16),
                    Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${article.vues}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
}
