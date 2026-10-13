import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/ecran_detail_article.dart';
import '../screens/ecran_discussion_groupe.dart';
import '../screens/ecran_infos_groupe.dart';
import 'api_service.dart';

// Clé VAPID publique du projet Firebase (Console > Project Settings >
// Cloud Messaging > Web configuration > Web Push certificates).
// Nécessaire pour que FirebaseMessaging.getToken() fonctionne sur le web.
const _cleVapidWeb =
    'A_REMPLIR_CLE_VAPID_EPUICI';

// Permet d'ouvrir un écran depuis n'importe où (ex: tap sur une notification)
// sans dépendre du BuildContext d'un widget précis.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const _canalArticles = AndroidNotificationChannel(
  'epuici_articles',
  'Nouveaux articles',
  description: "Notifications des nouveaux articles publiés dans vos églises suivies.",
  importance: Importance.high,
);

const _canalGroupes = AndroidNotificationChannel(
  'epuici_groupes',
  'Messages des groupes',
  description: 'Messages et demandes d\'adhésion de vos groupes.',
  importance: Importance.high,
);

// Doit être une fonction top-level (ou statique) : appelée par le système
// quand un message arrive alors que l'app est en arrière-plan/fermée.
@pragma('vm:entry-point')
Future<void> gererMessageArrierePlan(RemoteMessage message) async {
  // Rien à faire ici : Android affiche automatiquement la notification
  // système pour les messages contenant un bloc "notification".
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  // Groupe dont la discussion est affichée à l'écran : on n'affiche pas de
  // notification pour ses nouveaux messages (ils apparaissent déjà).
  static String? groupeOuvertId;

  static Future<void> initialiser() async {
    // flutter_local_notifications ne supporte pas le web : sur le web, les
    // notifications au premier plan sont gérées directement par le navigateur.
    if (!kIsWeb) {
      final android = _localNotifs.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_canalArticles);
      await android?.createNotificationChannel(_canalGroupes);

      await _localNotifs.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (details) {
          final payload = details.payload;
          if (payload == null || payload.isEmpty) return;
          try {
            final donnees = Map<String, dynamic>.from(jsonDecode(payload));
            _ouvrirDepuisDonnees(donnees, donnees['titre']);
          } catch (_) {
            // Anciennes notifications : le payload était directement l'id de l'article
            _ouvrirArticle(payload);
          }
        },
      );
    }

    // Notification reçue pendant que l'app est ouverte : on l'affiche nous-mêmes.
    FirebaseMessaging.onMessage.listen(_afficherNotificationPremierPlan);

    // L'utilisateur tape sur la notification, app en arrière-plan.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _ouvrirDepuisDonnees(message.data, message.notification?.title);
    });

    // App ouverte directement depuis une notification (était fermée).
    final messageInitial = await FirebaseMessaging.instance.getInitialMessage();
    if (messageInitial != null) {
      _ouvrirDepuisDonnees(messageInitial.data, messageInitial.notification?.title);
    }
  }

  static Future<void> _afficherNotificationPremierPlan(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Sur le web, il n'y a pas de plugin de notifications locales : on laisse
    // le navigateur afficher la notification via le service worker FCM.
    if (kIsWeb) return;

    final groupeId = message.data['groupeId'];
    if (message.data['type'] == 'message_groupe' && groupeId != null && groupeId == groupeOuvertId) {
      return;
    }

    final canal = groupeId != null ? _canalGroupes : _canalArticles;
    await _localNotifs.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          canal.id,
          canal.name,
          channelDescription: canal.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode({...message.data, 'titre': notification.title}),
    );
  }

  // Ouvre l'écran correspondant à la notification touchée
  static void _ouvrirDepuisDonnees(Map<String, dynamic> donnees, String? titre) {
    final groupeId = donnees['groupeId'];
    if (groupeId != null) {
      // Le titre de la notification d'un groupe est le nom du groupe
      final ecran = donnees['type'] == 'demande_groupe'
          ? EcranInfosGroupe(groupeId: groupeId)
          : EcranDiscussionGroupe(groupeId: groupeId, nomGroupe: titre ?? 'Groupe');
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => ecran));
      return;
    }

    final articleId = donnees['articleId'];
    if (articleId != null) _ouvrirArticle(articleId);
  }

  static void _ouvrirArticle(String articleId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => EcranDetailArticle(articleId: articleId)),
    );
  }

  // À appeler une fois l'utilisateur connecté : demande la permission puis
  // envoie le token FCM de l'appareil au serveur pour qu'il puisse le notifier.
  static Future<void> demanderPermissionEtEnregistrerToken() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = kIsWeb
        ? await messaging.getToken(vapidKey: _cleVapidWeb)
        : await messaging.getToken();
    if (token != null) {
      await ApiService.enregistrerTokenNotification(token);
    }

    messaging.onTokenRefresh.listen((nouveauToken) {
      ApiService.enregistrerTokenNotification(nouveauToken);
    });
  }
}
