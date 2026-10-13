class Utilisateur {
  final String id;
  final String? nom;
  final String telephone;
  final String? photoProfil;
  final List<String> villagesSuivis;

  Utilisateur({
    required this.id,
    this.nom,
    required this.telephone,
    this.photoProfil,
    required this.villagesSuivis,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    List<String> ids = [];
    if (json['villagesSuivis'] is List) {
      ids = (json['villagesSuivis'] as List)
          .map((v) => v is Map ? v['_id'].toString() : v.toString())
          .toList();
    }
    return Utilisateur(
      id: json['_id'] ?? '',
      nom: json['nom'],
      telephone: json['telephone'] ?? '',
      photoProfil: json['photoProfil'],
      villagesSuivis: ids,
    );
  }
}
