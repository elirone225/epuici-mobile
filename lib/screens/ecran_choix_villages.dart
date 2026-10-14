import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/village_model.dart';
import '../services/api_service.dart';
import '../services/stockage_local.dart';
import 'navigation_principale.dart';

class EcranChoixVillages extends StatefulWidget {
  // Mode modification : ouvert depuis le menu pour changer d'église suivie,
  // plutôt que lors de l'onboarding initial.
  final bool modeModification;

  const EcranChoixVillages({super.key, this.modeModification = false});

  @override
  State<EcranChoixVillages> createState() => _EcranChoixVillagesState();
}

class _EcranChoixVillagesState extends State<EcranChoixVillages> {
  List<Village> _villages = [];
  // Un fidèle ne suit qu'une seule église.
  String? _villageSelectionne;
  String? _villageInitial;
  bool _chargement = true;
  String _erreur = '';
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final villages = await ApiService.listerVillages();
      final suivisActuels = widget.modeModification
          ? await StockageLocal.obtenirVillagesSuivis()
          : <String>[];
      setState(() {
        _villages = villages;
        _villageInitial = suivisActuels.isEmpty ? null : suivisActuels.first;
        _villageSelectionne = _villageInitial;
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur = "Impossible de charger les villages. Vérifiez votre connexion.";
        _chargement = false;
      });
    }
  }

  Future<void> _enregistrer() async {
    final id = _villageSelectionne;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez votre église.')),
      );
      return;
    }
    await StockageLocal.enregistrerVillagesSuivis([id]);

    if (id != _villageInitial && await StockageLocal.estConnecte()) {
      await ApiService.suivreVillageCompte(id);
    }

    if (!mounted) return;

    if (widget.modeModification) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NavigationPrincipale()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final villagesFiltres = _villages
        .where((v) => v.nom.toLowerCase().contains(_recherche.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.modeModification ? 'Mon église' : 'Choisissez votre église',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Sélectionnez votre église pour suivre ses actualités. Vous ne pouvez suivre qu'une seule église.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une église',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (valeur) => setState(() => _recherche = valeur),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _chargement
                ? const Center(child: CircularProgressIndicator(color: EpuiciColors.primaire))
                : _erreur.isNotEmpty
                    ? Center(child: Text(_erreur))
                    : villagesFiltres.isEmpty
                        ? const Center(child: Text('Aucune église trouvée.'))
                        : RadioGroup<String>(
                            groupValue: _villageSelectionne,
                            onChanged: (id) => setState(() => _villageSelectionne = id),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: villagesFiltres.length,
                              itemBuilder: (context, index) {
                                final village = villagesFiltres[index];
                                return RadioListTile<String>(
                                  value: village.id,
                                  activeColor: EpuiciColors.primaire,
                                  title: Text(village.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(village.region),
                                  controlAffinity: ListTileControlAffinity.trailing,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  tileColor: Colors.white,
                                );
                              },
                            ),
                          ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EpuiciColors.primaire,
                  foregroundColor: Colors.white,
                ),
                onPressed: _enregistrer,
                child: const Text('Enregistrer'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
