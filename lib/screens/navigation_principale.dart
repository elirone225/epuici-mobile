import 'package:flutter/material.dart';
import 'ecran_fil_actualite.dart';
import 'ecran_groupes.dart';
import 'ecran_live_vod.dart';
import 'ecran_dons_priere.dart';
import 'ecran_menu.dart';

class NavigationPrincipale extends StatefulWidget {
  static const int ongletLiveVod = 2;
  static const int ongletDonsPriere = 3;

  // Onglet affiché à l'ouverture (ex : "Live & VOD" quand l'église est en direct).
  final int ongletInitial;

  const NavigationPrincipale({super.key, this.ongletInitial = 0});

  @override
  State<NavigationPrincipale> createState() => _NavigationPrincipaleState();
}

class _NavigationPrincipaleState extends State<NavigationPrincipale>
    with SingleTickerProviderStateMixin {
  late int _indexActif = widget.ongletInitial;

  // Fondu + léger glissement à chaque changement d'onglet.
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
  late final Animation<double> _courbe =
      CurvedAnimation(parent: _transition, curve: Curves.easeOutCubic);

  void _changerOnglet(int index) {
    if (index == _indexActif) return;
    setState(() => _indexActif = index);
    _transition.forward(from: 0);
  }

  @override
  void dispose() {
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ecrans = [
      const EcranFilActualite(),
      const EcranGroupes(),
      EcranLiveVod(actif: _indexActif == NavigationPrincipale.ongletLiveVod),
      EcranDonsPriere(actif: _indexActif == NavigationPrincipale.ongletDonsPriere),
      const EcranMenu(),
    ];

    return Scaffold(
      body: FadeTransition(
        opacity: _courbe,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.015), end: Offset.zero)
              .animate(_courbe),
          child: IndexedStack(index: _indexActif, children: ecrans),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexActif,
        onDestinationSelected: _changerOnglet,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'Groupes'),
          NavigationDestination(icon: Icon(Icons.live_tv_outlined), selectedIcon: Icon(Icons.live_tv), label: 'Live & VOD'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), selectedIcon: Icon(Icons.volunteer_activism), label: 'Dons & Prière'),
          NavigationDestination(icon: Icon(Icons.menu), selectedIcon: Icon(Icons.menu_open), label: 'Menu'),
        ],
      ),
    );
  }
}
