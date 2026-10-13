import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/stockage_local.dart';
import '../models/village_model.dart';
import '../services/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final idsSuivis = await StockageLocal.obtenirVillagesSuivis();
    final tousLesVillages = await ApiService.listerVillages();
    final connecte = await StockageLocal.estConnecte();
    setState(() {
      _mesVillages = tousLesVillages.where((v) => idsSuivis.contains(v.id)).toList();
      _connecte = connecte;
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
              onPressed: () async {
                Navigator.of(context).pop();
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EcranConnexion()),
                );
                _charger();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_connecte)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EpuiciColors.primaire,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Créez un compte pour sauvegarder vos églises suivies.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EcranConnexion()),
                        );
                        _charger();
                      },
                      child: const Text('Se connecter / Créer un compte'),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: EpuiciColors.primaire),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Connecté')),
                  TextButton(
                    onPressed: _deconnecter,
                    child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Églises suivies',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._mesVillages.map(
            (v) => ListTile(
              leading: const Icon(Icons.church_outlined, color: EpuiciColors.primaire),
              title: Text(v.nom),
              subtitle: Text(v.region),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _ajouterOuChangerVillage,
            icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
            label: const Text("Ajouter ou changer d'église"),
            style: OutlinedButton.styleFrom(
              foregroundColor: EpuiciColors.primaire,
              side: const BorderSide(color: EpuiciColors.primaire),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _ouvrirAlerte,
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Alerter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EpuiciColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_connecte)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Mon profil'),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EcranProfil()),
                );
                _charger();
              },
            ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            onTap: _afficherAPropos,
          ),
        ],
      ),
    );
  }
}
