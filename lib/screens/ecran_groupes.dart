import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/groupe_model.dart';
import '../models/village_model.dart';
import '../services/api_service.dart';
import '../services/stockage_local.dart';
import '../widgets/animations.dart';
import '../widgets/avatar_fidele.dart';
import 'ecran_connexion.dart';
import 'ecran_discussion_groupe.dart';

// Onglet "Groupes" : les groupes dont le fidèle fait partie (discussions)
// et la découverte des groupes de ses églises suivies.
class EcranGroupes extends StatefulWidget {
  const EcranGroupes({super.key});

  @override
  State<EcranGroupes> createState() => _EcranGroupesState();
}

class _EcranGroupesState extends State<EcranGroupes> {
  bool _chargement = true;
  bool _connecte = false;
  String? _erreur;

  List<Groupe> _mesGroupes = [];
  List<Village> _mesEglises = [];
  int _egliseActive = 0;
  List<Groupe> _groupesEglise = [];
  bool _chargementEglise = false;
  final Set<String> _actionsEnCours = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final connecte = await StockageLocal.estConnecte();
      if (!connecte) {
        setState(() {
          _connecte = false;
          _chargement = false;
        });
        return;
      }

      final idsSuivis = await StockageLocal.obtenirVillagesSuivis();
      final resultats = await Future.wait([
        ApiService.mesGroupes(),
        ApiService.listerVillages(),
      ]);
      final mesGroupes = resultats[0] as List<Groupe>;
      final mesEglises = (resultats[1] as List<Village>)
          .where((v) => idsSuivis.contains(v.id))
          .toList();

