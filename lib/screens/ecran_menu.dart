import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/stockage_local.dart';
import '../models/village_model.dart';
import '../services/api_service.dart';
import '../widgets/animations.dart';
import '../widgets/avatar_fidele.dart';
import 'ecran_choix_villages.dart';
import 'ecran_connexion.dart';
import 'ecran_alerte.dart';
import 'ecran_profil.dart';

class EcranMenu extends StatefulWidget {
  const EcranMenu({super.key});

  @override
  State<EcranMenu> createState() => _EcranMenuState();
}

class _EcranMenuState extends State<EcranMenu> {
  List<Village> _mesVillages = [];
  bool _connecte = false;
  String _nom = '';
  String? _photo;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final idsSuivis = await StockageLocal.obtenirVillagesSuivis();
    final tousLesVillages = await ApiService.listerVillages();
    final connecte = await StockageLocal.estConnecte();

    // Nom et photo pour l'en-tête : facultatifs, le menu s'affiche sans.
    String nom = '';
    String? photo;
    if (connecte) {
      try {
        final profil = await ApiService.obtenirMonProfil();
        nom = profil['nom'] ?? '';
        photo = profil['photoProfil'];
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _mesVillages = tousLesVillages.where((v) => idsSuivis.contains(v.id)).toList();
      _connecte = connecte;
      _nom = nom;
      _photo = photo;
    });
  }

  Future<void> _deconnecter() async {
    await StockageLocal.deconnecter();
    _charger();
  }

  Future<void> _ajouterOuChangerVillage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EcranChoixVillages(modeModification: true),
      ),
    );
    _charger();
  }

  Future<void> _ouvrirConnexion() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EcranConnexion()),
    );
    _charger();
  }

  Future<void> _ouvrirAlerte() async {
    if (!_connecte) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text(
            "Vous devez avoir un compte et être connecté pour envoyer une alerte à l'admin d'une église.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _ouvrirConnexion();
              },
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EcranAlerte()),
    );
  }

  Future<void> _ouvrirProfil() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EcranProfil()),
    );
    _charger();
  }

  void _afficherAPropos() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('À propos'),
        content: const Text(
          "Désormais l'information au bout des doigts.\n\n"
          "Application développée par votre fils, frère, ami, parent... AKE Ohouo Theodore Levy-Maixent.\n\n"
          "EPUICI est la plateforme d'information des églises EPUICI : chaque église y partage ses actualités, ses annonces et ses évènements avec ses fidèles.\n\n"
          "Pour avoir accès à l'espace pub, contactez le : 0595202737.\n\n"
          "EPUICI, l'actualité de nos églises toujours proche de vous.\n\n"
          "Que Dieu vous bénisse.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eglise = _mesVillages.isEmpty ? null : _mesVillages.first;
    var index = 0;

    return Scaffold(
      body: RefreshIndicator(
        color: EpuiciColors.primaire,
        onRefresh: _charger,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _entete(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Apparition(index: index++, child: _titreSection('Mon église')),
                  Apparition(index: index++, child: _carteEglise(eglise)),
                  const SizedBox(height: 22),
                  Apparition(index: index++, child: _titreSection('Actions')),
                  Apparition(
                    index: index++,
                    child: _tuile(
                      icone: Icons.campaign_rounded,
                      couleur: Colors.deepOrange,
                      titre: 'Alerter',
                      sousTitre: "Signaler un évènement à l'admin d'une église",
                      onTap: _ouvrirAlerte,
                    ),
                  ),
                  if (_connecte)
                    Apparition(
                      index: index++,
                      child: _tuile(
                        icone: Icons.person_rounded,
                        couleur: EpuiciColors.primaire,
                        titre: 'Mon profil',
                        sousTitre: 'Nom, photo et coordonnées',
                        onTap: _ouvrirProfil,
                      ),
                    ),
                  Apparition(
                    index: index++,
                    child: _tuile(
                      icone: Icons.notifications_rounded,
                      couleur: Colors.amber.shade700,
                      titre: 'Notifications',
                      sousTitre: 'Nouvelles publications de votre église',
                      onTap: () {},
                    ),
                  ),
                  Apparition(
                    index: index++,
                    child: _tuile(
                      icone: Icons.info_rounded,
                      couleur: EpuiciColors.accent,
                      titre: 'À propos',
                      sousTitre: "L'application EPUICI",
                      onTap: _afficherAPropos,
                    ),
                  ),
                  if (_connecte) ...[
                    const SizedBox(height: 18),
                    Apparition(
                      index: index++,
                      child: TextButton.icon(
                        onPressed: _deconnecter,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Déconnexion'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // En-tête en dégradé : identité du fidèle, ou invitation à se connecter.
  Widget _entete() {
    final hautEcran = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, hautEcran + 20, 20, 26),
      decoration: const BoxDecoration(
        gradient: degradeEpuici,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Menu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
              ),
              const Spacer(),
              Opacity(
                opacity: 0.9,
                child: Image.asset('assets/images/logo.png', width: 34, height: 34),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Apparition(
            child: _connecte
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: AvatarFidele(
                          nom: _nom.isEmpty ? 'F' : _nom,
                          photo: _photo,
                          rayon: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nom.isEmpty ? 'Bienvenue' : _nom,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: Colors.white70, size: 15),
                                SizedBox(width: 4),
                                Text(
                                  'Connecté',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Créez un compte pour sauvegarder votre église.',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _ouvrirConnexion,
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Se connecter / Créer un compte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: EpuiciColors.primaire,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _titreSection(String titre) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        titre.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _carteEglise(Village? eglise) {
    return TapAnime(
      onTap: _ajouterOuChangerVillage,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: EpuiciColors.secondaire),
          boxShadow: [
            BoxShadow(
              color: EpuiciColors.primaire.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                gradient: degradeEpuici,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.church_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eglise?.nom ?? 'Aucune église choisie',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    eglise?.region ?? 'Choisissez votre église pour suivre ses actualités',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: EpuiciColors.primaire.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                eglise == null ? 'Choisir' : 'Changer',
                style: const TextStyle(
                  color: EpuiciColors.primaire,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tuile({
    required IconData icone,
    required Color couleur,
    required String titre,
    required String sousTitre,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapAnime(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icone, color: couleur),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(
                      sousTitre,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
