import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../providers/goals_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/theme_provider.dart';
import '../themes/app_themes.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  void _showAddGoalSheet(BuildContext context, {SavingsGoal? goal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddGoalSheet(
        goal: goal,
        onSave: (g) {
          if (goal != null) {
            context.read<GoalsProvider>().updateGoal(g);
          } else {
            context.read<GoalsProvider>().addGoal(g);
          }
        },
      ),
    );
  }

  void _showAddFundsSheet(BuildContext context, SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddFundsSheet(
        goal: goal,
        onAdd: (amount) {
          context.read<GoalsProvider>().addFundsToGoal(goal.id, amount);
          context.read<ExpenseProvider>().addExpense(Expense(
            id: const Uuid().v4(),
            name: goal.name,
            amount: amount,
            category: 'savings',
            isRecurring: false,
            createdAt: DateTime.now(),
          ));
        },
      ),
    );
  }

  void _showSavingsSheet(BuildContext context, List<SavingsGoal> activeGoals) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.selectGoal, style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...activeGoals.map((goal) {
                  final pct = goal.targetAmount > 0
                      ? (goal.currentAmount / goal.targetAmount * 100)
                          .clamp(0, 100)
                          .toStringAsFixed(0)
                      : '0';
                  return ListTile(
                    leading: Text(goal.emoji,
                        style: const TextStyle(fontSize: 28)),
                    title: Text(goal.name),
                    subtitle: Text('$pct%'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddFundsSheet(context, goal);
                    },
                  );
                }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final currency = context.watch<CurrencyProvider>();
    String fmt(double v) => currency.format(v, decimalDigits: 0);

    final goalsProvider = context.watch<GoalsProvider>();
    final goals = goalsProvider.goals;
    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    final completedGoals = goals.where((g) => g.isCompleted).toList();
    final totalSaved = goalsProvider.getTotalSavingsCurrent();
    final totalTarget = goalsProvider.getTotalSavingsTarget();
    final isMonochrome = context.watch<ThemeProvider>().isMonochrome;

    return Scaffold(
      body: SafeArea(
        child: goals.isEmpty
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.savingsGoals,
                            style: theme.textTheme.headlineSmall),
                        _AddButton(
                            onTap: () => _showAddGoalSheet(context)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.flag_rounded,
                      title: l.noSavingsGoalsYet,
                      subtitle: l.startSaving,
                      buttonText: l.addGoal,
                      onButtonPressed: () => _showAddGoalSheet(context),
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
                        Text(l.savingsGoals,
                            style: theme.textTheme.headlineSmall),
                        Row(
                          children: [
                            if (activeGoals.isNotEmpty)
                              _SavingsButton(
                                onTap: () => _showSavingsSheet(context, activeGoals),
                              ),
                            const SizedBox(width: 8),
                            _AddButton(
                                onTap: () => _showAddGoalSheet(context)),
                          ],
                        ),
                      ],
                      ),
                    ),
                  ),
                  // Summary card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.totalSaved,
                                style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    fmt(totalSaved),
                                    style:
                                        theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${l.ofLabel} ${fmt(totalTarget)}',
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AnimatedProgressBar(
                              progress: totalTarget > 0
                                  ? (totalSaved / totalTarget * 100)
                                  : 0,
                              height: 6,
                              foregroundColor: isMonochrome ? const Color(0xFFA5D6A7) : theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${activeGoals.length} ${l.active}  ·  ${completedGoals.length} ${l.completed}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Active goals grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final goal = activeGoals[index];
                          return _GoalCard(
                            goal: goal,
                            formatCurrency: (a) => fmt(a),
                            onTap: () =>
                                _showAddFundsSheet(context, goal),
                            onLongPress: () =>
                                _showAddGoalSheet(context, goal: goal),
                          );
                        },
                        childCount: activeGoals.length,
                      ),
                    ),
                  ),
                  // Completed section
                  if (completedGoals.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text(
                          l.completed,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final goal = completedGoals[index];
                            return _GoalCard(
                              goal: goal,
                              formatCurrency: (a) => fmt(a),
                              isCompleted: true,
                              onTap: () {},
                              onLongPress: () =>
                                  _showAddGoalSheet(context, goal: goal),
                            );
                          },
                          childCount: completedGoals.length,
                        ),
                      ),
                    ),
                  ],
                  if (completedGoals.isEmpty)
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                ],
              ),
      ),
    );
  }
}

