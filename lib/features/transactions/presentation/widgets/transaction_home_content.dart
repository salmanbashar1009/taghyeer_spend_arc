import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/sync/sync_bloc.dart';
import '../bloc/sync/sync_event.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import 'arc_meter.dart';
import 'particle_burst.dart';
import 'spending_line_chart.dart';
import 'transaction_list_item.dart';
import 'summary_chip.dart';

class TransactionHomeContent extends StatelessWidget {
  final TransactionLoaded state;
  final double meterAnimationValue;
  final double chartAnimationValue;
  final bool showParticles;
  final Offset? particleOrigin;
  final VoidCallback onParticleComplete;

  const TransactionHomeContent({
    super.key,
    required this.state,
    required this.meterAnimationValue,
    required this.chartAnimationValue,
    required this.showParticles,
    this.particleOrigin,
    required this.onParticleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final dailySpending = state.dailySpending;
    final spendingValues = dailySpending.values.toList();
    final spendingLabels = dailySpending.keys
        .map((d) => '${d.day}/${d.month}')
        .toList();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            context.read<SyncBloc>().add(StartSync());
            context.read<TransactionBloc>().add(LoadTransactions());
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              const SizedBox(height: 16),

              // ── Arc Meter ──
              Center(
                child: ArcMeter(
                  spent: state.totalSpent,
                  budget: state.budget,
                  animationValue: meterAnimationValue,
                ),
              ),

              const SizedBox(height: 24),

              // ── Summary Row ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    SummaryChip(
                      label: 'Spent',
                      value: '\$${state.totalSpent.toStringAsFixed(0)}',
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    SummaryChip(
                      label: 'Income',
                      value: '\$${state.totalIncome.toStringAsFixed(0)}',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Line Chart ──
              if (spendingValues.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          'Last 7 Days',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SpendingLineChart(
                        dataPoints: spendingValues,
                        labels: spendingLabels,
                        animationValue: chartAnimationValue,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // ── Transaction List ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Transactions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),

              ...state.transactions.map((tx) {
                return TransactionListItem(
                  transaction: tx,
                  onDelete: () {
                    context.read<TransactionBloc>().add(
                          DeleteTransactionEvent(tx.id),
                        );
                  },
                );
              }),

              if (state.transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: Text('No transactions yet. Tap + to add one!'),
                  ),
                ),
            ],
          ),
        ),
        if (showParticles && particleOrigin != null)
          Positioned.fill(
            child: ParticleBurst(
              origin: particleOrigin!,
              onComplete: onParticleComplete,
            ),
          ),
      ],
    );
  }
}
