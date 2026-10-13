import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../models/village_model.dart';
import '../models/article_model.dart';
import '../models/groupe_model.dart';
import '../models/pub_reportage_model.dart';
import '../models/utilisateur_model.dart';
import 'stockage_local.dart';

class ApiService {
  static Future<List<Village>> listerVillages() async {
    final reponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/villages'));

    if (reponse.statusCode == 200) {
      final List donnees = jsonDecode(reponse.body);
      return donnees.map((v) => Village.fromJson(v)).toList();
    } else {
      throw Exception('Impossible de charger les églises.');
    }
  }

  static Future<List<Article>> filDActualite(List<String> idsVillages) async {
    final villagesParam = idsVillages.join(',');
    final reponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/articles/fil?villages=$villagesParam'),
    );

    if (reponse.statusCode == 200) {
      final List donnees = jsonDecode(reponse.body);
      return donnees.map((a) => Article.fromJson(a)).toList();
    } else {
      throw Exception('Impossible de charger le fil d\'actualité.');
    }
  }

  static Future<List<Article>> articlesParVillage(String villageId) async {
    final reponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/articles/village/$villageId'),
    );

    if (reponse.statusCode == 200) {
      final donnees = jsonDecode(reponse.body);
      final List articles = donnees['articles'] ?? [];
      return articles.map((a) => Article.fromJson(a)).toList();
    } else {
      throw Exception('Impossible de charger les articles.');
    }
  }

  // Bandes pub (images format banderole) affichées en haut du fil d'actualité
  static Future<List<String>> listerBannieresPub() async {
    final reponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/bannieres-pub'));

    if (reponse.statusCode == 200) {
      final List donnees = jsonDecode(reponse.body);
      return donnees
          .map((b) => (b['imageUrl'] ?? '') as String)
          .where((url) => url.isNotEmpty)
          .toList();
    } else {
      throw Exception('Impossible de charger les bandes pub.');
    }
  }

  static Future<Article> obtenirArticle(String id) async {
    final reponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/articles/$id'));

    if (reponse.statusCode == 200) {
      return Article.fromJson(jsonDecode(reponse.body));
    } else {
      throw Exception('Impossible de charger l\'article.');
    }
  }

  static Future<int> likerArticle(String id) async {
    final reponse = await http.put(Uri.parse('${ApiConfig.baseUrl}/articles/$id/like'));

    if (reponse.statusCode == 200) {
      final donnees = jsonDecode(reponse.body);
      return donnees['likes'] ?? 0;
    } else {
      throw Exception('Impossible de liker l\'article.');
    }
  }

  // Fil "Pub et Reportage" : vidéos publiées par le Super Admin, visibles par
  // tous les utilisateurs, tous villages confondus (défilement type TikTok).
  static Future<List<PubReportage>> listerPubReportages({int page = 1}) async {
    final reponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/pub-reportages?page=$page'),
    );

    if (reponse.statusCode == 200) {
      final donnees = jsonDecode(reponse.body);
      final List pubReportages = donnees['pubReportages'] ?? [];
      return pubReportages.map((p) => PubReportage.fromJson(p)).toList();
    } else {
      throw Exception('Impossible de charger les vidéos.');
    }
  }

  static Future<int> likerPubReportage(String id) async {
    final reponse = await http.put(Uri.parse('${ApiConfig.baseUrl}/pub-reportages/$id/like'));

    if (reponse.statusCode == 200) {
      final donnees = jsonDecode(reponse.body);
      return donnees['likes'] ?? 0;
    } else {
      throw Exception('Impossible de liker cette vidéo.');
    }
  }

  static Future<int> enregistrerVuePubReportage(String id) async {
    final reponse = await http.put(Uri.parse('${ApiConfig.baseUrl}/pub-reportages/$id/vue'));

    if (reponse.statusCode == 200) {
      final donnees = jsonDecode(reponse.body);
      return donnees['vues'] ?? 0;
    } else {
      throw Exception('Impossible d\'enregistrer la vue.');
    }
  }

  static Future<List<PubReportageCommentaire>> listerCommentairesPubReportage(String id) async {
    final reponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/pub-reportages/$id/commentaires'),
    );

    if (reponse.statusCode == 200) {
      final List donnees = jsonDecode(reponse.body);
      return donnees.map((c) => PubReportageCommentaire.fromJson(c)).toList();
    } else {
      throw Exception('Impossible de charger les commentaires.');
    }
  }

  static Future<PubReportageCommentaire> ajouterCommentairePubReportage({
    required String id,
    required String texte,
    String? repondreA,
  }) async {
    final token = await StockageLocal.obtenirToken();
    if (token == null) {
      throw Exception('Vous devez être connecté pour commenter.');
    }

    final reponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/pub-reportages/$id/commentaires'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'texte': texte,
        if (repondreA != null) 'repondreA': repondreA,
      }),
    );

    final donnees = jsonDecode(reponse.body);
    if (reponse.statusCode == 201) {
      return PubReportageCommentaire.fromJson(donnees);
    } else {
      throw Exception(donnees['message'] ?? "Impossible d'envoyer le commentaire.");
    }
  }

  // --- Authentification utilisateur (habitants) ---

  static Future<Map<String, dynamic>> inscrireUtilisateur({
    required String nom,
    required String telephone,
    required String motDePasse,
    String? email,
    XFile? photoProfil,
  }) async {
    final requete = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/utilisateurs/inscription'),
    );
    requete.fields['nom'] = nom;
    requete.fields['telephone'] = telephone;
    requete.fields['motDePasse'] = motDePasse;
    if (email != null && email.isNotEmpty) requete.fields['email'] = email;

    if (photoProfil != null) {
      requete.files.add(http.MultipartFile.fromBytes(
        'photoProfil',
        await photoProfil.readAsBytes(),
        filename: photoProfil.name,
      ));
    }

    final reponseStream = await requete.send();
    final reponse = await http.Response.fromStream(reponseStream);

    final donnees = jsonDecode(reponse.body);
    if (reponse.statusCode == 201) {
      return donnees;
    } else {
      throw Exception(donnees['message'] ?? 'Erreur lors de l\'inscription.');
    }
  }

  static Future<Map<String, dynamic>> connecterUtilisateur({
    required String telephone,
    required String motDePasse,
  }) async {
    final reponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/utilisateurs/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'telephone': telephone, 'motDePasse': motDePasse}),
    );

    final donnees = jsonDecode(reponse.body);
    if (reponse.statusCode == 200) {
      return donnees;
    } else {
      throw Exception(donnees['message'] ?? 'Erreur de connexion.');
    }
  }

  static Future<String> demanderReinitialisationMotDePasse({
    required String email,
  }) async {
    final reponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/utilisateurs/mot-de-passe-oublie'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final donnees = jsonDecode(reponse.body);
    if (reponse.statusCode == 200) {
      return donnees['message'] as String;
    } else {
      throw Exception(donnees['message'] ?? "Erreur lors de l'envoi du code.");
    }
  }

  static Future<void> reinitialiserMotDePasse({
    required String email,
    required String code,
    required String nouveauMotDePasse,
  }) async {
    final reponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/utilisateurs/reinitialiser-mot-de-passe'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'nouveauMotDePasse': nouveauMotDePasse,
      }),
    );

    final donnees = jsonDecode(reponse.body);
    if (reponse.statusCode != 200) {
      throw Exception(donnees['message'] ?? 'Erreur lors de la réinitialisation.');
    }
  }

  static Future<void> suivreVillageCompte(String villageId) async {
    final token = await StockageLocal.obtenirToken();
    if (token == null) return;

    await http.put(
      Uri.parse('${ApiConfig.baseUrl}/utilisateurs/suivre/$villageId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> enregistrerTokenNotification(String token) async {
    final tokenAuth = await StockageLocal.obtenirToken();
    if (tokenAuth == null) return;

    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/utilisateurs/token-notification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokenAuth',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (_) {
      // Silencieux : pas critique si l'enregistrement du token échoue.
    }
  }

  static Future<void> neSuivrePlusVillageCompte(String villageId) async {
    final token = await StockageLocal.obtenirToken();
    if (token == null) return;

    await http.put(
      Uri.parse('${ApiConfig.baseUrl}/utilisateurs/ne-plus-suivre/$villageId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // Ping léger envoyé à l'ouverture de l'app pour marquer l'utilisateur
  // comme "actif maintenant" côté admin (met à jour derniereConnexion).
  static Future<void> rafraichirPresence() async {
    final token = await StockageLocal.obtenirToken();
    if (token == null) return;

    try {
      await http.get(
        Uri.parse('${ApiConfig.baseUrl}/utilisateurs/mon-profil'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {
      // Silencieux : ce n'est qu'un ping de présence, pas une action critique.
    }
  }

  static Future<Map<String, dynamic>> obtenirMonProfil() async {
    final token = await StockageLocal.obtenirToken();
    if (token == null) {
      throw Exception('Vous devez être connecté.');
    }

    final reponse = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/utilisateurs/mon-profil'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final donnees = jsonDecode(reponse.body);
    if (reponse.statusCode == 200) {
      return donnees;
    } else {
      throw Exception(donnees['message'] ?? 'Erreur lors du chargement du profil.');
    }
  }

  static Future<Map<String, dynamic>> modifierMonProfil({
    String? nom,
    String? email,
    XFile? photoProfil,
  }) async {
    final token = await StockageLocal.obtenirToken();
    if (token == null) {
      throw Exception('Vous devez être connecté.');
    }

    final requete = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConfig.baseUrl}/utilisateurs/mon-profil'),
    );
    requete.headers['Authorization'] = 'Bearer $token';
    if (nom != null && nom.isNotEmpty) requete.fields['nom'] = nom;
    if (email != null && email.isNotEmpty) requete.fields['email'] = email;
    if (photoProfil != null) {
      requete.files.add(http.MultipartFile.fromBytes(
        'photoProfil',
        await photoProfil.readAsBytes(),
        filename: photoProfil.name,
      ));
    }

    final reponseStream = await requete.send();
    final reponse = await http.Response.fromStream(reponseStream);

    final donnees = jsonDecode(reponse.body);
    if (reponse.statusCode == 200) {
      return donnees;
    } else {
      throw Exception(donnees['message'] ?? 'Erreur lors de la mise à jour du profil.');
    }
  }

  // --- Alertes des habitants ---

  // Envoie une alerte (description + photos facultatives) au Village Admin
  // du village choisi par l'utilisateur connecté.
  static Future<void> envoyerAlerte({
    required String villageId,
    required String description,
    required List<XFile> photos,
  }) async {
    final token = await StockageLocal.obtenirToken();
    if (token == null) {
      throw Exception('Vous devez être connecté pour envoyer une alerte.');
    }

    final requete = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/alertes'),
    );
    requete.headers['Authorization'] = 'Bearer $token';
    requete.fields['village'] = villageId;
    requete.fields['description'] = description;

    for (final photo in photos) {
      requete.files.add(http.MultipartFile.fromBytes(
        'photos',
        await photo.readAsBytes(),
        filename: photo.name,
      ));
    }

    final reponseStream = await requete.send();
    final reponse = await http.Response.fromStream(reponseStream);

    if (reponse.statusCode != 201) {
      final donnees = jsonDecode(reponse.body);
      throw Exception(donnees['message'] ?? "Impossible d'envoyer l'alerte.");
    }
  }

  // --- Groupes de l'église (discussion entre fidèles) ---

  // Appel authentifié commun aux écrans des groupes : renvoie le JSON décodé
  // ou lève une Exception avec le message du serveur.
  static Future<dynamic> _requeteGroupe(
    String methode,
    String chemin, {
    Map<String, dynamic>? corps,
    int statutAttendu = 200,
  }) async {
    final token = await StockageLocal.obtenirToken();
    if (token == null) {
      throw Exception('Vous devez être connecté.');
    }

    final requete = http.Request(methode, Uri.parse('${ApiConfig.baseUrl}/groupes$chemin'));
    requete.headers['Authorization'] = 'Bearer $token';
    if (corps != null) {
      requete.headers['Content-Type'] = 'application/json';
      requete.body = jsonEncode(corps);
    }

    final reponse = await http.Response.fromStream(await requete.send());
    final donnees = jsonDecode(reponse.body);
    if (reponse.statusCode != statutAttendu) {
      throw Exception(donnees is Map ? (donnees['message'] ?? 'Erreur serveur.') : 'Erreur serveur.');
    }
    return donnees;
  }

  static Future<List<Groupe>> mesGroupes() async {
    final List donnees = await _requeteGroupe('GET', '/mes-groupes');
    return donnees.map((g) => Groupe.fromJson(g)).toList();
  }

  static Future<List<Groupe>> groupesDeLEglise(String egliseId) async {
    final List donnees = await _requeteGroupe('GET', '/eglise/$egliseId');
    return donnees.map((g) => Groupe.fromJson(g)).toList();
  }

  static Future<void> demanderAdhesionGroupe(String groupeId) async {
    await _requeteGroupe('POST', '/$groupeId/demande', statutAttendu: 201);
  }

  static Future<void> annulerDemandeGroupe(String groupeId) async {
    await _requeteGroupe('DELETE', '/$groupeId/demande');
  }

  static Future<void> quitterGroupe(String groupeId) async {
    await _requeteGroupe('POST', '/$groupeId/quitter');
  }

  static Future<DetailGroupe> obtenirGroupe(String groupeId) async {
    return DetailGroupe.fromJson(await _requeteGroupe('GET', '/$groupeId'));
  }

  static Future<List<DemandeGroupe>> demandesDuGroupe(String groupeId) async {
    final List donnees = await _requeteGroupe('GET', '/$groupeId/demandes');
    return donnees.map((d) => DemandeGroupe.fromJson(d)).toList();
  }

  // decision : 'acceptee' ou 'refusee'
  static Future<void> traiterDemandeGroupe(String demandeId, String decision) async {
    await _requeteGroupe('PUT', '/demandes/$demandeId', corps: {'decision': decision});
  }

  static Future<void> retirerMembreGroupe(String groupeId, String utilisateurId) async {
    await _requeteGroupe('DELETE', '/$groupeId/membres/$utilisateurId');
  }

  // Sans paramètre : les derniers messages. "apres" : uniquement les nouveaux
  // (rafraîchissement). "avant" : les plus anciens (remonter la discussion).
  static Future<List<MessageGroupe>> messagesDuGroupe(
    String groupeId, {
    String? apres,
    String? avant,
  }) async {
    final parametres = <String, String>{
      'apres': ?apres,
      'avant': ?avant,
    };
    final requete = parametres.isEmpty ? '' : '?${Uri(queryParameters: parametres).query}';
    final List donnees = await _requeteGroupe('GET', '/$groupeId/messages$requete');
    return donnees.map((m) => MessageGroupe.fromJson(m)).toList();
  }

  static Future<MessageGroupe> envoyerMessageGroupe(String groupeId, String texte) async {
    final donnees = await _requeteGroupe(
      'POST',
      '/$groupeId/messages',
      corps: {'texte': texte},
      statutAttendu: 201,
    );
    return MessageGroupe.fromJson(donnees);
  }

  // Envoie une photo (avec légende facultative) ou un message vocal
  static Future<MessageGroupe> envoyerMediaGroupe(
    String groupeId, {
    required List<int> octets,
    required String nomFichier,
    required String typeMime,
    String? legende,
    int? dureeAudio,
  }) async {
    final token = await StockageLocal.obtenirToken();
    if (token == null) {
      throw Exception('Vous devez être connecté.');
    }

    final requete = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/groupes/$groupeId/messages'),
    );
    requete.headers['Authorization'] = 'Bearer $token';
    if (legende != null && legende.isNotEmpty) requete.fields['texte'] = legende;
    if (dureeAudio != null) requete.fields['dureeAudio'] = dureeAudio.toString();
    requete.files.add(http.MultipartFile.fromBytes(
      'media',
      octets,
      filename: nomFichier,
      contentType: MediaType.parse(typeMime),
    ));

    final reponse = await http.Response.fromStream(await requete.send());
    final donnees = jsonDecode(reponse.body);
    if (reponse.statusCode == 201) {
      return MessageGroupe.fromJson(donnees);
    } else {
      throw Exception(donnees['message'] ?? "Impossible d'envoyer le fichier.");
    }
  }
}
