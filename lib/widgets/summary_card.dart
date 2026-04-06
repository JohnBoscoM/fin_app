import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatefulWidget {
  final String label;
  final double amount;
  final String? subtitle;
  final Color? amountColor;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final String locale;

  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    this.subtitle,
    this.amountColor,
    this.trailingIcon,
    this.onTrailingTap,
    this.locale = 'en',
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _countAnimation = Tween<double>(begin: 0, end: widget.amount).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _countAnimation = Tween<double>(
        begin: _countAnimation.value,
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
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      locale: widget.locale,
      symbol: '\$',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(20),
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
              Text(
                widget.label,
                style: theme.textTheme.bodyMedium,
              ),
              if (widget.trailingIcon != null)
                GestureDetector(
                  onTap: widget.onTrailingTap,
                  child: Icon(
                    widget.trailingIcon,
                    size: 22,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, _) {
              return Text(
                formatter.format(_countAnimation.value),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: widget.amountColor ??
                      theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
