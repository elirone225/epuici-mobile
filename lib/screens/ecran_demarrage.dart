import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/stockage_local.dart';
import 'ecran_connexion.dart';
import 'navigation_principale.dart';

// Splash screen affiché au démarrage de l'application (8 secondes, le temps
// que les données chargent) :
//   1. la carte de la Côte d'Ivoire apparaît ;
//   2. de petits logos apparaissent un à un dans les villes du pays ;
//   3. ils se rassemblent au centre pour former un gros logo qui tourne ;
// puis redirige vers l'accueil si l'utilisateur est déjà connecté, sinon
// vers l'écran de connexion.
class EcranDemarrage extends StatefulWidget {
  const EcranDemarrage({super.key});

  @override
  State<EcranDemarrage> createState() => _EcranDemarrageState();
}

// Ville affichée sur la carte (coordonnées géographiques).
class _Ville {
  final String nom;
  final double longitude;
  final double latitude;
  // Nom affiché au-dessus du logo plutôt qu'en dessous (évite les chevauchements).
  final bool nomAuDessus;
  const _Ville(this.nom, this.longitude, this.latitude,
      {this.nomAuDessus = false});
}

class _EcranDemarrageState extends State<EcranDemarrage>
    with TickerProviderStateMixin {
  // Durée totale du splash : laisse le temps aux données de charger.
  static const _dureeSplash = Duration(seconds: 8);

  // Villes où apparaissent les petits logos, dans l'ordre d'apparition.
  static const _villes = [
    _Ville('Abidjan', -4.03, 5.36),
    _Ville('Yamoussoukro', -5.28, 6.82),
    _Ville('Bouaké', -5.03, 7.69, nomAuDessus: true),
    _Ville('Korhogo', -5.63, 9.46),
    _Ville('Man', -7.55, 7.41),
    _Ville('San-Pédro', -6.64, 4.85),
    _Ville('Daloa', -6.45, 6.88),
    _Ville('Odienné', -7.56, 9.51),
    _Ville('Bondoukou', -2.85, 8.04),
    _Ville('Divo', -5.36, 5.84),
    _Ville('Abengourou', -3.50, 6.73),
    _Ville('Séguéla', -6.67, 7.96),
  ];

  // Chronologie (en fraction des 8 secondes).
  static const _finCarte = 0.15; // 0 → 1,2 s : la carte apparaît
  static const _debutVilles = 0.15; // 1,2 → 4,4 s : logos dans les villes
  static const _finVilles = 0.55;
  static const _dureePopVille = 0.06;
  static const _debutRassemblement = 0.58; // 4,6 → 6 s : rassemblement
  static const _finRassemblement = 0.75;

  // Séquence complète du splash.
  late final AnimationController _controleurSequence;
  // Rotation continue des logos.
  late final AnimationController _controleurRotation;

  late final Animation<double> _opaciteCarte;
  late final Animation<double> _echelleCarte;
  late final Animation<double> _echelleGrosLogo;
  late final Animation<double> _opaciteAnneau;
  late final Animation<double> _echelleAnneau;
  late final Animation<double> _opaciteTitre;
  late final Animation<Offset> _positionTitre;
  late final Animation<double> _opaciteSousTitre;

  @override
  void initState() {
    super.initState();

    _controleurSequence = AnimationController(
      vsync: this,
      duration: _dureeSplash,
    );
    _controleurRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _opaciteCarte = _intervalle(0.0, _finCarte * 0.7, Curves.easeOut);
    _echelleCarte = Tween<double>(begin: 0.7, end: 1.0)
        .animate(_intervalle(0.0, _finCarte, Curves.easeOutBack));

    // Gros logo : naît quand les petits logos arrivent au centre.
    _echelleGrosLogo = _intervalle(0.70, 0.82, Curves.elasticOut);

    // Onde blanche qui part du centre au moment de la fusion.
    _opaciteAnneau = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 80),
    ]).animate(_intervalle(0.72, 0.88, Curves.easeOut));
    _echelleAnneau = Tween<double>(begin: 0.5, end: 2.2)
        .animate(_intervalle(0.72, 0.88, Curves.easeOut));

    _opaciteTitre = _intervalle(0.78, 0.88, Curves.easeOut);
    _positionTitre = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(_intervalle(0.78, 0.88, Curves.easeOutCubic));
    _opaciteSousTitre = _intervalle(0.84, 0.94, Curves.easeOut);

    _controleurSequence.forward();
    _demarrer();
  }

  Animation<double> _intervalle(double debut, double fin, Curve courbe) {
    return CurvedAnimation(
      parent: _controleurSequence,
      curve: Interval(debut, fin, curve: courbe),
    );
  }

  Future<void> _demarrer() async {
    final resultats = await Future.wait([
      StockageLocal.estConnecte(),
      Future.delayed(_dureeSplash),
    ]);
    final connecte = resultats[0] as bool;
    if (connecte) {
      unawaited(ApiService.rafraichirPresence());
      unawaited(NotificationService.demanderPermissionEtEnregistrerToken());
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) =>
            connecte ? const NavigationPrincipale() : const EcranConnexion(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controleurSequence.dispose();
    _controleurRotation.dispose();
    super.dispose();
  }

  // Petit logo d'une ville : apparaît avec un rebond, puis glisse vers le
  // centre en rétrécissant et s'efface dans le gros logo.
  static const _taillePetitLogo = 26.0;

  double _debutPop(int index) =>
      _debutVilles +
      index * (_finVilles - _debutVilles - _dureePopVille) / (_villes.length - 1);

  Widget _petitLogo(int index, Size carte, Offset centre, Widget logo) {
    const taille = _taillePetitLogo;
    final t = _controleurSequence.value;
    final ville = _villes[index];

    final debutPop = _debutPop(index);
    final pop = Interval(debutPop, debutPop + _dureePopVille,
            curve: Curves.elasticOut)
        .transform(t);
    if (pop <= 0) return const SizedBox.shrink();

    final rassemblement = const Interval(_debutRassemblement, _finRassemblement,
            curve: Curves.easeInOutCubic)
        .transform(t);
    final disparition =
        const Interval(0.70, _finRassemblement, curve: Curves.easeIn)
            .transform(t);
    if (disparition >= 1) return const SizedBox.shrink();

    final depart = _CarteCoteDIvoire.projeter(
        ville.longitude, ville.latitude, carte);
    final position = Offset.lerp(depart, centre, rassemblement)!;
    final echelle = pop * lerpDouble(1.0, 0.6, rassemblement)!;

    return Positioned(
      left: position.dx - taille / 2,
      top: position.dy - taille / 2,
      child: Opacity(
        opacity: 1 - disparition,
        child: Transform.scale(
          scale: echelle,
          child: SizedBox(width: taille, height: taille, child: logo),
        ),
      ),
    );
  }

  // Nom de la ville : apparaît avec son logo et s'efface dès que les logos
  // commencent à se rassembler.
  Widget _nomVille(int index, Size carte) {
    final t = _controleurSequence.value;
    final ville = _villes[index];

    final debutPop = _debutPop(index);
    final apparition =
        Interval(debutPop, debutPop + _dureePopVille, curve: Curves.easeOut)
            .transform(t);
    final disparition = const Interval(_debutRassemblement,
            _debutRassemblement + 0.04, curve: Curves.easeIn)
        .transform(t);
    final opacite = apparition * (1 - disparition);
    if (opacite <= 0) return const SizedBox.shrink();

    final position = _CarteCoteDIvoire.projeter(
        ville.longitude, ville.latitude, carte);
    const ecart = _taillePetitLogo / 2 + 1;

    return Positioned(
      left: position.dx,
      top: ville.nomAuDessus ? position.dy - ecart : position.dy + ecart,
      child: FractionalTranslation(
        translation: Offset(-0.5, ville.nomAuDessus ? -1 : 0),
        child: Opacity(
          opacity: opacite,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              ville.nom,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const largeurCarte = 260.0;
    const tailleCarte =
        Size(largeurCarte, largeurCarte / _CarteCoteDIvoire.ratio);
    const tailleGrosLogo = largeurCarte * 0.46;
    final centre = Offset(_CarteCoteDIvoire.centre.dx * tailleCarte.width,
        _CarteCoteDIvoire.centre.dy * tailleCarte.height);

    final logoTournant = RotationTransition(
      turns: _controleurRotation,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Image.asset('assets/images/logo.png'),
      ),
    );

    return Scaffold(
      backgroundColor: EpuiciColors.primaire,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controleurSequence,
              builder: (context, _) {
                return SizedBox.fromSize(
                  size: tailleCarte,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: _opaciteCarte.value,
                          child: Transform.scale(
                            scale: _echelleCarte.value,
                            child: const CustomPaint(
                              painter: _CarteCoteDIvoire(),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: centre.dx - tailleGrosLogo / 2,
                        top: centre.dy - tailleGrosLogo / 2,
                        child: Opacity(
                          opacity: _opaciteAnneau.value,
                          child: Transform.scale(
                            scale: _echelleAnneau.value,
                            child: Container(
                              width: tailleGrosLogo,
                              height: tailleGrosLogo,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      for (var i = 0; i < _villes.length; i++)
                        _petitLogo(i, tailleCarte, centre, logoTournant),
                      for (var i = 0; i < _villes.length; i++)
                        _nomVille(i, tailleCarte),
                      if (_echelleGrosLogo.value > 0)
                        Positioned(
                          left: centre.dx - tailleGrosLogo / 2,
                          top: centre.dy - tailleGrosLogo / 2,
                          child: Transform.scale(
                            scale: _echelleGrosLogo.value,
                            child: SizedBox(
                              width: tailleGrosLogo,
                              height: tailleGrosLogo,
                              child: logoTournant,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _opaciteTitre,
              child: SlideTransition(
                position: _positionTitre,
                child: Text(
                  'EPUICI',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.1,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _opaciteSousTitre,
              child: Text(
                "L'actualité de nos églises,\nune seule famille en Christ.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 160,
              child: AnimatedBuilder(
                animation: _controleurSequence,
                builder: (context, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _controleurSequence.value,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Silhouette de la Côte d'Ivoire remplie aux couleurs du drapeau
// (orange / blanc / vert), avec un contour blanc.
class _CarteCoteDIvoire extends CustomPainter {
  const _CarteCoteDIvoire();

  // Frontière simplifiée (longitude, latitude), d'après Natural Earth 1:110m.
  static const List<Offset> _frontiere = [
    Offset(-2.856, 4.994), Offset(-3.311, 4.984), Offset(-4.009, 5.180),
    Offset(-4.650, 5.168), Offset(-5.834, 4.994), Offset(-6.529, 4.705),
    Offset(-7.519, 4.338), Offset(-7.712, 4.365), Offset(-7.635, 5.188),
    Offset(-7.540, 5.313), Offset(-7.570, 5.707), Offset(-7.994, 6.126),
    Offset(-8.311, 6.193), Offset(-8.603, 6.468), Offset(-8.385, 6.912),
    Offset(-8.485, 7.395), Offset(-8.439, 7.686), Offset(-8.281, 7.687),
    Offset(-8.222, 8.123), Offset(-8.299, 8.316), Offset(-8.203, 8.455),
    Offset(-7.832, 8.576), Offset(-8.079, 9.376), Offset(-8.310, 9.790),
    Offset(-8.229, 10.129), Offset(-8.030, 10.207), Offset(-7.900, 10.297),
    Offset(-7.623, 10.147), Offset(-6.851, 10.139), Offset(-6.666, 10.431),
    Offset(-6.494, 10.411), Offset(-6.205, 10.524), Offset(-6.050, 10.096),
    Offset(-5.817, 10.223), Offset(-5.404, 10.371), Offset(-4.955, 10.153),
    Offset(-4.780, 9.822), Offset(-4.330, 9.611), Offset(-3.980, 9.862),
    Offset(-3.512, 9.900), Offset(-2.827, 9.642), Offset(-2.562, 8.220),
    Offset(-2.984, 7.380), Offset(-3.244, 6.250), Offset(-2.811, 5.389),
  ];

  static const double _lonMin = -8.603, _lonMax = -2.562;
  static const double _latMin = 4.338, _latMax = 10.524;

  // Rapport largeur / hauteur de la carte.
  static const double ratio = (_lonMax - _lonMin) / (_latMax - _latMin);

  // Point (en fraction de la taille de la carte) où se forme le gros logo.
  static const Offset centre = Offset(0.49, 0.50);

  static const _orange = Color(0xFFF77F00);
  static const _vert = Color(0xFF009E60);
  static const _marge = 4.0;

  // Convertit des coordonnées géographiques en position sur la carte.
  static Offset projeter(double longitude, double latitude, Size taille) {
    final largeur = taille.width - _marge * 2;
    final hauteur = taille.height - _marge * 2;
    return Offset(
      _marge + (longitude - _lonMin) / (_lonMax - _lonMin) * largeur,
      _marge + (_latMax - latitude) / (_latMax - _latMin) * hauteur,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chemin = Path()
      ..addPolygon(
        _frontiere.map((p) => projeter(p.dx, p.dy, size)).toList(),
        true,
      );

    canvas.drawShadow(chemin, Colors.black, 8, false);

    canvas.save();
    canvas.clipPath(chemin);
    final tiers = size.width / 3;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, tiers, size.height), Paint()..color = _orange);
    canvas.drawRect(Rect.fromLTWH(tiers, 0, tiers, size.height),
        Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(tiers * 2, 0, tiers + 1, size.height),
        Paint()..color = _vert);
    canvas.restore();

    canvas.drawPath(
      chemin,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
