import 'package:flutter/material.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/widgets/spring_swipe_delete.dart';

import '../../domain/entities/transaction_entity.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
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
      key: key!,
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
          subtitle: Text(
            '${transaction.category} • ${_formatDate(transaction.date)}',
          ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

// lib/features/transactions/presentation/widgets/transaction_list_item.dart

// class TransactionListItem extends StatelessWidget {
//   final Transaction transaction;
//   final VoidCallback onDelete;
//
//   const TransactionListItem({
//     required Key key, // Ensure Key is required and passed
//     required this.transaction,
//     required this.onDelete,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Dismissible(
//       key: key!, // Use the same key as the widget
//       direction: DismissDirection.endToStart,
//       background: Container(
//         color: Colors.red,
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 20),
//         child: const Icon(Icons.delete, color: Colors.white),
//       ),
//       onDismissed: (direction) {
//         onDelete(); // Trigger the Bloc event
//       },
//       child: ListTile(
//         title: Text(transaction.title),
//         subtitle: Text(transaction.date.toString()),
//         trailing: Text('${transaction.amount}'),
//       ),
//     );
//   }
// }