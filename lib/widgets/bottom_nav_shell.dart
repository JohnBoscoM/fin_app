import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/goals_provider.dart';
import '../screens/expenses_screen.dart';
import '../screens/goals_screen.dart';
import '../themes/app_themes.dart';
import 'glass_container.dart';

class BottomNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    if (index == 2) {
      _showAddSheet(context);
      return;
    }
    final branchIndex = index > 2 ? index - 1 : index;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  int get _selectedIndex {
    final current = navigationShell.currentIndex;
    return current >= 2 ? current + 1 : current;
  }

  void _showAddSheet(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AddOption(
                  icon: CupertinoIcons.arrow_down,
                  iconColor: AppColors.negative,
                  label: l.addExpense,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showExpenseSheet(context);
                  },
                ),
                const SizedBox(height: 8),
                _AddOption(
                  icon: CupertinoIcons.arrow_up,
                  iconColor: AppColors.positive,
                  label: l.addIncome,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showIncomeSheet(context);
                  },
                ),
                const SizedBox(height: 8),
                _AddOption(
                  icon: CupertinoIcons.money_dollar_circle_fill,
                  iconColor: Theme.of(context).colorScheme.primary,
                  label: l.addSavings,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showGoalSheet(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddExpenseSheet(
        onSave: (expense) {
          context.read<ExpenseProvider>().addExpense(expense);
        },
      ),
    );
  }

  void _showIncomeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddIncomeSheet(
        onSave: (income) {
          context.read<IncomeProvider>().addIncome(income);
        },
      ),
    );
  }

  void _showGoalSheet(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final goals = context.read<GoalsProvider>().goals;
    final activeGoals = goals.where((g) => !g.isCompleted).toList();

    if (activeGoals.isEmpty) {
      // No goals exist – open the create-goal sheet directly
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => AddGoalSheet(
          onSave: (goal) {
            context.read<GoalsProvider>().addGoal(goal);
          },
        ),
      );
      return;
    }

    // Show a picker: list of active goals + option to create new
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
                            leading: Text(goal.emoji, style: const TextStyle(fontSize: 28)),
                            title: Text(goal.name),
                            subtitle: Text('$pct%'),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => AddFundsSheet(
                                  goal: goal,
                                  onAdd: (amount) {
                                    context
                                        .read<GoalsProvider>()
                                        .addFundsToGoal(goal.id, amount);
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
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: Icon(CupertinoIcons.add_circled,
                      color: Theme.of(ctx).colorScheme.primary),
                  title: Text(l.addGoal,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddGoalSheet(
                        onSave: (goal) {
                          context.read<GoalsProvider>().addGoal(goal);
                        },
                      ),
                    );
                  },
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
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SafeArea(
          child: GlassContainer(
            borderRadius: 28,
            blur: 30,
            opacity: 0.1,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: CupertinoIcons.house_fill,
                    label: l.home,
                    isSelected: _selectedIndex == 0,
                    onTap: () => _onTap(context, 0),
                  ),
                  _NavItem(
                    icon: CupertinoIcons.doc_text_fill,
                    label: l.records,
                    isSelected: _selectedIndex == 1,
                    onTap: () => _onTap(context, 1),
                  ),
                  _FabItem(onTap: () => _onTap(context, 2)),
                  _NavItem(
                    icon: CupertinoIcons.flag_fill,
                    label: l.goals,
                    isSelected: _selectedIndex == 3,
                    onTap: () => _onTap(context, 3),
                  ),
                  _NavItem(
                    icon: CupertinoIcons.ellipsis,
                    label: l.menu,
                    isSelected: _selectedIndex == 4,
                    onTap: () => _onTap(context, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FabItem extends StatelessWidget {
  final VoidCallback onTap;

  const _FabItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _AddOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
