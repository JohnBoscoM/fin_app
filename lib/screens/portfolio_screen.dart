import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../providers/portfolio_provider.dart';
import '../providers/currency_provider.dart';
import '../themes/app_themes.dart';
import '../widgets/donut_chart.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  static const _typeColors = <AssetType, Color>{
    AssetType.stock: AppColors.primary,
    AssetType.fund: Color(0xFF4ECDC4),
    AssetType.crypto: Color(0xFFFFD93D),
    AssetType.realEstate: Color(0xFFFF6B6B),
    AssetType.cash: AppColors.positive,
    AssetType.other: Color(0xFFC9ADA7),
  };

  void _showAddAssetSheet(BuildContext context, {Asset? asset}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddAssetSheet(
        asset: asset,
        onSave: (a) {
          if (asset != null) {
            context.read<PortfolioProvider>().updateAsset(a);
          } else {
            context.read<PortfolioProvider>().addAsset(a);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final currency = context.watch<CurrencyProvider>();
    String fmt(double v) => currency.format(v);

    final provider = context.watch<PortfolioProvider>();
    final assets = provider.assets;
    final totalValue = provider.getTotalPortfolioValue();
    final totalGainLoss = provider.getTotalGainLoss();
    final gainPercent = provider.getTotalGainLossPercent();
    final grouped = provider.getAssetsByType();
    final allocations = provider.getAllocationPercentages();

    return Scaffold(
      body: SafeArea(
        child: assets.isEmpty
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.portfolio,
                            style: theme.textTheme.headlineSmall),
                        GestureDetector(
                          onTap: () => _showAddAssetSheet(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.account_balance_wallet_rounded,
                      title: l.noAssetsYet,
                      subtitle: l.trackInvestments,
                      buttonText: l.addAsset,
                      onButtonPressed: () => _showAddAssetSheet(context),
                    ),
                  ),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Portfolio',
                              style: theme.textTheme.headlineSmall),
                          GestureDetector(
                            onTap: () => _showAddAssetSheet(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Total value card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.totalValue,
                                style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text(
                              fmt(totalValue),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  totalGainLoss >= 0
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  color: totalGainLoss >= 0
                                      ? AppColors.positive
                                      : AppColors.negative,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${totalGainLoss >= 0 ? '+' : ''}${fmt(totalGainLoss)}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: totalGainLoss >= 0
                                        ? AppColors.positive
                                        : AppColors.negative,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${gainPercent >= 0 ? '+' : ''}${gainPercent.toStringAsFixed(1)}%',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: totalGainLoss >= 0
                                        ? AppColors.positive
                                        : AppColors.negative,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Allocation chart
                  if (allocations.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.allocation,
                                  style: theme.textTheme.titleLarge),
                              const SizedBox(height: 16),
                              Center(
                                child: DonutChart(
                                  size: 160,
                                  strokeWidth: 22,
                                  segments:
                                      allocations.entries.map((entry) {
                                    final type = AssetType.values.firstWhere(
                                      (t) => t.displayName == entry.key,
                                      orElse: () => AssetType.other,
                                    );
                                    return DonutSegment(
                                      label: entry.key,
                                      value: entry.value,
                                      color: _typeColors[type] ??
                                          AppColors.other,
                                    );
                                  }).toList(),
                                  center: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(l.total,
                                          style: theme.textTheme.bodySmall),
                                      Text(
                                        '${assets.length}',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 6,
                                children: allocations.entries.map((entry) {
                                  final type = AssetType.values.firstWhere(
                                    (t) => t.displayName == entry.key,
                                    orElse: () => AssetType.other,
                                  );
                                  final color =
                                      _typeColors[type] ?? AppColors.other;
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${entry.key} ${entry.value.toStringAsFixed(0)}%',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Asset groups
                  ...grouped.entries.map((group) {
                    final typeColor =
                        _typeColors[group.key] ?? AppColors.other;
                    final typeTotal = group.value
                        .fold<double>(0, (s, a) => s + a.currentValue);
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: typeColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      group.key.displayName,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                                Text(
                                  fmt(typeTotal),
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...group.value.map((asset) {
                              return Dismissible(
                                key: ValueKey(asset.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.negative
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.delete_rounded,
                                      color: AppColors.negative),
                                ),
                                onDismissed: (_) {
                                  context
                                      .read<PortfolioProvider>()
                                      .deleteAsset(asset.id);
                                },
                                child: GestureDetector(
                                  onTap: () => _showAddAssetSheet(context,
                                      asset: asset),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: Border.all(
                                        color: theme.colorScheme.outline,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                asset.name,
                                                style:
                                                    theme.textTheme.bodyLarge,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                fmt(asset.currentValue),
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${asset.gainLoss >= 0 ? '+' : ''}${fmt(asset.gainLoss)}',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: asset.gainLoss >= 0
                                                    ? AppColors.positive
                                                    : AppColors.negative,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${asset.gainLossPercent >= 0 ? '+' : ''}${asset.gainLossPercent.toStringAsFixed(1)}%',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: asset.gainLoss >= 0
                                                    ? AppColors.positive
                                                    : AppColors.negative,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
    );
  }
}

class _AddAssetSheet extends StatefulWidget {
  final Asset? asset;
  final ValueChanged<Asset> onSave;

  const _AddAssetSheet({this.asset, required this.onSave});

  @override
  State<_AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<_AddAssetSheet> {
  late TextEditingController _nameController;
  late TextEditingController _currentValueController;
  late TextEditingController _purchaseValueController;
  late TextEditingController _notesController;
  AssetType _type = AssetType.stock;
  DateTime _purchaseDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset?.name ?? '');
    _currentValueController = TextEditingController(
      text: widget.asset?.currentValue.toString() ?? '',
    );
    _purchaseValueController = TextEditingController(
      text: widget.asset?.purchaseValue.toString() ?? '',
    );
    _notesController =
        TextEditingController(text: widget.asset?.notes ?? '');
    _type = widget.asset?.type ?? AssetType.stock;
    _purchaseDate = widget.asset?.purchaseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentValueController.dispose();
    _purchaseValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final currentVal =
        double.tryParse(_currentValueController.text.trim());
    final purchaseVal =
        double.tryParse(_purchaseValueController.text.trim());
    if (name.isEmpty || currentVal == null || purchaseVal == null) return;

    widget.onSave(Asset(
      id: widget.asset?.id ?? const Uuid().v4(),
      name: name,
      type: _type,
      currentValue: currentVal,
      purchaseValue: purchaseVal,
      purchaseDate: _purchaseDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 8, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                widget.asset != null ? l.editAsset : l.addAsset,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l.assetName),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            // Type dropdown
            DropdownButtonFormField<AssetType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: l.assetType),
              items: AssetType.values.map((t) {
                return DropdownMenuItem(
                    value: t, child: Text(t.displayName));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentValueController,
              decoration:
                  InputDecoration(labelText: l.currentValue),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _purchaseValueController,
              decoration:
                  InputDecoration(labelText: l.purchaseValue),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration:
                  InputDecoration(labelText: l.notesOptional),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l.save,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
