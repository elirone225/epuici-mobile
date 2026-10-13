import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../config/theme.dart';
import '../models/groupe_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/avatar_fidele.dart';
import '../widgets/lecteur_vocal.dart';
import 'ecran_infos_groupe.dart';
import 'ecran_photo_plein_ecran.dart';

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
  static const _dureeMaxVocal = Duration(minutes: 5);

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

  // Enregistrement d'un message vocal
  final _enregistreur = AudioRecorder();
  bool _enregistrement = false;
  Duration _dureeEnregistrement = Duration.zero;
  Timer? _chronoEnregistrement;
  _FormatAudio? _formatEnregistrement;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.groupeOuvertId = widget.groupeId;
    _defilementCtrl.addListener(_surDefilement);
    // Le bouton envoyer remplace le micro dès qu'on tape du texte
    _saisieCtrl.addListener(() => setState(() {}));
    _chargerDerniers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (NotificationService.groupeOuvertId == widget.groupeId) {
      NotificationService.groupeOuvertId = null;
    }
    _minuterie?.cancel();
    _chronoEnregistrement?.cancel();
    if (_enregistrement) _enregistreur.cancel();
    _enregistreur.dispose();
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

  void _afficherErreur(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
    );
  }

  // Envoi commun aux photos et aux vocaux
  Future<void> _envoyerMedia({
    required List<int> octets,
    required String nomFichier,
    required String typeMime,
    String? legende,
    int? dureeAudio,
  }) async {
    setState(() => _envoi = true);
    try {
      final message = await ApiService.envoyerMediaGroupe(
        widget.groupeId,
        octets: octets,
        nomFichier: nomFichier,
        typeMime: typeMime,
        legende: legende,
        dureeAudio: dureeAudio,
      );
      _ajouterMessages([message]);
      if (_defilementCtrl.hasClients) {
        _defilementCtrl.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    } catch (e) {
      _afficherErreur(e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  // --- Photos ---

  Future<void> _choisirPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (contexte) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: EpuiciColors.primaire),
              title: const Text('Galerie'),
              onTap: () => Navigator.of(contexte).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: EpuiciColors.primaire),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.of(contexte).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? photo;
    try {
      photo = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
    } catch (e) {
      _afficherErreur("Impossible d'accéder aux photos.");
      return;
    }
    if (photo == null || !mounted) return;

    final octets = await photo.readAsBytes();
    if (!mounted) return;

    // Aperçu avant envoi, avec une légende facultative
    final legendeCtrl = TextEditingController(text: _saisieCtrl.text.trim());
    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: Image.memory(octets, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: legendeCtrl,
                maxLength: 2000,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Ajouter une légende...', counterText: ''),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexte).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(contexte).pop(true), child: const Text('Envoyer')),
        ],
      ),
    );
    final legende = legendeCtrl.text.trim();
    legendeCtrl.dispose();
    if (confirme != true) return;

    // Le texte déjà tapé a servi de légende
    if (legende.isNotEmpty && legende == _saisieCtrl.text.trim()) _saisieCtrl.clear();

    final typeMime = photo.mimeType ?? _typeMimeImage(photo.name);
    await _envoyerMedia(
      octets: octets,
      nomFichier: photo.name.isNotEmpty ? photo.name : 'photo.jpg',
      typeMime: typeMime,
      legende: legende,
    );
  }

  String _typeMimeImage(String nom) {
    final extension = nom.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  // --- Messages vocaux ---

  // Premier format d'enregistrement pris en charge par le navigateur :
  // Opus/WebM (Chrome, Android), AAC/MP4 (Safari, iPhone), sinon WAV.
  Future<_FormatAudio?> _formatAudioDisponible() async {
    const formats = [
      _FormatAudio(AudioEncoder.opus, 'audio/webm', 'webm'),
      _FormatAudio(AudioEncoder.aacLc, 'audio/mp4', 'm4a'),
      _FormatAudio(AudioEncoder.wav, 'audio/wav', 'wav'),
    ];
    for (final format in formats) {
      if (await _enregistreur.isEncoderSupported(format.encodeur)) return format;
    }
    return null;
  }

  Future<void> _demarrerEnregistrement() async {
    try {
      if (!await _enregistreur.hasPermission()) {
        _afficherErreur(
          "Autorisez l'accès au micro dans les réglages du navigateur pour envoyer un message vocal.",
        );
        return;
      }
      final format = await _formatAudioDisponible();
      if (format == null) {
        _afficherErreur("L'enregistrement audio n'est pas pris en charge sur cet appareil.");
        return;
      }

      // Sur le web, le chemin est ignoré (l'enregistrement est gardé en mémoire)
      await _enregistreur.start(
        RecordConfig(encoder: format.encodeur, numChannels: 1),
        path: kIsWeb ? '' : 'vocal_${DateTime.now().millisecondsSinceEpoch}.${format.extension}',
      );

      setState(() {
        _enregistrement = true;
        _formatEnregistrement = format;
        _dureeEnregistrement = Duration.zero;
      });
      _chronoEnregistrement = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _dureeEnregistrement += const Duration(seconds: 1));
        if (_dureeEnregistrement >= _dureeMaxVocal) _terminerEnregistrement();
      });
    } catch (e) {
      _afficherErreur("Impossible de démarrer l'enregistrement.");
    }
  }

  Future<void> _annulerEnregistrement() async {
    _chronoEnregistrement?.cancel();
    await _enregistreur.cancel();
    if (mounted) setState(() => _enregistrement = false);
  }

  Future<void> _terminerEnregistrement() async {
    if (!_enregistrement) return;
    _chronoEnregistrement?.cancel();
    final duree = _dureeEnregistrement;
    final format = _formatEnregistrement!;
    setState(() => _enregistrement = false);

    try {
      final chemin = await _enregistreur.stop();
      if (chemin == null) return;
      if (duree < const Duration(seconds: 1)) {
        _afficherErreur('Message vocal trop court.');
        return;
      }
      // Sur le web, "chemin" est une URL blob: lisible avec XFile
      final octets = await XFile(chemin).readAsBytes();
      await _envoyerMedia(
        octets: octets,
        nomFichier: 'vocal.${format.extension}',
        typeMime: format.typeMime,
        dureeAudio: duree.inSeconds,
      );
    } catch (e) {
      _afficherErreur("Impossible d'envoyer le message vocal.");
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
            if (message.estPhoto) ...[
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EcranPhotoPleinEcran(
                      url: message.mediaUrl!,
                      legende: message.texte,
                      auteur: message.moi ? 'Vous' : message.auteurNom,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: message.mediaUrl!,
                    width: 240,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 240,
                      height: 240,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: EpuiciColors.primaire),
                    ),
                    errorWidget: (context, url, erreur) => Container(
                      width: 240,
                      height: 160,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade500, size: 40),
                    ),
                  ),
                ),
              ),
              if (message.texte.isNotEmpty) const SizedBox(height: 6),
            ],
            if (message.estAudio)
              LecteurVocal(url: message.mediaUrl!, dureeSecondes: message.dureeAudio, moi: moi),
            if (message.texte.isNotEmpty)
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
        child: _enregistrement ? _barreEnregistrement() : _barreTexte(),
      ),
    );
  }

  Widget _boutonRond({required IconData icone, required VoidCallback? onTap, Color? couleur}) {
    return Material(
      color: couleur ?? EpuiciColors.primaire,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: _envoi
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(icone, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _barreTexte() {
    final texteVide = _saisieCtrl.text.trim().isEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
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
                      contentPadding: EdgeInsets.fromLTRB(18, 12, 4, 12),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Envoyer une photo',
                  icon: Icon(Icons.photo_camera_outlined, color: Colors.grey.shade600),
                  onPressed: _envoi ? null : _choisirPhoto,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Comme sur WhatsApp : micro tant qu'aucun texte n'est saisi
        texteVide
            ? _boutonRond(icone: Icons.mic, onTap: _envoi ? null : _demarrerEnregistrement)
            : _boutonRond(icone: Icons.send, onTap: _envoi ? null : _envoyer),
      ],
    );
  }

  Widget _barreEnregistrement() {
    final minutes = _dureeEnregistrement.inMinutes;
    final secondes = (_dureeEnregistrement.inSeconds % 60).toString().padLeft(2, '0');
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.only(left: 4, right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Annuler',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _annulerEnregistrement,
                ),
                const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
                const SizedBox(width: 8),
                Text('$minutes:$secondes', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('Enregistrement...', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _boutonRond(icone: Icons.send, onTap: _terminerEnregistrement),
      ],
    );
  }
}

// Format d'enregistrement audio : encodeur, type MIME envoyé au serveur, extension
class _FormatAudio {
  final AudioEncoder encodeur;
  final String typeMime;
  final String extension;

  const _FormatAudio(this.encodeur, this.typeMime, this.extension);
}
