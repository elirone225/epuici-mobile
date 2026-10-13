import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/village_model.dart';
import '../services/api_service.dart';
import '../services/stockage_local.dart';
import 'navigation_principale.dart';

class EcranChoixVillages extends StatefulWidget {
  // Mode modification : ouvert depuis le menu pour ajouter/retirer des villages
  // suivis, plutôt que lors de l'onboarding initial.
  final bool modeModification;

  const EcranChoixVillages({super.key, this.modeModification = false});

  @override
  State<EcranChoixVillages> createState() => _EcranChoixVillagesState();
}

class _EcranChoixVillagesState extends State<EcranChoixVillages> {
  List<Village> _villages = [];
  final Set<String> _villagesSelectionnes = {};
  Set<String> _villagesInitiaux = {};
  bool _chargement = true;
  String _erreur = '';
  String _recherche = '';

  static const int _maxVillages = 5;

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
        _villagesInitiaux = suivisActuels.toSet();
        _villagesSelectionnes.addAll(_villagesInitiaux);
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur = "Impossible de charger les villages. Vérifiez votre connexion.";
        _chargement = false;
      });
    }
  }

  void _toggleVillage(String id) {
    setState(() {
      if (_villagesSelectionnes.contains(id)) {
        _villagesSelectionnes.remove(id);
      } else {
        if (_villagesSelectionnes.length >= _maxVillages) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vous pouvez suivre $_maxVillages églises maximum.')),
          );
          return;
        }
        _villagesSelectionnes.add(id);
      }
    });
  }

  Future<void> _enregistrer() async {
    if (_villagesSelectionnes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins une église.')),
      );
      return;
    }
    final idsSelectionnes = _villagesSelectionnes.toList();
    await StockageLocal.enregistrerVillagesSuivis(idsSelectionnes);

    if (await StockageLocal.estConnecte()) {
      final ajoutes = _villagesSelectionnes.difference(_villagesInitiaux);
      final retires = _villagesInitiaux.difference(_villagesSelectionnes);
      for (final id in ajoutes) {
        await ApiService.suivreVillageCompte(id);
      }
      for (final id in retires) {
        await ApiService.neSuivrePlusVillageCompte(id);
      }
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
          widget.modeModification ? 'Mes églises suivies' : 'Choisissez vos églises',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Sélectionnez une ou plusieurs églises pour suivre leurs actualités (max $_maxVillages).',
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
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: villagesFiltres.length,
                            itemBuilder: (context, index) {
                              final village = villagesFiltres[index];
                              final selectionne = _villagesSelectionnes.contains(village.id);
                              return CheckboxListTile(
                                value: selectionne,
                                onChanged: (_) => _toggleVillage(village.id),
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
