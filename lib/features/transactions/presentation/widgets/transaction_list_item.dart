import 'package:flutter/material.dart';
import 'package:taghyeer_spend_arc/features/transactions/domain/entities/transaction_entity.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/widgets/spring_swipe_delete.dart';


class TransactionListItem extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SpringSwipeDelete(
      onDeleted: onDelete,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: transaction.isExpense
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.primaryContainer,
            child: Icon(
              transaction.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
              color: transaction.isExpense
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          title: Text(transaction.title),
          subtitle: Text(transaction.category),
          trailing: Text(
            '${transaction.isExpense ? "-" : "+"}\$${transaction.amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: transaction.isExpense
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}