class Article {
  final String id;
  final String titre;
  final String contenu;
  final String categorie;
  final List<String> photos;
  final int vues;
  final int likes;
  final DateTime creeLe;
  final String? villageNom;

  Article({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.categorie,
    required this.photos,
    required this.vues,
    required this.likes,
    required this.creeLe,
    this.villageNom,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['_id'] ?? '',
      titre: json['titre'] ?? '',
      contenu: json['contenu'] ?? '',
      categorie: json['categorie'] ?? 'actualites',
      photos: List<String>.from(json['photos'] ?? []),
      vues: json['vues'] ?? 0,
      likes: json['likes'] ?? 0,
      creeLe: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      villageNom: json['village'] is Map ? json['village']['nom'] : null,
    );
  }

  String tempsEcoule() {
    final diff = DateTime.now().difference(creeLe);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}
