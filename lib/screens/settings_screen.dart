import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/currency_provider.dart';
import '../themes/app_themes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final locProvider = context.watch<LocalizationProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Text(l.settings, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),

            // Appearance section
            Text(
              l.appearance,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: isDark ? l.darkMode : l.lightMode,
              trailing: Switch.adaptive(
                value: isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ),
            const SizedBox(height: 24),

            // Language section
            Text(
              l.language,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.language_rounded,
              title: l.language,
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 0.5,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: locProvider.locale.languageCode,
                    isDense: true,
                    items: [
                      DropdownMenuItem(value: 'en', child: Text(l.english)),
                      DropdownMenuItem(value: 'sv', child: Text(l.swedish)),
                    ],
                    onChanged: (code) {
                      if (code != null) {
                        locProvider.setLocale(Locale(code));
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Currency section
            Text(
              l.currency,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.attach_money_rounded,
              title: l.currency,
              trailing: GestureDetector(
                onTap: () => _showCurrencyPicker(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${currencyProvider.current.symbol}  ${currencyProvider.currencyCode}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // About section
            Text(
              l.about,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: l.version,
              trailing: Text(
                '1.0.0',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final currencyProvider = context.read<CurrencyProvider>();

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(l.selectCurrency,
                    style: theme.textTheme.titleLarge),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: CurrencyProvider.supportedCurrencies.length,
                  itemBuilder: (context, index) {
                    final c = CurrencyProvider.supportedCurrencies[index];
                    final isSelected =
                        c.code == currencyProvider.currencyCode;
                    return ListTile(
                      leading: Text(c.symbol,
                          style: theme.textTheme.titleMedium),
                      title: Text(c.name),
                      subtitle: Text(c.code),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: () {
                        currencyProvider.setCurrency(c.code);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: theme.textTheme.bodyLarge),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
