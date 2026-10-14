import 'package:flutter/material.dart';

// Version native (non distribuée) : la lecture des directs et vidéos
// intégrés n'est disponible que dans la PWA.
class LecteurIntegre extends StatelessWidget {
  final String lien;
  final bool lectureAuto;

  const LecteurIntegre({super.key, required this.lien, this.lectureAuto = false});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          'Lecture disponible dans la version web.',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

// Version native (non distribuée) : sans effet.
void ouvrirLienExterne(String lien) {}
