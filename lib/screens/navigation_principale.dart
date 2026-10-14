import 'package:flutter/material.dart';
import '../config/theme.dart';
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

class _NavigationPrincipaleState extends State<NavigationPrincipale> {
  late int _indexActif = widget.ongletInitial;

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
      body: IndexedStack(index: _indexActif, children: ecrans),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexActif,
        onTap: (index) => setState(() => _indexActif = index),
        selectedItemColor: EpuiciColors.primaire,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), activeIcon: Icon(Icons.forum), label: 'Groupes'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv_outlined), activeIcon: Icon(Icons.live_tv), label: 'Live & VOD'),
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism_outlined), activeIcon: Icon(Icons.volunteer_activism), label: 'Dons & Prière'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }
}
