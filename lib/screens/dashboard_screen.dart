import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';
import '../themes/app_themes.dart';
import '../widgets/month_selector.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/donut_chart.dart';
import '../widgets/app_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final currency = context.watch<CurrencyProvider>();
    String fmt(double v) => currency.format(v);

    final expenseProvider = context.watch<ExpenseProvider>();
    final incomeProvider = context.watch<IncomeProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final goalsProvider = context.watch<GoalsProvider>();

    final totalIncome = incomeProvider.getTotalIncomeForMonth(_selectedMonth);
    final totalExpenses = expenseProvider.getTotalExpensesForMonth(_selectedMonth);
    final balance = totalIncome - totalExpenses;
    final totalBudgeted = budgetProvider.getTotalBudgeted(_selectedMonth);
    final budgetLeft = totalBudgeted - totalExpenses;
    final categoryTotals = expenseProvider.getCategoryTotalsForMonth(_selectedMonth);
    final isMonochrome = context.watch<ThemeProvider>().isMonochrome;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: MonthSelector(
                  selectedMonth: _selectedMonth,
                  onMonthChanged: (m) => setState(() => _selectedMonth = m),
                ),
              ),
            ),

            // Total Balance Card
            SliverToBoxAdapter(
              child: _StaggeredEntry(
                delay: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l.totalBalance,
                              style: theme.textTheme.bodyMedium,
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _AnimatedAmount(
                          amount: balance,
                          style: theme.textTheme.headlineLarge!,
                          formatCurrency: fmt,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Budget Section
            SliverToBoxAdapter(
              child: _StaggeredEntry(
                delay: 100,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l.budget,
                              style: theme.textTheme.titleLarge,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                l.allBudgets,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _AnimatedAmount(
                          amount: budgetLeft.clamp(0, double.infinity),
                          style: theme.textTheme.headlineMedium!,
                          formatCurrency: fmt,
                          suffix: ' ${l.left}',
                          suffixStyle: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '-${fmt(totalExpenses)} ${l.spentThisMonth}',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        AnimatedProgressBar(
                          progress: totalBudgeted > 0
                              ? (totalExpenses / totalBudgeted * 100)
                              : 0,
                          height: 6,
                        ),
                        const SizedBox(height: 16),
                        // Category spending chips
                        if (categoryTotals.isNotEmpty)
                          SizedBox(
                            height: 54,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: categoryTotals.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final entry =
                                    categoryTotals.entries.elementAt(index);
                                final catProvider = context.watch<CategoryProvider>();
                                final cat = catProvider.getCategoryById(entry.key);
                                final color = isMonochrome
                                    ? (entry.key == 'savings' ? const Color(0xFFA5D6A7) : const Color(0xFF9E9E9E))
                                    : (entry.key == 'savings' ? AppColors.positive : (cat?.color ?? AppColors.other));
                                return _CategorySpendChip(
                                  category: catProvider.getDisplayNameById(entry.key, l),
                                  amount: fmt(entry.value),
                                  spentLabel: l.spent,
                                  color: color,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Categories Donut Chart
            SliverToBoxAdapter(
              child: _StaggeredEntry(
                delay: 200,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l.categories,
                              style: theme.textTheme.titleLarge,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                l.statistics,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: DonutChart(
                            size: 180,
                            strokeWidth: 14,
                            segments: categoryTotals.entries.map((entry) {
                              final catProvider = context.read<CategoryProvider>();
                              final cat = catProvider.getCategoryById(entry.key);
                              return DonutSegment(
                                label: catProvider.getDisplayNameById(entry.key, l),
                                value: entry.value,
                                color: isMonochrome
                                    ? (entry.key == 'savings' ? const Color(0xFFA5D6A7) : const Color(0xFFEF9A9A))
                                    : (entry.key == 'savings' ? AppColors.positive : (cat?.color ?? AppColors.other)),
                              );
                            }).toList(),
                            center: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l.expense,
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  fmt(totalExpenses),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Category legend
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: categoryTotals.entries.map((entry) {
                            final catProvider = context.read<CategoryProvider>();
                            final cat = catProvider.getCategoryById(entry.key);
                            final color = isMonochrome
                                ? (entry.key == 'savings' ? const Color(0xFFA5D6A7) : const Color(0xFF9E9E9E))
                                : (entry.key == 'savings' ? AppColors.positive : (cat?.color ?? AppColors.other));
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
                                  catProvider.getDisplayNameById(entry.key, l),
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
            ),

            // Goals snapshot
            if (goalsProvider.goals.isNotEmpty)
              SliverToBoxAdapter(
                child: _StaggeredEntry(
                  delay: 300,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.savingsGoals,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          ...goalsProvider.goals.take(3).map((goal) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Text(
                                    goal.emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.name,
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        AnimatedProgressBar(
                                          progress: goal.progressPercent,
                                          height: 4,
                                          foregroundColor: isMonochrome ? const Color(0xFFA5D6A7) : theme.colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${goal.progressPercent.toStringAsFixed(0)}%',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: isMonochrome ? const Color(0xFFA5D6A7) : theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Top Expenses
            SliverToBoxAdapter(
              child: _StaggeredEntry(
                delay: 400,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.topExpenses,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (expenseProvider
                            .getTopExpensesForMonth(_selectedMonth)
                            .isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                l.noExpensesThisMonth,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          )
                        else
                          ...expenseProvider
                              .getTopExpensesForMonth(_selectedMonth, limit: 5)
                              .map((expense) {
                            final catProvider = context.read<CategoryProvider>();
                            final cat = catProvider.getCategoryById(expense.category);
                            final color = cat?.color ?? AppColors.other;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      cat?.icon ?? Icons.receipt_rounded,
                                      color: color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense.name,
                                          style: theme.textTheme.bodyLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          catProvider.getDisplayNameById(expense.category, l),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '-${fmt(expense.amount)}',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: AppColors.negative,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredEntry extends StatefulWidget {
  final int delay;
  final Widget child;

  const _StaggeredEntry({required this.delay, required this.child});

  @override
  State<_StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<_StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class _AnimatedAmount extends StatefulWidget {
  final double amount;
  final TextStyle style;
  final String Function(double) formatCurrency;
  final String? suffix;
  final TextStyle? suffixStyle;

  const _AnimatedAmount({
    required this.amount,
    required this.style,
    required this.formatCurrency,
    this.suffix,
    this.suffixStyle,
  });

  @override
  State<_AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<_AnimatedAmount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.amount).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.amount,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            text: TextSpan(
              text: widget.formatCurrency(_animation.value),
              style: widget.style,
              children: widget.suffix != null
                  ? [
                      TextSpan(
                        text: widget.suffix,
                        style: widget.suffixStyle ?? widget.style,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _CategorySpendChip extends StatelessWidget {
  final String category;
  final String amount;
  final Color color;
  final String spentLabel;

  const _CategorySpendChip({
    required this.category,
    required this.amount,
    required this.color,
    required this.spentLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              value: 0.65,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category,
                style: theme.textTheme.labelLarge?.copyWith(fontSize: 12),
              ),
              Text(
                '$amount $spentLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
