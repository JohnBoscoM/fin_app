import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/category_provider.dart';
import '../themes/app_themes.dart';
import '../widgets/month_selector.dart';
import '../widgets/category_badge.dart';
import '../widgets/empty_state.dart';
import '../screens/goals_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _selectedCategory = '';

  void _showAddExpenseSheet() {
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

  void _showAddIncomeSheet() {
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

  void _showEditExpenseSheet(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddExpenseSheet(
        expense: expense,
        onSave: (updated) {
          context.read<ExpenseProvider>().updateExpense(updated);
        },
      ),
    );
  }

  void _showAddSavingsSheet() {
    final l = AppLocalizations.of(context)!;
    final goals = context.read<GoalsProvider>().goals;
    final activeGoals = goals.where((g) => !g.isCompleted).toList();

    if (activeGoals.isEmpty) {
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
                      children: activeGoals.map((goal) {
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
                }).toList(),
                    ),
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: Icon(Icons.add_circle_outline_rounded,
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
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final currency = context.watch<CurrencyProvider>();
    String fmt(double v) => currency.format(v);

    final expenseProvider = context.watch<ExpenseProvider>();
    final incomeProvider = context.watch<IncomeProvider>();

    final monthExpenses = _selectedCategory.isEmpty
        ? expenseProvider.getExpensesForMonth(_selectedMonth)
        : expenseProvider.getExpensesByCategoryForMonth(
            _selectedCategory, _selectedMonth);
    final monthIncomes = incomeProvider.getIncomesForMonth(_selectedMonth);
    final totalExpenses =
        expenseProvider.getTotalExpensesForMonth(_selectedMonth);
    final totalIncome = incomeProvider.getTotalIncomeForMonth(_selectedMonth);

    // Merge and sort by date
    final List<_TransactionItem> transactions = [
      ...monthExpenses.map((e) => _TransactionItem(
            id: e.id,
            name: e.name,
            amount: -e.amount,
            category: e.category,
            date: e.createdAt,
            isExpense: true,
            isRecurring: e.isRecurring,
          )),
      ...monthIncomes.map((i) => _TransactionItem(
            id: i.id,
            name: i.source,
            amount: i.amount,
            category: l.income,
            date: i.createdAt,
            isExpense: false,
            isRecurring: i.isRecurring,
          )),
    ]..sort((a, b) {
        // Primary: group by date (newest day first)
        final dateCmp = b.date.compareTo(a.date);
        final sameDay = a.date.year == b.date.year &&
            a.date.month == b.date.month &&
            a.date.day == b.date.day;
        if (!sameDay) return dateCmp;
        // Within same day: income=0, savings=1, expense=2
        int priorityOf(_TransactionItem t) {
          if (!t.isExpense) return 0; // income
          if (t.category == 'savings') return 1; // savings
          return 2; // expense
        }
        final cmp = priorityOf(a).compareTo(priorityOf(b));
        if (cmp != 0) return cmp;
        return b.date.compareTo(a.date); // newest first within group
      });

    // Group by date
    final grouped = <String, List<_TransactionItem>>{};
    for (final t in transactions) {
      final key = _getDateGroupKey(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    final catProvider = context.watch<CategoryProvider>();
    final allCatIds = catProvider.categories.map((c) => c.id).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l.records,
                      style: theme.textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      _MiniActionButton(
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.negative,
                        onTap: _showAddExpenseSheet,
                      ),
                      const SizedBox(width: 8),
                      _MiniActionButton(
                        icon: Icons.arrow_upward_rounded,
                        color: AppColors.positive,
                        onTap: _showAddIncomeSheet,
                      ),
                      const SizedBox(width: 8),
                      _MiniActionButton(
                        icon: Icons.savings_rounded,
                        color: theme.colorScheme.primary,
                        onTap: _showAddSavingsSheet,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            MonthSelector(
              selectedMonth: _selectedMonth,
              onMonthChanged: (m) => setState(() => _selectedMonth = m),
            ),
            const SizedBox(height: 12),

            // Summary row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _MiniStat(
                    label: l.income,
                    amount: fmt(totalIncome),
                    color: AppColors.positive,
                  ),
                  const SizedBox(width: 12),
                  _MiniStat(
                    label: l.expenses,
                    amount: fmt(totalExpenses),
                    color: AppColors.negative,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Category filter
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: allCatIds.length + 1, // +1 for "All"
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return CategoryBadge(
                      categoryId: '',
                      isSelected: _selectedCategory.isEmpty,
                      onTap: () => setState(() => _selectedCategory = ''),
                    );
                  }
                  final catId = allCatIds[index - 1];
                  return CategoryBadge(
                    categoryId: catId,
                    isSelected: _selectedCategory == catId,
                    onTap: () => setState(() => _selectedCategory = catId),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Transaction list
            Expanded(
              child: transactions.isEmpty
                  ? EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: l.noTransactions,
                      subtitle: l.addExpenseOrIncome,
                      buttonText: l.addExpense,
                      onButtonPressed: _showAddExpenseSheet,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final groupKey = grouped.keys.elementAt(index);
                        final items = grouped[groupKey]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 12, bottom: 8),
                              child: Text(
                                groupKey,
                                style: theme.textTheme.labelMedium,
                              ),
                            ),
                            ...items.map((t) => _TransactionRow(
                                  item: t,
                                  formatCurrency: fmt,
                                  onDismissed: () {
                                    if (t.isExpense) {
                                      context
                                          .read<ExpenseProvider>()
                                          .deleteExpense(t.id);
                                    } else {
                                      context
                                          .read<IncomeProvider>()
                                          .deleteIncome(t.id);
                                    }
                                  },
                                  onTap: t.isExpense
                                      ? () {
                                          final expense = monthExpenses
                                              .firstWhere(
                                                  (e) => e.id == t.id);
                                          _showEditExpenseSheet(expense);
                                        }
                                      : null,
                                )),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateGroupKey(DateTime date) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return l.today;
    if (dateOnly == today.subtract(const Duration(days: 1))) return l.yesterday;
    if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return l.thisWeek;
    }
    return DateFormat('d MMM yyyy').format(date);
  }
}

class _TransactionItem {
  final String id;
  final String name;
  final double amount;
  final String category;
  final DateTime date;
  final bool isExpense;
  final bool isRecurring;

  _TransactionItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    required this.isExpense,
    this.isRecurring = false,
  });
}

