import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'ecran_fil_actualite.dart';
import 'ecran_groupes.dart';
import 'ecran_live_vod.dart';
import 'ecran_dons_priere.dart';
import 'ecran_menu.dart';

class NavigationPrincipale extends StatefulWidget {
  const NavigationPrincipale({super.key});

  @override
  State<NavigationPrincipale> createState() => _NavigationPrincipaleState();
}

class _NavigationPrincipaleState extends State<NavigationPrincipale> {
  static const int _indexLiveVod = 2;
  static const int _indexDonsPriere = 3;

  int _indexActif = 0;

  @override
  Widget build(BuildContext context) {
    final ecrans = [
      const EcranFilActualite(),
      const EcranGroupes(),
      EcranLiveVod(actif: _indexActif == _indexLiveVod),
      EcranDonsPriere(actif: _indexActif == _indexDonsPriere),
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
