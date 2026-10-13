import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/article_model.dart';
import '../services/api_service.dart';

class EcranDetailArticle extends StatefulWidget {
  final String articleId;

  const EcranDetailArticle({super.key, required this.articleId});

  @override
  State<EcranDetailArticle> createState() => _EcranDetailArticleState();
}

class _EcranDetailArticleState extends State<EcranDetailArticle> {
  Article? _article;
  bool _chargement = true;
  bool _dejaLike = false;
  final PageController _pageController = PageController();
  int _pagePhotoActive = 0;
  Timer? _timerDefilement;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _timerDefilement?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Fait défiler automatiquement les photos toutes les 5 secondes
  void _demarrerDefilement() {
    _timerDefilement?.cancel();
    if (_article == null || _article!.photos.length < 2) return;
    _timerDefilement = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final suivante = (_pagePhotoActive + 1) % _article!.photos.length;
      _pageController.animateToPage(
        suivante,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _charger() async {
    try {
      final article = await ApiService.obtenirArticle(widget.articleId);
      setState(() {
        _article = article;
        _chargement = false;
      });
      _demarrerDefilement();
    } catch (e) {
      setState(() => _chargement = false);
    }
  }

  Future<void> _liker() async {
    if (_dejaLike || _article == null) return;
    try {
      final nouveauxLikes = await ApiService.likerArticle(_article!.id);
      setState(() {
        _dejaLike = true;
        _article = Article(
          id: _article!.id,
          titre: _article!.titre,
          contenu: _article!.contenu,
          categorie: _article!.categorie,
          photos: _article!.photos,
          vues: _article!.vues,
          likes: nouveauxLikes,
          creeLe: _article!.creeLe,
          villageNom: _article!.villageNom,
        );
      });
    } catch (e) {
      // silencieux
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: EpuiciColors.primaire)),
      );
    }

    if (_article == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail')),
        body: const Center(child: Text('Article introuvable.')),
      );
    }

    final article = _article!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.photos.isNotEmpty) ...[
              SizedBox(
                height: 240,
                // Un swipe manuel relance le compteur de 5 secondes
                child: Listener(
                  onPointerDown: (_) => _demarrerDefilement(),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: article.photos.length,
                    onPageChanged: (index) => setState(() => _pagePhotoActive = index),
                    itemBuilder: (context, index) => CachedNetworkImage(
                      imageUrl: article.photos[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(color: Colors.grey.shade100),
                    ),
                  ),
                ),
              ),
              if (article.photos.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      article.photos.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _pagePhotoActive ? EpuiciColors.primaire : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.villageNom != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EpuiciColors.primaire,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.villageNom!,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    article.titre,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.tempsEcoule(),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article.contenu,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _liker,
                        child: Row(
                          children: [
                            Icon(
                              _dejaLike ? Icons.favorite : Icons.favorite_border,
                              color: _dejaLike ? Colors.red : Colors.grey.shade500,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text('${article.likes}', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Icon(Icons.remove_red_eye_outlined, size: 20, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text('${article.vues}', style: TextStyle(color: Colors.grey.shade600)),
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