class _TransactionRow extends StatelessWidget {
  final _TransactionItem item;
  final String Function(double) formatCurrency;
  final VoidCallback onDismissed;
  final VoidCallback? onTap;

  const _TransactionRow({
    required this.item,
    required this.formatCurrency,
    required this.onDismissed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catProvider = context.watch<CategoryProvider>();
    final l = AppLocalizations.of(context)!;
    final cat = item.isExpense ? catProvider.getCategoryById(item.category) : null;
    final color = item.isExpense
        ? (cat?.color ?? AppColors.other)
        : AppColors.positive;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.negative.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.negative),
      ),
      onDismissed: (_) => onDismissed(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.isExpense
                      ? (cat?.icon ?? Icons.receipt_rounded)
                      : Icons.arrow_upward_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.isExpense
                                ? catProvider.getDisplayNameById(item.category, l)
                                : item.category,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isRecurring) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.repeat_rounded,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.isExpense
                        ? '-${formatCurrency(item.amount.abs())}'
                        : '+${formatCurrency(item.amount)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: item.isExpense
                          ? AppColors.negative
                          : AppColors.positive,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('d MMM').format(item.date),
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outline,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// Add Expense Bottom Sheet
class AddExpenseSheet extends StatefulWidget {
  final Expense? expense;
  final ValueChanged<Expense> onSave;

  const AddExpenseSheet({super.key, this.expense, required this.onSave});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  String _category = 'food';
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense?.name ?? '');
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );
    _category = widget.expense?.category ?? 'food';
    _isRecurring = widget.expense?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (name.isEmpty || amount == null || amount <= 0) return;

    final expense = Expense(
      id: widget.expense?.id ?? const Uuid().v4(),
      name: name,
      amount: amount,
      category: _category,
      isRecurring: _isRecurring,
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
    );
    widget.onSave(expense);
    Navigator.pop(context);
  }

  void _showAddCategorySheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddCategorySheet(),
    );
    if (result != null && mounted) {
      setState(() => _category = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final catProvider = context.watch<CategoryProvider>();
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
                      widget.expense != null ? l.editExpense : l.addExpense,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: l.expenseName),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(labelText: l.expenseAmount),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  Text(l.category, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...catProvider.categories.map((cat) {
                        return CategoryBadge(
                          categoryId: cat.id,
                          isSelected: _category == cat.id,
                          onTap: () => setState(() => _category = cat.id),
                        );
                      }),
                      // Add category button
                      GestureDetector(
                        onTap: _showAddCategorySheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.colorScheme.outline),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                l.addCategory,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l.isRecurring, style: theme.textTheme.bodyLarge),
                      Switch(
                        value: _isRecurring,
                        onChanged: (v) => setState(() => _isRecurring = v),
                      ),
                    ],
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
                l.save,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Add Income Bottom Sheet
