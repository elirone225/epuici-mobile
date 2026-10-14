import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/stockage_local.dart';
import 'ecran_choix_villages.dart';
import 'ecran_connexion.dart';

// Onglet "Dons & Prière" : grande animation du logo, puis les actions
// "Faire un don", "Payer la dîme" (pas encore disponibles) et
// "Demande de prière" (envoyée directement à l'admin de l'église suivie).
class EcranDonsPriere extends StatefulWidget {
  // Vrai quand l'onglet est affiché : l'animation est mise en pause sinon.
  final bool actif;

  const EcranDonsPriere({super.key, required this.actif});

  @override
  State<EcranDonsPriere> createState() => _EcranDonsPriereState();
}

class _EcranDonsPriereState extends State<EcranDonsPriere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur;

  @override
  void initState() {
    super.initState();
    _controleur = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.actif) _controleur.repeat();
  }

  @override
  void didUpdateWidget(covariant EcranDonsPriere ancien) {
    super.didUpdateWidget(ancien);
    if (widget.actif && !_controleur.isAnimating) {
      _controleur.repeat();
    } else if (!widget.actif && _controleur.isAnimating) {
      _controleur.stop();
    }
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  void _pasEncoreDisponible(String action) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(action),
        content: const Text('Pas encore disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _demandePriere() async {
    if (!await StockageLocal.estConnecte()) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text(
            "Vous devez avoir un compte et être connecté pour envoyer une demande de prière à l'admin de votre église.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EcranConnexion()),
                );
              },
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );
      return;
    }

    if ((await StockageLocal.obtenirVillagesSuivis()).isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Aucune église'),
          content: const Text(
            "Choisissez d'abord votre église : votre demande de prière sera envoyée à son admin.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const EcranChoixVillages(modeModification: true),
                  ),
                );
              },
              child: const Text('Choisir mon église'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final envoyee = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FormulairePriere(),
    );

    if (envoyee == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Votre demande de prière a été envoyée à l'admin de votre église."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dons & Prière')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(child: _LogoAnime(animation: _controleur)),
          const SizedBox(height: 8),
          Text(
            '« Que chacun donne comme il l\'a résolu en son cœur, '
            'car Dieu aime celui qui donne avec joie. »',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '2 Corinthiens 9:7',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 24),
          _CarteAction(
            icone: Icons.volunteer_activism_outlined,
            couleur: EpuiciColors.accent,
            titre: 'Faire un don',
            sousTitre: 'Soutenir les œuvres de votre église',
            onTap: () => _pasEncoreDisponible('Faire un don'),
          ),
          const SizedBox(height: 12),
          _CarteAction(
            icone: Icons.account_balance_wallet_outlined,
            couleur: EpuiciColors.primaire,
            titre: 'Payer la dîme',
            sousTitre: 'Rendre à Dieu la dîme de vos revenus',
            onTap: () => _pasEncoreDisponible('Payer la dîme'),
          ),
          const SizedBox(height: 12),
          _CarteAction(
            icone: Icons.favorite_outline,
            couleur: const Color(0xFF6A3FA0),
            titre: 'Demande de prière',
            sousTitre: "Confier un sujet de prière à l'admin de votre église",
            onTap: _demandePriere,
          ),
        ],
      ),
    );
  }
}

// Grand logo qui tourne au centre d'un halo lumineux, entouré d'ondes qui
// s'élargissent et de petites étoiles en orbite.
class _LogoAnime extends StatelessWidget {
  final Animation<double> animation;

  const _LogoAnime({required this.animation});

  static const _taille = 260.0;
  static const _tailleLogo = 150.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, logo) {
        final t = animation.value;
        // Respiration du logo (2 cycles par tour).
        final respiration = 1 + 0.05 * math.sin(t * 4 * math.pi);

        return SizedBox(
          width: _taille,
          height: _taille,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo doux derrière le logo.
              Container(
                width: _tailleLogo * 1.25 * respiration,
                height: _tailleLogo * 1.25 * respiration,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: EpuiciColors.primaireClair.withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              // Trois ondes décalées qui partent du logo et s'estompent.
              for (var i = 0; i < 3; i++) _onde((t * 2 + i / 3) % 1),
              // Étoiles en orbite.
              for (var i = 0; i < 6; i++) _etoile(t, i),
              Transform.scale(
                scale: respiration,
                child: Transform.rotate(angle: t * 2 * math.pi, child: logo),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: _tailleLogo,
        height: _tailleLogo,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Image.asset('assets/images/logo.png'),
      ),
    );
  }

  Widget _onde(double progression) {
    final taille = _tailleLogo + (_taille - _tailleLogo) * progression;
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: EpuiciColors.primaire.withValues(alpha: 0.5 * (1 - progression)),
          width: 2,
        ),
      ),
    );
  }

  Widget _etoile(double t, int index) {
    final angle = -t * 2 * math.pi + index * math.pi / 3;
    final rayon = _tailleLogo / 2 + 28;
    final scintillement = 0.5 + 0.5 * math.sin(t * 6 * math.pi + index);
    return Transform.translate(
      offset: Offset(math.cos(angle) * rayon, math.sin(angle) * rayon),
      child: Opacity(
        opacity: 0.4 + 0.6 * scintillement,
        child: Icon(
          Icons.auto_awesome,
          size: 14 + 4 * scintillement,
          color: index.isEven ? EpuiciColors.accent : EpuiciColors.primaireClair,
        ),
      ),
    );
  }
}

class _CarteAction extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String titre;
  final String sousTitre;
  final VoidCallback onTap;

  const _CarteAction({
    required this.icone,
    required this.couleur,
    required this.titre,
    required this.sousTitre,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: couleur),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      sousTitre,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// Champ de saisie de la demande de prière, ouvert en bas de l'écran.
// Se ferme avec `true` une fois la demande envoyée.
class _FormulairePriere extends StatefulWidget {
  const _FormulairePriere();

  @override
  State<_FormulairePriere> createState() => _FormulairePriereState();
}

class _FormulairePriereState extends State<_FormulairePriere> {
  final _texteCtrl = TextEditingController();
  bool _envoi = false;
  String _erreur = '';

  @override
  void dispose() {
    _texteCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final texte = _texteCtrl.text.trim();
    if (texte.isEmpty) {
      setState(() => _erreur = 'Veuillez écrire votre demande de prière.');
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = '';
    });
    try {
      await ApiService.envoyerDemandePriere(texte);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _erreur = e.toString().replaceAll('Exception: ', '');
          _envoi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Demande de prière', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            "Votre demande sera envoyée directement à l'admin de votre église.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _texteCtrl,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Écrivez ici votre sujet de prière...',
              border: OutlineInputBorder(),
            ),
          ),
          if (_erreur.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_erreur, style: const TextStyle(color: Colors.red)),
            ),
          ElevatedButton.icon(
            onPressed: _envoi ? null : _envoyer,
            style: ElevatedButton.styleFrom(
              backgroundColor: EpuiciColors.primaire,
              foregroundColor: Colors.white,
            ),
            icon: _envoi
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send),
            label: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
