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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mémorise la version chargée au démarrage
    MiseAJour.verifier();
  }

  @override
  void dispose() {
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
    );
  }
}
