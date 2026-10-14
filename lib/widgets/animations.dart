import 'dart:async';

import 'package:flutter/material.dart';
import '../config/theme.dart';

// Briques visuelles communes aux écrans : apparitions en cascade, effet de
// pression, en-têtes en dégradé, squelettes de chargement et états vides.

// Fait apparaître son enfant en fondu en glissant légèrement vers le haut.
// [index] décale le départ pour un effet de cascade dans les listes.
class Apparition extends StatefulWidget {
  final Widget child;
  final int index;

  const Apparition({super.key, required this.child, this.index = 0});

  @override
  State<Apparition> createState() => _ApparitionState();
}

class _ApparitionState extends State<Apparition> with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _courbe =
      CurvedAnimation(parent: _controleur, curve: Curves.easeOutCubic);
  Timer? _delai;

  @override
  void initState() {
    super.initState();
    // Cascade plafonnée : les éléments loin dans la liste n'attendent pas.
    final attente = Duration(milliseconds: 70 * widget.index.clamp(0, 6));
    _delai = Timer(attente, () {
      if (mounted) _controleur.forward();
    });
  }

  @override
  void dispose() {
    _delai?.cancel();
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _courbe,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(_courbe),
        child: widget.child,
      ),
    );
  }
}

// Rétrécit légèrement son enfant pendant l'appui, pour un retour tactile.
class TapAnime extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const TapAnime({super.key, required this.child, this.onTap});

  @override
  State<TapAnime> createState() => _TapAnimeState();
}

class _TapAnimeState extends State<TapAnime> {
  bool _appuye = false;

  void _changer(bool valeur) {
    if (widget.onTap != null) setState(() => _appuye = valeur);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _changer(true),
      onTapUp: (_) => _changer(false),
      onTapCancel: () => _changer(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _appuye ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// Dégradé de marque utilisé par les en-têtes.
const degradeEpuici = LinearGradient(
  colors: [EpuiciColors.primaire, EpuiciColors.primaireClair],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Barre d'en-tête en dégradé bleu, titre blanc.
class AppBarEpuici extends StatelessWidget implements PreferredSizeWidget {
  final Widget titre;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const AppBarEpuici({super.key, required this.titre, this.actions, this.bottom});

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titre,
      actions: actions,
      bottom: bottom,
      foregroundColor: Colors.white,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: 22,
          ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: degradeEpuici,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
    );
  }
}

// Bloc gris animé d'un reflet, pour simuler un contenu en cours de chargement.
class Squelette extends StatefulWidget {
  final double hauteur;
  final double? largeur;
  final double rayon;

  const Squelette({super.key, required this.hauteur, this.largeur, this.rayon = 10});

  @override
  State<Squelette> createState() => _SqueletteState();
}

class _SqueletteState extends State<Squelette> with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controleur,
      builder: (context, _) {
        final t = _controleur.value * 3 - 1; // le reflet traverse de gauche à droite
        return Container(
          height: widget.hauteur,
          width: widget.largeur,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.rayon),
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t + 1, 0),
              colors: [Colors.grey.shade200, Colors.grey.shade100, Colors.grey.shade200],
            ),
          ),
        );
      },
    );
  }
}

// Liste de cartes squelettes affichée pendant le chargement d'un fil.
class ListeSquelettes extends StatelessWidget {
  final int nombre;
  final bool avecImage;

  const ListeSquelettes({super.key, this.nombre = 3, this.avecImage = true});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nombre,
      itemBuilder: (context, _) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Squelette(hauteur: 36, largeur: 36, rayon: 18),
                SizedBox(width: 10),
                Squelette(hauteur: 14, largeur: 120),
              ],
            ),
            if (avecImage) ...[
              const SizedBox(height: 12),
              const Squelette(hauteur: 160, rayon: 12),
            ],
            const SizedBox(height: 12),
            const Squelette(hauteur: 14),
            const SizedBox(height: 8),
            const Squelette(hauteur: 14, largeur: 200),
          ],
        ),
      ),
    );
  }
}

// Écran vide ou d'invitation : grande icône dans un halo, message, action.
class EtatVide extends StatelessWidget {
  final IconData icone;
  final String message;
  final String? libelleAction;
  final VoidCallback? onAction;

  const EtatVide({
    super.key,
    required this.icone,
    required this.message,
    this.libelleAction,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Apparition(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EpuiciColors.primaire.withValues(alpha: 0.08),
                ),
                child: Icon(icone, size: 44, color: EpuiciColors.primaire),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
              ),
              if (libelleAction != null && onAction != null) ...[
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EpuiciColors.primaire,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  child: Text(libelleAction!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
