import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/animations.dart';
import '../services/api_service.dart';
import '../services/stockage_local.dart';
import 'navigation_principale.dart';
import 'ecran_inscription.dart';
import 'ecran_mot_de_passe_oublie.dart';

class EcranConnexion extends StatefulWidget {
  const EcranConnexion({super.key});

  @override
  State<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends State<EcranConnexion> {
  final _telephoneCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool _chargement = false;
  String _erreur = '';

  Future<void> _connecter() async {
    setState(() {
      _erreur = '';
      _chargement = true;
    });
    try {
      final donnees = await ApiService.connecterUtilisateur(
        telephone: _telephoneCtrl.text.trim(),
        motDePasse: _motDePasseCtrl.text,
      );
      await StockageLocal.enregistrerToken(donnees['token']);

      // Synchronise l'église suivie (une seule par fidèle) : celle déjà
      // enregistrée sur le compte (ex: choisie depuis un autre appareil) est
      // prioritaire ; sinon, celle choisie localement avant la connexion est
      // envoyée vers le compte.
      final villagesLocaux = await StockageLocal.obtenirVillagesSuivis();
      final List villagesServeur = donnees['villagesSuivis'] ?? [];
      final idsServeur = villagesServeur
          .map((v) => v['_id'].toString())
          .toList();

      if (idsServeur.isEmpty && villagesLocaux.isNotEmpty) {
        await ApiService.suivreVillageCompte(villagesLocaux.first);
      }
      await StockageLocal.enregistrerVillagesSuivis(
        idsServeur.isNotEmpty ? [idsServeur.first] : villagesLocaux,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const NavigationPrincipale()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _erreur = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarEpuici(titre: Text('Connexion')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Apparition(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: EpuiciColors.primaire.withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 96,
                    height: 96,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bon retour parmi nous',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 22),
              ),
              Text(
                "Connectez-vous pour retrouver l'actualité de votre église.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _telephoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _motDePasseCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EcranMotDePasseOublie(),
                      ),
                    );
                  },
                  child: const Text('Mot de passe oublié ?'),
                ),
              ),
              const SizedBox(height: 8),
              if (_erreur.isNotEmpty)
                Text(
                  _erreur,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _chargement ? null : _connecter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EpuiciColors.primaire,
                  foregroundColor: Colors.white,
                ),
                child: Text(_chargement ? 'Connexion...' : 'Se connecter'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EcranInscription()),
                  );
                },
                child: const Text("Pas encore de compte ? S'inscrire"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
