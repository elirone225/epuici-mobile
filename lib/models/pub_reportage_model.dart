class PubReportage {
  final String id;
  final String titre;
  final String? description;
  final String type;
  final String videoUrl;
  final String? villageNom;
  final int likes;
  final int vues;
  final int nombreCommentaires;
  final DateTime creeLe;

  PubReportage({
    required this.id,
    required this.titre,
    this.description,
    required this.type,
    required this.videoUrl,
    this.villageNom,
    required this.likes,
    required this.vues,
    required this.nombreCommentaires,
    required this.creeLe,
  });

  factory PubReportage.fromJson(Map<String, dynamic> json) {
    return PubReportage(
      id: json['_id'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'reportage',
      videoUrl: json['videoUrl'] ?? '',
      villageNom: json['village'] is Map ? json['village']['nom'] : null,
      likes: json['likes'] ?? 0,
      vues: json['vues'] ?? 0,
      nombreCommentaires: json['nombreCommentaires'] ?? 0,
      creeLe: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get labelType => type == 'publicite' ? 'Publicité' : 'Reportage';

  PubReportage copierAvec({int? likes, int? vues, int? nombreCommentaires}) {
    return PubReportage(
      id: id,
      titre: titre,
      description: description,
      type: type,
      videoUrl: videoUrl,
      villageNom: villageNom,
      likes: likes ?? this.likes,
      vues: vues ?? this.vues,
      nombreCommentaires: nombreCommentaires ?? this.nombreCommentaires,
      creeLe: creeLe,
    );
  }
}

class PubReportageCommentaire {
  final String id;
  final String texte;
  final String auteurNom;
  final String? auteurPhoto;
  final String? repondreAId;
  final String? repondreANom;
  final DateTime creeLe;

  PubReportageCommentaire({
    required this.id,
    required this.texte,
    required this.auteurNom,
    this.auteurPhoto,
    this.repondreAId,
    this.repondreANom,
    required this.creeLe,
  });

  factory PubReportageCommentaire.fromJson(Map<String, dynamic> json) {
    final repondreA = json['repondreA'];
    return PubReportageCommentaire(
      id: json['_id'] ?? '',
      texte: json['texte'] ?? '',
      auteurNom: json['auteur'] is Map ? (json['auteur']['nom'] ?? 'Anonyme') : 'Anonyme',
      auteurPhoto: json['auteur'] is Map ? json['auteur']['photoProfil'] : null,
      repondreAId: repondreA is Map ? repondreA['_id'] : null,
      repondreANom: repondreA is Map && repondreA['auteur'] is Map
          ? (repondreA['auteur']['nom'] ?? 'Anonyme')
          : null,
      creeLe: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String tempsEcoule() {
    final diff = DateTime.now().difference(creeLe);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}
