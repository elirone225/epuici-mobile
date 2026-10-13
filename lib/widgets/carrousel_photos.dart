import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';

// Carrousel de photos qui défile automatiquement toutes les 5 secondes,
// avec indicateurs (points) superposés en bas de l'image.
class CarrouselPhotos extends StatefulWidget {
  final List<String> photos;
  final double height;

  const CarrouselPhotos({super.key, required this.photos, this.height = 180});

  @override
  State<CarrouselPhotos> createState() => _CarrouselPhotosState();
}

class _CarrouselPhotosState extends State<CarrouselPhotos> {
  final PageController _pageController = PageController();
  int _pagePhotoActive = 0;
  Timer? _timerDefilement;

  @override
  void initState() {
    super.initState();
    _demarrerDefilement();
  }

  @override
  void dispose() {
    _timerDefilement?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _demarrerDefilement() {
    _timerDefilement?.cancel();
    if (widget.photos.length < 2) return;
    _timerDefilement = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final suivante = (_pagePhotoActive + 1) % widget.photos.length;
      _pageController.animateToPage(
        suivante,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          // Un swipe manuel relance le compteur de 5 secondes
          Listener(
            onPointerDown: (_) => _demarrerDefilement(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) => setState(() => _pagePhotoActive = index),
              itemBuilder: (context, index) => CachedNetworkImage(
                imageUrl: widget.photos[index],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(color: Colors.grey.shade100),
                errorWidget: (context, url, error) => Container(color: Colors.grey.shade100),
              ),
            ),
          ),
          if (widget.photos.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.photos.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _pagePhotoActive ? EpuiciColors.primaire : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
