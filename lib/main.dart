import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'firebase_options.dart';
import 'screens/ecran_demarrage.dart';
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

class EpuiciApp extends StatelessWidget {
  const EpuiciApp({super.key});

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
