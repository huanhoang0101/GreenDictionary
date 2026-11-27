
import 'package:flutter/material.dart';

import '../widgets/header.dart';
import 'home_page.dart';
import 'vocabulary_groups_page.dart';
import 'dashboard_page.dart';
import 'grammar_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // Mỗi mục có Navigator riêng để các trang con
  // luôn được mở bên dưới Header chung.
  Widget _buildTabNavigator(Widget page) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => page,
        );
      },
    );
  }

  late final List<Widget> _pages = [
    _buildTabNavigator(const HomePage()),

    _buildTabNavigator(const VocabularyGroupsPage()),

    _buildTabNavigator(const GrammarPage()),

    _buildTabNavigator(
      const PlaceholderPage(
        title: 'Dịch câu',
        description: 'Trang dịch câu sẽ được phát triển sau.',
        icon: Icons.translate,
      ),
    ),

    _buildTabNavigator(
      const PlaceholderPage(
        title: 'Thi thử JLPT',
        description: 'Trang thi thử JLPT sẽ được phát triển sau.',
        icon: Icons.assignment_outlined,
      ),
    ),

    _buildTabNavigator(
      DashboardPage(onNavigate: _selectPage),
    ),
  ];

  void _selectPage(int index) {
    if (index < 0 || index >= _pages.length) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Header(
            selectedIndex: _selectedIndex,
            onMenuSelected: _selectPage,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: const Color(0xFF35A995),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(description),
        ],
      ),
    );
  }
}
