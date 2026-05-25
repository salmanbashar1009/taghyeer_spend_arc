import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/summary_card.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
      ),
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        buildWhen: (previous, current) => current is! TransactionError,
        builder: (context, state) {
          if (state is TransactionLoading && state is! TransactionLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TransactionLoaded) {
            return Column(
              children: [
                SummaryCard(
                  totalIncome: state.totalIncome,
                  totalSpent: state.totalSpent,
                ),
                const Divider(height: 1),
                Expanded(
                  child: state.transactions.isEmpty
                      ? const Center(child: Text('No transactions yet.'))
                      : ListView.builder(
                          itemCount: state.transactions.length,
                          itemBuilder: (context, index) {
                            final tx = state.transactions[index];
                            return TransactionListItem(
                              key: ValueKey(tx.id),
                              transaction: tx,
                              onDelete: () => context
                                  .read<TransactionBloc>()
                                  .add(DeleteTransactionEvent(tx.id)),
                            );
                          },
                        ),
                ),
              ],
            );
          }
          if (state is TransactionInitial) {
             return const Center(child: CircularProgressIndicator());
          }
          return const Center(child: Text('Something went wrong.'));
        },
      ),
    );
  }
}
