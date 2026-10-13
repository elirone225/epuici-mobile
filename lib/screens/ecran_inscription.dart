import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/stockage_local.dart';
import 'ecran_choix_villages.dart';
import 'navigation_principale.dart';

class EcranInscription extends StatefulWidget {
  const EcranInscription({super.key});

  @override
  State<EcranInscription> createState() => _EcranInscriptionState();
}

class _EcranInscriptionState extends State<EcranInscription> {
  final _nomCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _photoProfil;
  bool _chargement = false;
  String _erreur = '';

  Future<void> _choisirPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() => _photoProfil = image);
    }
  }

  Future<void> _inscrire() async {
    setState(() {
      _erreur = '';
      _chargement = true;
    });
    try {
      final donnees = await ApiService.inscrireUtilisateur(
        nom: _nomCtrl.text.trim(),
        telephone: _telephoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        motDePasse: _motDePasseCtrl.text,
        photoProfil: _photoProfil,
      );
      await StockageLocal.enregistrerToken(donnees['token']);
      unawaited(NotificationService.demanderPermissionEtEnregistrerToken());

      final villagesLocaux = await StockageLocal.obtenirVillagesSuivis();
      for (final id in villagesLocaux) {
        await ApiService.suivreVillageCompte(id);
      }

      final onboardingFait = await StockageLocal.onboardingDejaFait();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => onboardingFait
                ? const NavigationPrincipale()
                : const EcranChoixVillages(),
          ),
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
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _choisirPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: EpuiciColors.primaire.withValues(alpha: 0.1),
                      backgroundImage: _photoProfil != null
                          ? (kIsWeb
                              ? NetworkImage(_photoProfil!.path)
                              : FileImage(File(_photoProfil!.path))) as ImageProvider
                          : null,
                      child: _photoProfil == null
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
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Photo de profil (facultatif)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
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
              controller: _telephoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail (facultatif, pour récupérer votre compte)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _motDePasseCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (_erreur.isNotEmpty)
              Text(_erreur, style: const TextStyle(color: Colors.red, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _chargement ? null : _inscrire,
              style: ElevatedButton.styleFrom(
                backgroundColor: EpuiciColors.primaire,
                foregroundColor: Colors.white,
              ),
              child: Text(_chargement ? 'Création...' : 'Créer mon compte'),
            ),
          ],
        ),
      ),
    );
  }
}
