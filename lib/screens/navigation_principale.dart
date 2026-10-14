import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'ecran_fil_actualite.dart';
import 'ecran_groupes.dart';
import 'ecran_pub_reportage.dart';
import 'ecran_dons_priere.dart';
import 'ecran_menu.dart';

class NavigationPrincipale extends StatefulWidget {
  const NavigationPrincipale({super.key});

  @override
  State<NavigationPrincipale> createState() => _NavigationPrincipaleState();
}

class _NavigationPrincipaleState extends State<NavigationPrincipale> {
  static const int _indexPubReportage = 2;
  static const int _indexDonsPriere = 3;

  int _indexActif = 0;

  @override
  Widget build(BuildContext context) {
    final ecrans = [
      const EcranFilActualite(),
      const EcranGroupes(),
      EcranPubReportage(actif: _indexActif == _indexPubReportage),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: 'Groupes'),
          BottomNavigationBarItem(icon: Icon(Icons.video_collection_outlined), label: 'Pub & Reportage'),
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism_outlined), label: 'Dons & Prière'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }
}
