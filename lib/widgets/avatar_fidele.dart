import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';

// Photo de profil du fidèle, ou l'initiale de son nom à défaut
class AvatarFidele extends StatelessWidget {
  final String nom;
  final String? photo;
  final double rayon;

  const AvatarFidele({super.key, required this.nom, this.photo, this.rayon = 20});

  @override
  Widget build(BuildContext context) {
    final aPhoto = photo != null && photo!.isNotEmpty;
    final initiale = nom.trim().isNotEmpty ? nom.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: rayon,
      backgroundColor: EpuiciColors.primaire.withValues(alpha: 0.12),
      backgroundImage: aPhoto ? CachedNetworkImageProvider(photo!) : null,
      child: aPhoto
          ? null
          : Text(
              initiale,
              style: TextStyle(
                color: EpuiciColors.primaire,
                fontWeight: FontWeight.w700,
                fontSize: rayon * 0.8,
              ),
            ),
    );
  }
}

// "14:05" aujourd'hui, "Hier", sinon "12/10"
String libelleDateCourte(DateTime date) {
  final local = date.toLocal();
  final maintenant = DateTime.now();
  final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
  final jour = DateTime(local.year, local.month, local.day);
  final ecart = aujourdhui.difference(jour).inDays;
  if (ecart == 0) return _heure(local);
  if (ecart == 1) return 'Hier';
  return '${_deuxChiffres(local.day)}/${_deuxChiffres(local.month)}';
}

// Séparateur de jour dans une discussion : "Aujourd'hui", "Hier", "12/10/2026"
String libelleJour(DateTime date) {
  final local = date.toLocal();
  final maintenant = DateTime.now();
  final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
  final jour = DateTime(local.year, local.month, local.day);
  final ecart = aujourdhui.difference(jour).inDays;
  if (ecart == 0) return "Aujourd'hui";
  if (ecart == 1) return 'Hier';
  return '${_deuxChiffres(local.day)}/${_deuxChiffres(local.month)}/${local.year}';
}

String libelleHeure(DateTime date) => _heure(date.toLocal());

String _heure(DateTime d) => '${_deuxChiffres(d.hour)}:${_deuxChiffres(d.minute)}';
String _deuxChiffres(int n) => n.toString().padLeft(2, '0');
