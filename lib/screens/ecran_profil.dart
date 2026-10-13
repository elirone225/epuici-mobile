import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class EcranProfil extends StatefulWidget {
  const EcranProfil({super.key});

  @override
  State<EcranProfil> createState() => _EcranProfilState();
}

class _EcranProfilState extends State<EcranProfil> {
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _telephone = '';
  String? _photoProfilActuelle;
  XFile? _nouvellePhoto;
  bool _chargement = true;
  bool _enregistrement = false;
  String _erreur = '';

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerProfil() async {
    try {
      final profil = await ApiService.obtenirMonProfil();
      setState(() {
        _nomCtrl.text = profil['nom'] ?? '';
        _emailCtrl.text = profil['email'] ?? '';
        _telephone = profil['telephone'] ?? '';
        _photoProfilActuelle = profil['photoProfil'];
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur = e.toString().replaceAll('Exception: ', '');
        _chargement = false;
      });
    }
  }

  Future<void> _choisirPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() => _nouvellePhoto = image);
    }
  }

  Future<void> _enregistrer() async {
    setState(() {
      _erreur = '';
      _enregistrement = true;
    });
    try {
      await ApiService.modifierMonProfil(
        nom: _nomCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        photoProfil: _nouvellePhoto,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: EpuiciColors.primaire))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: GestureDetector(
                      onTap: _choisirPhoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: EpuiciColors.primaire.withValues(alpha: 0.1),
                            backgroundImage: _imageAffichee(),
                            child: _imageAffichee() == null
                                ? const Icon(Icons.person_outline, size: 40, color: EpuiciColors.primaire)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: EpuiciColors.primaire,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: _telephone),
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      helperText:
                          "Permet de récupérer votre compte en cas d'oubli du mot de passe.",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_erreur.isNotEmpty)
                    Text(_erreur, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _enregistrement ? null : _enregistrer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EpuiciColors.primaire,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_enregistrement ? 'Enregistrement...' : 'Enregistrer'),
                  ),
                ],
              ),
            ),
    );
  }

  ImageProvider? _imageAffichee() {
    if (_nouvellePhoto != null) {
      return kIsWeb
          ? NetworkImage(_nouvellePhoto!.path)
          : FileImage(File(_nouvellePhoto!.path)) as ImageProvider;
    }
    if (_photoProfilActuelle != null && _photoProfilActuelle!.isNotEmpty) {
      return CachedNetworkImageProvider(_photoProfilActuelle!);
    }
    return null;
  }
}
