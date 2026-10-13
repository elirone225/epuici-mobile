class Village {
  final String id;
  final String nom;
  final String region;
  final String? photoCouverture;

  Village({
    required this.id,
    required this.nom,
    required this.region,
    this.photoCouverture,
  });

  factory Village.fromJson(Map<String, dynamic> json) {
    return Village(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      region: json['region'] ?? '',
      photoCouverture: json['photoCouverture'],
    );
  }
}
