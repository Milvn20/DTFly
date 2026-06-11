import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/jugadores_screen.dart';
import 'package:flutter_application_1/theme/dtfly_theme.dart';
import 'package:flutter_application_1/widgets/dtfly_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _screens = [
    const Center(child: Text('Inicio')),
    const JugadoresScreen(),
    const Center(child: Text('Estadísticas')),
    const Center(child: Text('Reportes')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DtflyTheme.background,
      appBar: AppBar(title: const Text('DTFly')),
      body: _screens[_index],
      bottomNavigationBar: DtflyBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          DtflyNavItem(icon: Icons.home_outlined, label: 'Inicio'),
          DtflyNavItem(icon: Icons.people_outline, label: 'Plantel'),
          DtflyNavItem(icon: Icons.bar_chart, label: 'Estadísticas'),
          DtflyNavItem(icon: Icons.description_outlined, label: 'Reportes'),
        ],
      ),
    );
  }
}