class AddIncomeSheet extends StatefulWidget {
  final ValueChanged<Income> onSave;

  const AddIncomeSheet({super.key, required this.onSave});

  @override
  State<AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<AddIncomeSheet> {
  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isRecurring = false;

  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final source = _sourceController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (source.isEmpty || amount == null || amount <= 0) return;

    widget.onSave(Income(
      id: const Uuid().v4(),
      source: source,
      amount: amount,
      isRecurring: _isRecurring,
      createdAt: DateTime.now(),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.addIncome, style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _sourceController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.incomeName),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.incomeAmount),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.isRecurring, style: theme.textTheme.bodyLarge),
                Switch(
                  value: _isRecurring,
                  onChanged: (v) => setState(() => _isRecurring = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.positive,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.save,
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

// Add Category Bottom Sheet
class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({super.key});

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _nameController = TextEditingController();
  int _selectedColorValue = 0xFF7F5AF0;
  int _selectedIconCodePoint = Icons.label_rounded.codePoint;

  static final _colorOptions = [
    0xFF7F5AF0, 0xFFE53935, 0xFFFF6B6B, 0xFFFFA500, 0xFFFFD93D,
    0xFF2CB67D, 0xFF4ECDC4, 0xFF95E1D3, 0xFF03A9F4, 0xFF3F51B5,
    0xFF9C27B0, 0xFFE91E63, 0xFF607D8B, 0xFF795548, 0xFF00BCD4,
    0xFFFFC107,
  ];

  static final _iconOptions = [
    Icons.label_rounded,
    Icons.home_rounded,
    Icons.restaurant_rounded,
    Icons.directions_car_rounded,
    Icons.subscriptions_rounded,
    Icons.favorite_rounded,
    Icons.movie_rounded,
    Icons.shopping_bag_rounded,
    Icons.flight_rounded,
    Icons.school_rounded,
    Icons.sports_esports_rounded,
    Icons.music_note_rounded,
    Icons.play_circle_rounded,
    Icons.fitness_center_rounded,
    Icons.coffee_rounded,
    Icons.local_bar_rounded,
    Icons.pets_rounded,
    Icons.child_care_rounded,
    Icons.build_rounded,
    Icons.local_gas_station_rounded,
    Icons.local_parking_rounded,
    Icons.local_pharmacy_rounded,
    Icons.security_rounded,
    Icons.bolt_rounded,
    Icons.phone_android_rounded,
    Icons.wifi_rounded,
    Icons.cleaning_services_rounded,
    Icons.checkroom_rounded,
    Icons.receipt_rounded,
    Icons.card_giftcard_rounded,
    Icons.local_florist_rounded,
    Icons.brush_rounded,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final id = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final category = ExpenseCategory(
      id: '${id}_${DateTime.now().millisecondsSinceEpoch}',
      nameKey: name,
      colorValue: _selectedColorValue,
      iconCodePoint: _selectedIconCodePoint,
    );
    context.read<CategoryProvider>().addCategory(category);
    Navigator.pop(context, category.id);
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
              child: Text(l.addCategory, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l.categoryName),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text(l.categoryColor, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((cv) {
                final isSelected = _selectedColorValue == cv;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorValue = cv),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(cv),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(l.categoryIcon, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: GridView.count(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: _iconOptions.map((ic) {
                  final isSelected = _selectedIconCodePoint == ic.codePoint;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconCodePoint = ic.codePoint),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColorValue).withValues(alpha: 0.25)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Color(_selectedColorValue), width: 2)
                            : Border.all(color: theme.colorScheme.outline, width: 0.5),
                      ),
                      child: Icon(
                        ic,
                        size: 18,
                        color: isSelected ? Color(_selectedColorValue) : theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
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
                  l.save,
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
