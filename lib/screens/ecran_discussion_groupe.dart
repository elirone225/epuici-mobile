import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/groupe_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/avatar_fidele.dart';
import 'ecran_infos_groupe.dart';

// Discussion d'un groupe, façon messagerie. Les nouveaux messages sont
// récupérés toutes les quelques secondes tant que l'écran est ouvert.
class EcranDiscussionGroupe extends StatefulWidget {
  final String groupeId;
  final String nomGroupe;

  const EcranDiscussionGroupe({super.key, required this.groupeId, required this.nomGroupe});

  @override
  State<EcranDiscussionGroupe> createState() => _EcranDiscussionGroupeState();
}

class _EcranDiscussionGroupeState extends State<EcranDiscussionGroupe>
    with WidgetsBindingObserver {
  static const _intervalleRafraichissement = Duration(seconds: 4);

  final _saisieCtrl = TextEditingController();
  final _defilementCtrl = ScrollController();

  List<MessageGroupe> _messages = [];
  bool _chargement = true;
  bool _envoi = false;
  bool _chargementAnciens = false;
  bool _plusAnciensDisponibles = true;
  bool _rafraichissementEnCours = false;
  String? _erreur;
  Timer? _minuterie;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.groupeOuvertId = widget.groupeId;
    _defilementCtrl.addListener(_surDefilement);
    _chargerDerniers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (NotificationService.groupeOuvertId == widget.groupeId) {
      NotificationService.groupeOuvertId = null;
    }
    _minuterie?.cancel();
    _saisieCtrl.dispose();
    _defilementCtrl.dispose();
    super.dispose();
  }

  // Pas de rafraîchissement quand l'app est en arrière-plan
  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat == AppLifecycleState.resumed) {
      _rafraichir();
      _demarrerMinuterie();
    } else if (etat == AppLifecycleState.paused) {
      _minuterie?.cancel();
    }
  }

  void _demarrerMinuterie() {
    _minuterie?.cancel();
    _minuterie = Timer.periodic(_intervalleRafraichissement, (_) => _rafraichir());
  }

  Future<void> _chargerDerniers() async {
    try {
      final messages = await ApiService.messagesDuGroupe(widget.groupeId);
      setState(() {
        _messages = messages;
        _plusAnciensDisponibles = messages.length >= 50;
        _chargement = false;
      });
      _demarrerMinuterie();
    } catch (e) {
      setState(() {
        _erreur = e.toString().replaceAll('Exception: ', '');
        _chargement = false;
      });
    }
  }

  Future<void> _rafraichir() async {
    if (_rafraichissementEnCours || _chargement || _erreur != null) return;
    _rafraichissementEnCours = true;
    try {
      final nouveaux = await ApiService.messagesDuGroupe(
        widget.groupeId,
        apres: _messages.isNotEmpty ? _messages.last.dateIso : null,
      );
      _ajouterMessages(nouveaux);
    } catch (e) {
      // Retiré du groupe entre-temps : on arrête et on l'indique
      final message = e.toString().replaceAll('Exception: ', '');
      if (message.contains('pas membre') && mounted) {
        _minuterie?.cancel();
        setState(() => _erreur = message);
      }
    } finally {
      _rafraichissementEnCours = false;
    }
  }

  void _ajouterMessages(List<MessageGroupe> nouveaux) {
    if (!mounted || nouveaux.isEmpty) return;
    final idsConnus = _messages.map((m) => m.id).toSet();
    final aAjouter = nouveaux.where((m) => !idsConnus.contains(m.id)).toList();
    if (aAjouter.isEmpty) return;
    setState(() => _messages = [..._messages, ...aAjouter]);
  }

  // La liste est inversée : remonter vers les anciens messages = aller vers la fin
  void _surDefilement() {
    if (_defilementCtrl.position.pixels >= _defilementCtrl.position.maxScrollExtent - 200) {
      _chargerAnciens();
    }
  }

  Future<void> _chargerAnciens() async {
    if (_chargementAnciens || !_plusAnciensDisponibles || _messages.isEmpty) return;
    setState(() => _chargementAnciens = true);
    try {
      final anciens = await ApiService.messagesDuGroupe(
        widget.groupeId,
        avant: _messages.first.dateIso,
      );
      setState(() {
        _messages = [...anciens, ..._messages];
        _plusAnciensDisponibles = anciens.length >= 50;
      });
    } catch (_) {
      // On réessaiera au prochain défilement
    } finally {
      if (mounted) setState(() => _chargementAnciens = false);
    }
  }

  Future<void> _envoyer() async {
    final texte = _saisieCtrl.text.trim();
    if (texte.isEmpty || _envoi) return;

    setState(() => _envoi = true);
    try {
      final message = await ApiService.envoyerMessageGroupe(widget.groupeId, texte);
      _saisieCtrl.clear();
      _ajouterMessages([message]);
      if (_defilementCtrl.hasClients) {
        _defilementCtrl.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _ouvrirInfos() async {
    final resultat = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EcranInfosGroupe(groupeId: widget.groupeId)),
    );
    // Le fidèle a quitté le groupe depuis l'écran d'infos
    if (resultat == 'quitte' && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF3),
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: _erreur == null ? _ouvrirInfos : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                AvatarFidele(nom: widget.nomGroupe, rayon: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.nomGroupe, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        'Appuyez pour voir les infos du groupe',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (_erreur == null)
            IconButton(icon: const Icon(Icons.info_outline), onPressed: _ouvrirInfos),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _contenu()),
          if (_erreur == null && !_chargement) _barreSaisie(),
        ],
      ),
    );
  }

  Widget _contenu() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: EpuiciColors.primaire));
    }
    if (_erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_erreur!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aucun message pour le moment.\nÉcrivez le premier !',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Liste inversée : index 0 = message le plus récent, en bas de l'écran
    return ListView.builder(
      controller: _defilementCtrl,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      itemCount: _messages.length + (_chargementAnciens ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: EpuiciColors.primaire)),
          );
        }
        final position = _messages.length - 1 - index;
        final message = _messages[position];
        final precedent = position > 0 ? _messages[position - 1] : null;
        final nouveauJour = precedent == null || libelleJour(precedent.date) != libelleJour(message.date);
        // On n'affiche le nom que si l'auteur change, comme sur WhatsApp
        final memeAuteur = precedent != null &&
            !nouveauJour &&
            precedent.auteurNom == message.auteurNom &&
            precedent.moi == message.moi;

        return Column(
          children: [
            if (nouveauJour) _separateurJour(message.date),
            _bulle(message, afficherAuteur: !message.moi && !memeAuteur),
          ],
        );
      },
    );
  }

  Widget _separateurJour(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(libelleJour(date), style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ),
    );
  }

  Widget _bulle(MessageGroupe message, {required bool afficherAuteur}) {
    final moi = message.moi;
    return Align(
      alignment: moi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: EdgeInsets.only(top: afficherAuteur ? 8 : 3),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: moi ? EpuiciColors.primaire : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(moi ? 14 : 4),
            bottomRight: Radius.circular(moi ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (afficherAuteur)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  message.estResponsable ? '${message.auteurNom} · Responsable' : message.auteurNom,
                  style: const TextStyle(
                    color: EpuiciColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            Text(
              message.texte,
              style: TextStyle(color: moi ? Colors.white : Colors.black87, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                libelleHeure(message.date),
                style: TextStyle(
                  fontSize: 10.5,
                  color: moi ? Colors.white.withValues(alpha: 0.75) : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barreSaisie() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _saisieCtrl,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: EpuiciColors.primaire,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _envoi ? null : _envoyer,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: _envoi
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
