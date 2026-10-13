import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../models/village_model.dart';
import '../services/api_service.dart';

class EcranAlerte extends StatefulWidget {
  const EcranAlerte({super.key});

  @override
  State<EcranAlerte> createState() => _EcranAlerteState();
}

class _EcranAlerteState extends State<EcranAlerte> {
  final _descriptionCtrl = TextEditingController();
  final List<XFile> _photos = [];
  final ImagePicker _picker = ImagePicker();

  List<Village> _villages = [];
  String? _villageChoisiId;
  bool _chargementVillages = true;
  bool _envoi = false;
  String _erreur = '';

  static const int _maxPhotos = 3;

  @override
  void initState() {
    super.initState();
    _chargerVillages();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerVillages() async {
    try {
      final villages = await ApiService.listerVillages();
      setState(() {
        _villages = villages;
        _chargementVillages = false;
      });
    } catch (e) {
      setState(() {
        _erreur = 'Impossible de charger les églises. Vérifiez votre connexion.';
        _chargementVillages = false;
      });
    }
  }

  Future<void> _ajouterPhoto(ImageSource source) async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxPhotos photos.')),
      );
      return;
    }
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null) {
      setState(() => _photos.add(image));
    }
  }

  void _choisirSourcePhoto() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.of(context).pop();
                _ajouterPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.of(context).pop();
                _ajouterPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _retirerPhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _envoyerAlerte() async {
    setState(() => _erreur = '');

    if (_villageChoisiId == null) {
      setState(() => _erreur = "Choisissez l'église concernée.");
      return;
    }
    if (_descriptionCtrl.text.trim().isEmpty) {
      setState(() => _erreur = "Décrivez l'évènement.");
      return;
    }

    setState(() => _envoi = true);
    try {
      await ApiService.envoyerAlerte(
        villageId: _villageChoisiId!,
        description: _descriptionCtrl.text.trim(),
        photos: _photos,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Votre alerte a été envoyée à l'admin de l'église.")),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerter')),
      body: _chargementVillages
          ? const Center(child: CircularProgressIndicator(color: EpuiciColors.primaire))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "Signalez un évènement à l'admin d'une église : décès, malade, "
                  "besoin de prière, urgence, etc. Décrivez la situation en quelques lignes et ajoutez "
                  "des photos si possible.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Text('Église concernée', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _villageChoisiId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    hintText: 'Sélectionnez une église',
                  ),
                  items: _villages
                      .map((v) => DropdownMenuItem(
                            value: v.id,
                            child: Text('${v.nom} — ${v.region}'),
                          ))
                      .toList(),
                  onChanged: (valeur) => setState(() => _villageChoisiId = valeur),
                ),
                const SizedBox(height: 20),
                Text('Description', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Décrivez l'évènement en quelques lignes...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Photos (facultatif)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ..._photos.asMap().entries.map(
                          (entree) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: FutureBuilder<Uint8List>(
                                  future: entree.value.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const SizedBox(width: 90, height: 90);
                                    }
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _retirerPhoto(entree.key),
                                ),
                              ),
                            ],
                          ),
                        ),
                    if (_photos.length < _maxPhotos)
                      InkWell(
                        onTap: _choisirSourcePhoto,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_erreur.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_erreur, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _envoi ? null : _envoyerAlerte,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EpuiciColors.primaire,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_envoi ? 'Envoi en cours...' : "Envoyer l'alerte"),
                ),
              ],
            ),
    );
  }
}
