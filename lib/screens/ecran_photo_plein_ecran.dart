import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// Photo d'un groupe en plein écran, zoomable avec deux doigts
class EcranPhotoPleinEcran extends StatelessWidget {
  final String url;
  final String? legende;
  final String? auteur;

  const EcranPhotoPleinEcran({super.key, required this.url, this.legende, this.auteur});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: auteur != null ? Text(auteur!, style: const TextStyle(color: Colors.white)) : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, erreur) =>
                      const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                ),
              ),
            ),
          ),
          if (legende != null && legende!.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(legende!, style: const TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }
}
