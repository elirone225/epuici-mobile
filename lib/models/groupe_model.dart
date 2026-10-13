// monStatut : 'aucun' | 'en_attente' | 'membre' | 'responsable'
class Groupe {
  final String id;
  final String nom;
  final String description;
  final String? egliseNom;
  final int nbMembres;
  final String monStatut;
  final int nbDemandesEnAttente;
  final String? dernierMessageTexte;
  final String? dernierMessageAuteur;
  final DateTime? dernierMessageLe;

  Groupe({
    required this.id,
    required this.nom,
    required this.description,
    this.egliseNom,
    required this.nbMembres,
    required this.monStatut,
    this.nbDemandesEnAttente = 0,
    this.dernierMessageTexte,
    this.dernierMessageAuteur,
    this.dernierMessageLe,
  });

  bool get estMembre => monStatut == 'membre' || monStatut == 'responsable';
  bool get estResponsable => monStatut == 'responsable';

  factory Groupe.fromJson(Map<String, dynamic> json) {
    final dernier = json['dernierMessage'];
    return Groupe(
      id: json['_id'],
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      egliseNom: json['village'] is Map ? json['village']['nom'] : null,
      nbMembres: json['nbMembres'] ?? 0,
      monStatut: json['monStatut'] ?? 'aucun',
      nbDemandesEnAttente: json['nbDemandesEnAttente'] ?? 0,
      dernierMessageTexte: dernier is Map ? dernier['texte'] : null,
      dernierMessageAuteur: dernier is Map ? dernier['auteurNom'] : null,
      dernierMessageLe: dernier is Map ? DateTime.tryParse(dernier['createdAt'] ?? '') : null,
    );
  }
}

class MembreGroupe {
  final String id;
  final String nom;
  final String? photoProfil;
  final bool estResponsable;
  final bool moi;

  MembreGroupe({
    required this.id,
    required this.nom,
    this.photoProfil,
    required this.estResponsable,
    required this.moi,
  });

  factory MembreGroupe.fromJson(Map<String, dynamic> json) {
    return MembreGroupe(
      id: json['_id'],
      nom: json['nom'] ?? 'Membre',
      photoProfil: json['photoProfil'],
      estResponsable: json['estResponsable'] ?? false,
      moi: json['moi'] ?? false,
    );
  }
}

class DetailGroupe {
  final String id;
  final String nom;
  final String description;
  final String? egliseNom;
  final String monStatut;
  final int nbDemandesEnAttente;
  final List<MembreGroupe> membres;

  DetailGroupe({
    required this.id,
    required this.nom,
    required this.description,
    this.egliseNom,
    required this.monStatut,
    required this.nbDemandesEnAttente,
    required this.membres,
  });

  bool get estResponsable => monStatut == 'responsable';

  factory DetailGroupe.fromJson(Map<String, dynamic> json) {
    return DetailGroupe(
      id: json['_id'],
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      egliseNom: json['village'] is Map ? json['village']['nom'] : null,
      monStatut: json['monStatut'] ?? 'membre',
      nbDemandesEnAttente: json['nbDemandesEnAttente'] ?? 0,
      membres: (json['membres'] as List? ?? [])
          .map((m) => MembreGroupe.fromJson(m))
          .toList(),
    );
  }
}

class DemandeGroupe {
  final String id;
  final String nom;
  final String? telephone;
  final String? photoProfil;
  final DateTime date;

  DemandeGroupe({
    required this.id,
    required this.nom,
    this.telephone,
    this.photoProfil,
    required this.date,
  });

  factory DemandeGroupe.fromJson(Map<String, dynamic> json) {
    final utilisateur = json['utilisateur'] is Map ? json['utilisateur'] : {};
    return DemandeGroupe(
      id: json['_id'],
      nom: utilisateur['nom'] ?? 'Fidèle',
      telephone: utilisateur['telephone'],
      photoProfil: utilisateur['photoProfil'],
      date: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// type : 'texte' | 'photo' | 'audio'
class MessageGroupe {
  final String id;
  final String type;
  final String texte; // légende pour une photo, vide pour un vocal
  final String? mediaUrl;
  final int? dureeAudio; // en secondes
  final DateTime date;
  final String auteurNom;
  final String? auteurPhoto;
  final bool estResponsable;
  final bool moi;

  MessageGroupe({
    required this.id,
    this.type = 'texte',
    required this.texte,
    this.mediaUrl,
    this.dureeAudio,
    required this.date,
    required this.auteurNom,
    this.auteurPhoto,
    required this.estResponsable,
    required this.moi,
  });

  factory MessageGroupe.fromJson(Map<String, dynamic> json) {
    final auteur = json['auteur'] is Map ? json['auteur'] : null;
    return MessageGroupe(
      id: json['_id'],
      type: json['type'] ?? 'texte',
      texte: json['texte'] ?? '',
      mediaUrl: json['mediaUrl'],
      dureeAudio: (json['dureeAudio'] as num?)?.toInt(),
      // Le serveur renvoie l'heure UTC : on l'affiche en heure locale
      date: (DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now()).toLocal(),
      auteurNom: auteur?['nom'] ?? 'Compte supprimé',
      auteurPhoto: auteur?['photoProfil'],
      estResponsable: json['estResponsable'] ?? false,
      moi: json['moi'] ?? false,
    );
  }

  bool get estPhoto => type == 'photo' && mediaUrl != null;
  bool get estAudio => type == 'audio' && mediaUrl != null;

  // Date brute (UTC, telle que renvoyée par le serveur) pour le paramètre "apres"
  String get dateIso => date.toUtc().toIso8601String();
}