class _GoalCard extends StatefulWidget {
  final SavingsGoal goal;
  final String Function(double) formatCurrency;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GoalCard({
    required this.goal,
    required this.formatCurrency,
    this.isCompleted = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = widget.goal;
    final isMonochrome = context.watch<ThemeProvider>().isMonochrome;
    final color = isMonochrome
        ? const Color(0xFFA5D6A7)
        : Color(int.parse('0xFF${goal.colorHex.replaceAll('#', '')}'));

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(goal.emoji, style: const TextStyle(fontSize: 28)),
                  if (widget.isCompleted)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.positive.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.positive,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                goal.name,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              AnimatedProgressBar(
                progress: goal.progressPercent,
                height: 5,
                foregroundColor: color,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.formatCurrency(goal.currentAmount)} / ${widget.formatCurrency(goal.targetAmount)}',
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.progressPercent.toStringAsFixed(0)}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: color,
                    ),
                  ),
                  if (goal.daysRemaining >= 0)
                    Text(
                      '${goal.daysRemaining}d',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SavingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.savings_rounded,
            color: Theme.of(context).colorScheme.primary, size: 18),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class AddGoalSheet extends StatefulWidget {
  final SavingsGoal? goal;
  final ValueChanged<SavingsGoal> onSave;

  const AddGoalSheet({super.key, this.goal, required this.onSave});

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _currentController;
  String _emoji = '🎯';
  String _colorHex = '7F5AF0';
  DateTime? _deadline;

  final _emojis = [
    '🎯', '🏠', '🚗', '✈️', '💻', '📱', '🎓', '💍',
    '🏖️', '🎮', '💪', '🎵', '📚', '🛍️', '🎁', '💰',
    '📈', '💹', '🏦',
  ];

  final _colors = [
    '7F5AF0', '2CB67D', 'E53935', 'FF6B6B', 'FFA500',
    '4ECDC4', 'FFD93D', '95E1D3',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _targetController = TextEditingController(
      text: widget.goal?.targetAmount.toString() ?? '',
    );
    _currentController = TextEditingController(
      text: widget.goal?.currentAmount.toString() ?? '0',
    );
    _emoji = widget.goal?.emoji ?? '🎯';
    _colorHex = widget.goal?.colorHex ?? '7F5AF0';
    _deadline = widget.goal?.deadline;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text.trim());
    final current = double.tryParse(_currentController.text.trim()) ?? 0;
    if (name.isEmpty || target == null || target <= 0) return;

    widget.onSave(SavingsGoal(
      id: widget.goal?.id ?? const Uuid().v4(),
      name: name,
      emoji: _emoji,
      targetAmount: target,
      currentAmount: current,
      deadline: _deadline,
      colorHex: _colorHex,
      createdAt: widget.goal?.createdAt ?? DateTime.now(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 8, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      widget.goal != null ? AppLocalizations.of(context)!.editGoal : AppLocalizations.of(context)!.newGoal,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Emoji picker
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _emojis.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 4),
                      itemBuilder: (context, index) {
                        final emoji = _emojis[index];
                        final isSelected = _emoji == emoji;
                        return GestureDetector(
                          onTap: () => setState(() => _emoji = emoji),
                          child: Container(
                            width: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                                  : null,
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.goalName),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _targetController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.targetAmount),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currentController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.currentAmount),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  // Color picker
                  Text('Color', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: _colors.map((hex) {
                      final color = Color(int.parse('0xFF$hex'));
                      final isSelected = _colorHex == hex;
                      return GestureDetector(
                        onTap: () => setState(() => _colorHex = hex),
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2.5)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Deadline
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            _deadline ?? DateTime.now().add(const Duration(days: 90)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) setState(() => _deadline = date);
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _deadline != null
                                ? DateFormat('d MMM yyyy').format(_deadline!)
                                : AppLocalizations.of(context)!.deadline,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _deadline != null
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Icon(Icons.calendar_today_rounded,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.save,
                style:
                    theme.textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddFundsSheet extends StatefulWidget {
  final SavingsGoal goal;
  final ValueChanged<double> onAdd;

  const AddFundsSheet({super.key, required this.goal, required this.onAdd});

  @override
  State<AddFundsSheet> createState() => _AddFundsSheetState();
}

class _AddFundsSheetState extends State<AddFundsSheet> {
  final _amountController = TextEditingController();
  final _presets = [50.0, 100.0, 250.0, 500.0];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _add() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;
    widget.onAdd(amount);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = widget.goal.targetAmount - widget.goal.currentAmount;
    final currency = context.watch<CurrencyProvider>();
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 8, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l.addFunds} - ${widget.goal.name}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${currency.format(remaining, decimalDigits: 0)} ${l.remaining}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: _presets.map((preset) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () {
                        _amountController.text = preset.toStringAsFixed(0);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: theme.colorScheme.outline),
                      ),
                      child: Text(
                        currency.current.symbolAfter
                            ? '${preset.toStringAsFixed(0)}${currency.current.symbol}'
                            : '${currency.current.symbol}${preset.toStringAsFixed(0)}',
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: l.customAmount),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onSubmitted: (_) => _add(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _add,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l.save,
                  style:
                      theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
