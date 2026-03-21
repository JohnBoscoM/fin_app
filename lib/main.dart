import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'services/storage_service.dart';
import 'providers/theme_provider.dart';
import 'providers/localization_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/income_provider.dart';
import 'providers/goals_provider.dart';
import 'themes/app_themes.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/portfolio_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storageService = StorageService();
  await storageService.init();
  
  final isDarkMode = storageService.isDarkMode();
  final language = storageService.getLanguage();
  
  final initialLocale = language != null 
      ? Locale(language, language == 'en' ? 'US' : 'SE')
      : _getDeviceLocale();
  
  runApp(MyApp(
    storageService: storageService,
    initialDarkMode: isDarkMode,
    initialLocale: initialLocale,
  ));
}

Locale _getDeviceLocale() {
  final String deviceLocale = Intl.getCurrentLocale();
  if (deviceLocale.startsWith('sv')) {
    return const Locale('sv', 'SE');
  }
  return const Locale('en', 'US');
}

class MyApp extends StatefulWidget {
  final StorageService storageService;
  final bool initialDarkMode;
  final Locale initialLocale;

  const MyApp({
    super.key,
    required this.storageService,
    required this.initialDarkMode,
    required this.initialLocale,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
  }

  GoRouter _buildRouter() {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/expenses',
          name: 'expenses',
          builder: (context, state) => const ExpensesScreen(),
        ),
        GoRoute(
          path: '/goals',
          name: 'goals',
          builder: (context, state) => const GoalsScreen(),
        ),
        GoRoute(
          path: '/portfolio',
          name: 'portfolio',
          builder: (context, state) => const PortfolioScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(widget.initialDarkMode),
        ),
        ChangeNotifierProvider(
          create: (_) => LocalizationProvider(widget.initialLocale),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(widget.storageService)..loadExpenses(),
        ),
        ChangeNotifierProvider(
          create: (_) => IncomeProvider(widget.storageService)..loadIncomes(),
        ),
        ChangeNotifierProvider(
          create: (_) => GoalsProvider(widget.storageService)..loadGoals(),
        ),
      ],
      child: Consumer2<ThemeProvider, LocalizationProvider>(
        builder: (context, themeProvider, localizationProvider, _) {
          return MaterialApp.router(
            title: 'Budget App',
            theme: AppThemes.lightTheme(),
            darkTheme: AppThemes.darkTheme(),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('sv', 'SE'),
            ],
            locale: localizationProvider.locale,
          );
        },
      ),
    );
  }
}

