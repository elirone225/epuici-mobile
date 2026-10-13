import 'dart:async';

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/stockage_local.dart';
import 'ecran_connexion.dart';
import 'navigation_principale.dart';

// Splash screen affiché au démarrage de l'application : montre le logo,
// puis redirige automatiquement vers l'accueil si l'utilisateur est déjà
// connecté, sinon vers l'écran de connexion.
class EcranDemarrage extends StatefulWidget {
  const EcranDemarrage({super.key});

  @override
  State<EcranDemarrage> createState() => _EcranDemarrageState();
}

class _EcranDemarrageState extends State<EcranDemarrage>
    with TickerProviderStateMixin {
  // Entrée : logo + texte apparaissent en cascade avec un léger effet de rebond.
  late final AnimationController _controleurEntree;
  late final Animation<double> _opaciteLogo;
  late final Animation<double> _echelleLogo;
  late final Animation<double> _rotationLogo;
  late final Animation<double> _opaciteAnneau;
  late final Animation<double> _echelleAnneau;
  late final Animation<double> _opaciteTitre;
  late final Animation<Offset> _positionTitre;
  late final Animation<double> _opaciteSousTitre;

  // Respiration continue du logo tant que l'app charge.
  late final AnimationController _controleurPulsation;
  late final Animation<double> _pulsation;

  @override
  void initState() {
    super.initState();

    _controleurEntree = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    // Anneau qui s'étend et s'estompe derrière le logo (0 - 60%).
    _opaciteAnneau = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0), weight: 70),
    ]).animate(
      CurvedAnimation(
        parent: _controleurEntree,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _echelleAnneau = Tween<double>(begin: 0.6, end: 1.6).animate(
      CurvedAnimation(
        parent: _controleurEntree,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Logo : fondu + zoom avec rebond et légère rotation (0 - 55%).
    _opaciteLogo = CurvedAnimation(
      parent: _controleurEntree,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _echelleLogo = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controleurEntree,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _rotationLogo = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _controleurEntree,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // Titre : glisse et apparaît juste après le logo (35% - 70%).
    _opaciteTitre = CurvedAnimation(
      parent: _controleurEntree,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );
    _positionTitre = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controleurEntree,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Sous-titre : apparaît en dernier (60% - 100%).
    _opaciteSousTitre = CurvedAnimation(
      parent: _controleurEntree,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _controleurPulsation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulsation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controleurPulsation, curve: Curves.easeInOut),
    );

    _controleurEntree.forward();
    _demarrer();
  }

  Future<void> _demarrer() async {
    final resultats = await Future.wait([
      StockageLocal.estConnecte(),
      Future.delayed(const Duration(milliseconds: 1800)),
    ]);
    final connecte = resultats[0] as bool;
    if (connecte) {
      unawaited(ApiService.rafraichirPresence());
      unawaited(NotificationService.demanderPermissionEtEnregistrerToken());
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            connecte ? const NavigationPrincipale() : const EcranConnexion(),
      ),
    );
  }

  @override
  void dispose() {
    _controleurEntree.dispose();
    _controleurPulsation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EpuiciColors.primaire,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_controleurEntree, _controleurPulsation]),
              builder: (context, child) {
                return SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: _opaciteAnneau.value,
                        child: Transform.scale(
                          scale: _echelleAnneau.value,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _opaciteLogo.value,
                        child: Transform.rotate(
                          angle: _rotationLogo.value,
                          child: Transform.scale(
                            scale: _echelleLogo.value * _pulsation.value,
                            child: child,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Image.asset(
                'assets/images/logo.png',
                width: 140,
                height: 140,
              ),
            ),
            const SizedBox(height: 16),
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
          ],
        ),
      ),
    );
  }
}
