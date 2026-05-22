import 'package:flutter/material.dart';
import 'summary_chip.dart';

class SummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalSpent;

  const SummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SummaryChip(
            label: 'Income',
            value: '\$${totalIncome.toStringAsFixed(0)}',
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          SummaryChip(
            label: 'Spent',
            value: '\$${totalSpent.toStringAsFixed(0)}',
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}
