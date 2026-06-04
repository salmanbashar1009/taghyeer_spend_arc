import 'package:flutter/material.dart';
import 'summary_chip.dart';

class SummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalSpent;
  final double? totalRemain;

  const SummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalSpent,
     this.totalRemain
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
          SummaryChip(
            label: 'Spent',
            value: '\$${totalSpent.toStringAsFixed(0)}',
            color: Theme.of(context).colorScheme.error,
          ),
          if (totalRemain != null) SummaryChip(
            label: 'Remain',
            value: '\$${totalRemain?.toStringAsFixed(0)}',
            color: Colors.deepOrangeAccent,
          ),
        ],
      ),
    );
  }
}
