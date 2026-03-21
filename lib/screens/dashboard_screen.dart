import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/localization_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              context.read<LocalizationProvider>().toggleLanguage();
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_4),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Dashboard Screen - Coming Soon'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Portfolio'),
        ],
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.go('/expenses');
              break;
            case 2:
              context.go('/goals');
              break;
            case 3:
              context.go('/portfolio');
              break;
          }
        },
      ),
    );
  }
}

extension GoExtension on BuildContext {
  void go(String path) {
    // Placeholder for navigation
  }
}
