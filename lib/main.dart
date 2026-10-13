import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'firebase_options.dart';
import 'screens/ecran_demarrage.dart';
import 'services/mise_a_jour.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sur le web, il n'y a pas de google-services.json / GoogleService-Info.plist :
  // la config Firebase doit être fournie explicitement.
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.currentPlatform : null,
  );
  FirebaseMessaging.onBackgroundMessage(gererMessageArrierePlan);
  await NotificationService.initialiser();
  runApp(const EpuiciApp());
}

class EpuiciApp extends StatefulWidget {
  const EpuiciApp({super.key});

  @override
  State<EpuiciApp> createState() => _EpuiciAppState();
}

class _EpuiciAppState extends State<EpuiciApp> with WidgetsBindingObserver {
  static const _intervalleVerification = Duration(minutes: 30);
  Timer? _verificationReguliere;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mémorise la version chargée au démarrage
    MiseAJour.verifier();
    // App restée ouverte longtemps : on propose la mise à jour sans recharger
    _verificationReguliere = Timer.periodic(
      _intervalleVerification,
      (_) => MiseAJour.verifier(rechargerSiNouvelle: false),
    );
  }

  @override
  void dispose() {
    _verificationReguliere?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Retour sur l'app : recharge la PWA si une nouvelle version a été publiée
  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat == AppLifecycleState.resumed) MiseAJour.verifier();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPUICI',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: EpuiciTheme.clair,
      home: const EcranDemarrage(),
      builder: (context, enfant) => Column(
        children: [
          Expanded(child: enfant ?? const SizedBox.shrink()),
          const _BandeauMiseAJour(),
        ],
      ),
    );
  }
}

// Bandeau affiché en bas de l'écran quand une nouvelle version est publiée
class _BandeauMiseAJour extends StatelessWidget {
  const _BandeauMiseAJour();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MiseAJour.disponible,
      builder: (context, disponible, _) {
        if (!disponible) return const SizedBox.shrink();
        return Material(
          color: EpuiciColors.primaire,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.system_update, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Une nouvelle version d'EPUICI est disponible.",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: MiseAJour.recharger,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('METTRE À JOUR', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
