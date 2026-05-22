import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/transactions/presentation/bloc/transaction_bloc.dart';
import '../../features/transactions/presentation/bloc/transaction_event.dart';
import '../../features/transactions/presentation/bloc/transaction_state.dart';
import '../../features/transactions/presentation/widgets/arc_meter.dart';
import '../../features/transactions/presentation/widgets/spending_line_chart.dart';
import '../../features/transactions/presentation/widgets/transaction_list_item.dart';

class AdaptiveHomeGrid extends StatelessWidget {
  final TransactionLoaded state;
  final Animation<double> meterAnimation;
  final Animation<double> chartAnimation;
  final bool isSyncing;
  final double shaderTime;
  final ui.FragmentProgram? glowProgram;
  final ui.FragmentProgram? shimmerProgram;

  const AdaptiveHomeGrid({
    super.key,
    required this.state,
    required this.meterAnimation,
    required this.chartAnimation,
    this.isSyncing = false,
    required this.shaderTime,
    this.glowProgram,
    this.shimmerProgram,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    
    return Stack(
      children: [
        isWide ? _buildWideLayout(context) : _buildNarrowLayout(context),
        if (isSyncing && shimmerProgram != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ShimmerPainter(
                  shader: shimmerProgram!.fragmentShader(),
                  time: shaderTime,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAnimatedMeter(),
                const SizedBox(height: 48),
                _buildAnimatedChart(context),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: _buildTransactionList(),
        ),
      ],
    );
  }

  /// Refined Narrow Layout using CustomScrollView for better visibility and scroll behavior
  Widget _buildNarrowLayout(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _buildAnimatedMeter()),
                const SizedBox(height: 32),
                _buildAnimatedChart(context),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 100),
          sliver: state.transactions.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No transactions yet.')),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = state.transactions[index];
                      return TransactionListItem(
                        transaction: tx,
                        onDelete: () => context.read<TransactionBloc>().add(DeleteTransactionEvent(tx.id)),
                      );
                    },
                    childCount: state.transactions.length,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAnimatedMeter() {
    return AnimatedBuilder(
      animation: meterAnimation,
      builder: (context, _) => ArcMeter(
        spent: state.totalSpent,
        budget: state.totalIncome,
        animationValue: Curves.easeOutBack.transform(meterAnimation.value),
        glowShader: glowProgram?.fragmentShader(),
        shaderTime: shaderTime,
      ),
    );
  }

  Widget _buildAnimatedChart(BuildContext context) {
    final dailySpending = state.dailySpending;
    final spendingValues = dailySpending.values.toList();
    final spendingLabels = dailySpending.keys
        .map((d) => '${d.day}/${d.month}')
        .toList();

    return AnimatedBuilder(
      animation: chartAnimation,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Weekly Spending History',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Ensure the chart has a solid background or container to be visible
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SpendingLineChart(
                  dataPoints: spendingValues,
                  labels: spendingLabels,
                  animationValue: Curves.easeInOutCubic.transform(chartAnimation.value),
                  height: 200, // Increased height for better visibility
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionList() {
    if (state.transactions.isEmpty) {
      return const Center(child: Text('No transactions recorded yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: state.transactions.length,
      itemBuilder: (context, index) {
        final tx = state.transactions[index];
        return TransactionListItem(
          transaction: tx,
          onDelete: () => context.read<TransactionBloc>().add(DeleteTransactionEvent(tx.id)),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  _ShimmerPainter({required this.shader, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.time != time;
}