      setState(() {
        _connecte = true;
        _mesGroupes = mesGroupes;
        _mesEglises = mesEglises;
        if (_egliseActive >= mesEglises.length) _egliseActive = 0;
        _chargement = false;
      });
      await _chargerGroupesEglise();
    } catch (e) {
      setState(() {
        _erreur = e.toString().replaceAll('Exception: ', '');
        _chargement = false;
      });
    }
  }

  Future<void> _chargerGroupesEglise() async {
    if (_mesEglises.isEmpty) return;
    setState(() => _chargementEglise = true);
    try {
      final groupes = await ApiService.groupesDeLEglise(
        _mesEglises[_egliseActive].id,
      );
      setState(() => _groupesEglise = groupes);
    } catch (_) {
      setState(() => _groupesEglise = []);
    } finally {
      setState(() => _chargementEglise = false);
    }
  }

  Future<void> _ouvrirDiscussion(Groupe groupe) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EcranDiscussionGroupe(groupeId: groupe.id, nomGroupe: groupe.nom),
      ),
    );
    _charger();
  }

  Future<void> _executerAction(
    Groupe groupe,
    Future<void> Function() action,
    String succes,
  ) async {
    setState(() => _actionsEnCours.add(groupe.id));
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(succes)));
      await _chargerGroupesEglise();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _actionsEnCours.remove(groupe.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        appBar: AppBarEpuici(titre: Text('Groupes')),
        body: ListeSquelettes(avecImage: false, nombre: 5),
      );
    }
    if (!_connecte) {
      return Scaffold(
        appBar: const AppBarEpuici(titre: Text('Groupes')),
        body: _invitationConnexion(),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const AppBarEpuici(
          titre: Text('Groupes'),
          bottom: TabBar(
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'Mes groupes'),
              Tab(text: 'Découvrir'),
            ],
          ),
        ),
        body: _erreur != null
            ? _messageErreur()
            : TabBarView(children: [_ongletMesGroupes(), _ongletDecouvrir()]),
      ),
    );
  }

  Widget _invitationConnexion() {
    return EtatVide(
      icone: Icons.forum_rounded,
      message:
          'Connectez-vous pour rejoindre les groupes de votre église et discuter avec leurs membres.',
      libelleAction: 'Se connecter',
      onAction: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const EcranConnexion()));
        _charger();
      },
    );
  }

  Widget _messageErreur() {
    return EtatVide(
      icone: Icons.wifi_off_rounded,
      message: _erreur!,
      libelleAction: 'Réessayer',
      onAction: _charger,
    );
  }

  Widget _ongletMesGroupes() {
    if (_mesGroupes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _charger,
        color: EpuiciColors.primaire,
        child: const EtatVide(
          icone: Icons.groups_rounded,
          message:
              "Vous ne faites partie d'aucun groupe.\nOuvrez l'onglet « Découvrir » pour demander à en rejoindre un.",
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _charger,
      color: EpuiciColors.primaire,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        itemCount: _mesGroupes.length,
        itemBuilder: (context, index) {
          final groupe = _mesGroupes[index];
          final apercu = groupe.dernierMessageTexte != null
              ? '${groupe.dernierMessageAuteur} : ${groupe.dernierMessageTexte}'
              : groupe.egliseNom ?? 'Aucun message';
          return Apparition(
            index: index,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: EpuiciColors.primaire.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () => _ouvrirDiscussion(groupe),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                leading: AvatarFidele(nom: groupe.nom, rayon: 24),
                title: Text(
                  groupe.nom,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  apercu,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (groupe.dernierMessageLe != null)
                      Text(
                        libelleDateCourte(groupe.dernierMessageLe!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (groupe.nbDemandesEnAttente > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: EpuiciColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${groupe.nbDemandesEnAttente} demande${groupe.nbDemandesEnAttente > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _ongletDecouvrir() {
    if (_mesEglises.isEmpty) {
      return const EtatVide(
        icone: Icons.church_rounded,
        message: 'Suivez une église pour découvrir ses groupes.',
      );
    }

    return Column(
      children: [
        if (_mesEglises.length > 1) _barreEglises(),
        Expanded(
          child: _chargementEglise
              ? const ListeSquelettes(avecImage: false)
              : RefreshIndicator(
                  onRefresh: _chargerGroupesEglise,
                  color: EpuiciColors.primaire,
                  child: _groupesEglise.isEmpty
                      ? const EtatVide(
                          icone: Icons.group_add_rounded,
                          message: "Cette église n'a pas encore de groupe.",
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _groupesEglise.length,
                          itemBuilder: (context, index) => Apparition(
                            index: index,
                            child: _carteGroupe(_groupesEglise[index]),
                          ),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _barreEglises() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _mesEglises.length,
        itemBuilder: (context, index) {
          final actif = _egliseActive == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: GestureDetector(
              onTap: () {
                setState(() => _egliseActive = index);
                _chargerGroupesEglise();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: actif ? EpuiciColors.primaire : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  _mesEglises[index].nom,
                  style: TextStyle(
                    color: actif ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _carteGroupe(Groupe groupe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: EpuiciColors.primaire.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarFidele(nom: groupe.nom, rayon: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupe.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${groupe.nbMembres} membre${groupe.nbMembres > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (groupe.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              groupe.description,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: _boutonAction(groupe)),
        ],
      ),
    );
  }

  Widget _boutonAction(Groupe groupe) {
    final enCours = _actionsEnCours.contains(groupe.id);

    if (groupe.estMembre) {
      return OutlinedButton.icon(
        onPressed: () => _ouvrirDiscussion(groupe),
        icon: const Icon(Icons.forum_outlined, size: 18),
        label: Text(
          groupe.estResponsable
              ? 'Ouvrir (responsable)'
              : 'Ouvrir la discussion',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: EpuiciColors.primaire,
          side: const BorderSide(color: EpuiciColors.primaire),
        ),
      );
    }

    if (groupe.monStatut == 'en_attente') {
      return OutlinedButton(
        onPressed: enCours
            ? null
            : () => _executerAction(
                groupe,
                () => ApiService.annulerDemandeGroupe(groupe.id),
                'Demande annulée.',
              ),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade700),
        child: const Text('Demande en attente · Annuler'),
      );
    }

    return ElevatedButton(
      onPressed: enCours
          ? null
          : () => _executerAction(
              groupe,
              () => ApiService.demanderAdhesionGroupe(groupe.id),
              'Demande envoyée. Un responsable du groupe doit la valider.',
            ),
      style: ElevatedButton.styleFrom(
        backgroundColor: EpuiciColors.primaire,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: enCours
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Demander à rejoindre'),
    );
  }
}
