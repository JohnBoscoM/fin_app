import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';
import 'services/storage_service.dart';
import 'providers/theme_provider.dart';
import 'providers/localization_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/income_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/category_provider.dart';
import 'themes/app_themes.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/bottom_nav_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final language = storageService.getLanguage();

  final initialLocale = language != null
      ? Locale(language, language == 'en' ? 'US' : 'SE')
      : _getDeviceLocale();

  runApp(MyApp(
    storageService: storageService,
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

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  final StorageService storageService;
  final Locale initialLocale;

  const MyApp({
    super.key,
    required this.storageService,
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
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return BottomNavShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const DashboardScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/expenses',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const ExpensesScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/goals',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const GoalsScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const SettingsScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(widget.storageService),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              LocalizationProvider(widget.initialLocale, widget.storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => CurrencyProvider(widget.storageService),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CategoryProvider(widget.storageService)..loadCategories(),
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
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(widget.storageService)..loadBudgets(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              PortfolioProvider(widget.storageService)..loadAssets(),
        ),
      ],
      child: Consumer2<ThemeProvider, LocalizationProvider>(
        builder: (context, themeProvider, localizationProvider, _) {
          return MaterialApp.router(
            title: 'Budget App',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme(accent: themeProvider.accentColor),
            darkTheme: AppThemes.darkTheme(accent: themeProvider.accentColor),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
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

