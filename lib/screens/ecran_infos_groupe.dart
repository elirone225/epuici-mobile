import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/groupe_model.dart';
import '../services/api_service.dart';
import '../widgets/avatar_fidele.dart';

// Infos d'un groupe : description et membres. Les responsables y valident
// les demandes d'adhésion et peuvent retirer un membre.
// Renvoie 'quitte' si le fidèle a quitté le groupe.
class EcranInfosGroupe extends StatefulWidget {
  final String groupeId;

  const EcranInfosGroupe({super.key, required this.groupeId});

  @override
  State<EcranInfosGroupe> createState() => _EcranInfosGroupeState();
}

class _EcranInfosGroupeState extends State<EcranInfosGroupe> {
  DetailGroupe? _groupe;
  List<DemandeGroupe> _demandes = [];
  bool _chargement = true;
  String? _erreur;
  final Set<String> _actionsEnCours = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final groupe = await ApiService.obtenirGroupe(widget.groupeId);
      final demandes = groupe.estResponsable
          ? await ApiService.demandesDuGroupe(widget.groupeId)
          : <DemandeGroupe>[];
      setState(() {
        _groupe = groupe;
        _demandes = demandes;
        _chargement = false;
        _erreur = null;
      });
    } catch (e) {
      setState(() {
        _erreur = e.toString().replaceAll('Exception: ', '');
        _chargement = false;
      });
    }
  }

  void _afficher(String texte) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _traiterDemande(DemandeGroupe demande, String decision) async {
    setState(() => _actionsEnCours.add(demande.id));
    try {
      await ApiService.traiterDemandeGroupe(demande.id, decision);
      if (!mounted) return;
      _afficher(decision == 'acceptee'
          ? '${demande.nom} a rejoint le groupe.'
          : 'Demande de ${demande.nom} refusée.');
      await _charger();
    } catch (e) {
      if (mounted) _afficher(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _actionsEnCours.remove(demande.id));
    }
  }

  Future<bool> _confirmer(String titre, String texte, String action) async {
    final reponse = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        title: Text(titre),
        content: Text(texte),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexte).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(contexte).pop(true),
            child: Text(action, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return reponse == true;
  }

  Future<void> _retirerMembre(MembreGroupe membre) async {
    final ok = await _confirmer(
      'Retirer ${membre.nom} ?',
      "${membre.nom} ne pourra plus lire ni envoyer de messages dans ce groupe.",
      'Retirer',
    );
    if (!ok) return;
    try {
      await ApiService.retirerMembreGroupe(widget.groupeId, membre.id);
      if (!mounted) return;
      _afficher('${membre.nom} a été retiré du groupe.');
      await _charger();
    } catch (e) {
      if (mounted) _afficher(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _quitter() async {
    final ok = await _confirmer(
      'Quitter le groupe ?',
      'Vous ne recevrez plus les messages de ce groupe. Pour revenir, il faudra refaire une demande.',
      'Quitter',
    );
    if (!ok) return;
    try {
      await ApiService.quitterGroupe(widget.groupeId);
      if (mounted) Navigator.of(context).pop('quitte');
    } catch (e) {
      if (mounted) _afficher(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Infos du groupe')),
      body: _corps(),
    );
  }

  Widget _corps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: EpuiciColors.primaire));
    }
    if (_erreur != null) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(32), child: Text(_erreur!, textAlign: TextAlign.center)),
      );
    }

    final groupe = _groupe!;
    final membres = [...groupe.membres]
      ..sort((a, b) {
        if (a.estResponsable != b.estResponsable) return a.estResponsable ? -1 : 1;
        return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      });

    return RefreshIndicator(
      onRefresh: _charger,
      color: EpuiciColors.primaire,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 20),
          Center(child: AvatarFidele(nom: groupe.nom, rayon: 40)),
          const SizedBox(height: 12),
          Text(
            groupe.nom,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            [
              if (groupe.egliseNom != null) groupe.egliseNom!,
              '${membres.length} membre${membres.length > 1 ? 's' : ''}',
            ].join(' · '),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (groupe.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(groupe.description, textAlign: TextAlign.center),
            ),
          if (groupe.estResponsable) ..._sectionDemandes(),
          _titreSection('Membres (${membres.length})'),
          ...membres.map((m) => _ligneMembre(m, peutRetirer: groupe.estResponsable)),
          if (!groupe.estResponsable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: OutlinedButton.icon(
                onPressed: _quitter,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Quitter le groupe'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _titreSection(String titre) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(titre, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  List<Widget> _sectionDemandes() {
    return [
      _titreSection("Demandes d'adhésion (${_demandes.length})"),
      if (_demandes.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Aucune demande en attente.', style: TextStyle(color: Colors.grey.shade600)),
        ),
      ..._demandes.map((demande) {
        final enCours = _actionsEnCours.contains(demande.id);
        return Container(
          color: Colors.white,
          child: ListTile(
            leading: AvatarFidele(nom: demande.nom, photo: demande.photoProfil),
            title: Text(demande.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: demande.telephone != null ? Text(demande.telephone!) : null,
            trailing: enCours
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: EpuiciColors.primaire),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Refuser',
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _traiterDemande(demande, 'refusee'),
                      ),
                      IconButton(
                        tooltip: 'Accepter',
                        icon: const Icon(Icons.check_circle, color: EpuiciColors.accent),
                        onPressed: () => _traiterDemande(demande, 'acceptee'),
                      ),
                    ],
                  ),
          ),
        );
      }),
    ];
  }

  Widget _ligneMembre(MembreGroupe membre, {required bool peutRetirer}) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: AvatarFidele(nom: membre.nom, photo: membre.photoProfil),
        title: Text(membre.moi ? '${membre.nom} (vous)' : membre.nom),
        trailing: membre.estResponsable
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EpuiciColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Responsable',
                  style: TextStyle(color: EpuiciColors.accent, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              )
            : (peutRetirer && !membre.moi)
                ? IconButton(
                    tooltip: 'Retirer du groupe',
                    icon: Icon(Icons.person_remove_outlined, color: Colors.grey.shade600),
                    onPressed: () => _retirerMembre(membre),
                  )
                : null,
      ),
    );
  }
}
