import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class EcranMotDePasseOublie extends StatefulWidget {
  const EcranMotDePasseOublie({super.key});

  @override
  State<EcranMotDePasseOublie> createState() => _EcranMotDePasseOublieState();
}

class _EcranMotDePasseOublieState extends State<EcranMotDePasseOublie> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _nouveauMotDePasseCtrl = TextEditingController();
  final _confirmerMotDePasseCtrl = TextEditingController();

  bool _codeEnvoye = false;
  bool _chargement = false;
  String _erreur = '';
  String _info = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _nouveauMotDePasseCtrl.dispose();
    _confirmerMotDePasseCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyerCode() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _erreur = 'Entrez votre e-mail.');
      return;
    }
    setState(() {
      _erreur = '';
      _chargement = true;
    });
    try {
      final message = await ApiService.demanderReinitialisationMotDePasse(
        email: _emailCtrl.text.trim(),
      );
      setState(() {
        _codeEnvoye = true;
        _info = message;
      });
    } catch (e) {
      setState(() => _erreur = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _chargement = false);
    }
  }

  Future<void> _reinitialiser() async {
    setState(() => _erreur = '');

    if (_codeCtrl.text.trim().isEmpty) {
      setState(() => _erreur = 'Entrez le code reçu par e-mail.');
      return;
    }
    if (_nouveauMotDePasseCtrl.text.length < 6) {
      setState(() => _erreur = 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }
    if (_nouveauMotDePasseCtrl.text != _confirmerMotDePasseCtrl.text) {
      setState(() => _erreur = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _chargement = true);
    try {
      await ApiService.reinitialiserMotDePasse(
        email: _emailCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        nouveauMotDePasse: _nouveauMotDePasseCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé. Vous pouvez vous connecter.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              _codeEnvoye
                  ? "Entrez le code reçu par e-mail ainsi que votre nouveau mot de passe."
                  : "Entrez l'e-mail associé à votre compte pour recevoir un code de réinitialisation.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              enabled: !_codeEnvoye,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
            ),
            if (_codeEnvoye) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Code reçu par e-mail',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nouveauMotDePasseCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmerMotDePasseCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (_info.isNotEmpty && _erreur.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_info, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ),
            if (_erreur.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_erreur, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _chargement ? null : (_codeEnvoye ? _reinitialiser : _envoyerCode),
              style: ElevatedButton.styleFrom(
                backgroundColor: EpuiciColors.primaire,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _chargement
                    ? 'Veuillez patienter...'
                    : (_codeEnvoye ? 'Réinitialiser le mot de passe' : 'Recevoir le code'),
              ),
            ),
            if (_codeEnvoye)
              TextButton(
                onPressed: _chargement
                    ? null
                    : () => setState(() {
                          _codeEnvoye = false;
                          _erreur = '';
                          _info = '';
                        }),
                child: const Text("Changer d'e-mail"),
              ),
          ],
        ),
      ),
    );
  }
}
