import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_state.dart';
import '../widgets/arc_meter.dart';
import '../widgets/spending_line_chart.dart';
import '../widgets/transaction_list_item.dart';
import '../bloc/transaction_event.dart';
import '../widgets/summary_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late final AnimationController _meterController;
  late final AnimationController _chartController;
  late final AnimationController _shaderController;

  ui.FragmentProgram? _glowProgram;

  @override
  void initState() {
    super.initState();
    _meterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _chartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _shaderController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _loadShaders();
  }

  Future<void> _loadShaders() async {
    try {
      _glowProgram = await ui.FragmentProgram.fromAsset('shaders/spending_glow.frag');
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading shaders: $e');
    }
  }

  @override
  void dispose() {
    _meterController.dispose();
    _chartController.dispose();
    _shaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) return const Center(child: CircularProgressIndicator());
        if (state is TransactionLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionBloc>().add(LoadTransactions());
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: const Text('SpendArc'),
                  surfaceTintColor: Colors.transparent,
                  backgroundColor: Colors.transparent,
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _meterController,
                        builder: (context, _) => ArcMeter(
                          spent: state.totalSpent,
                          budget: state.totalIncome,
                          animationValue: Curves.easeOutBack.transform(_meterController.value),
                          glowShader: _glowProgram?.fragmentShader(),
                          shaderTime: _shaderController.value,
                        ),
                      ),
                      SummaryCard(
                        totalIncome: state.totalIncome,
                        totalSpent: state.totalSpent,
                        totalRemain: state.totalIncome - state.totalSpent,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnimatedBuilder(
                          animation: _chartController,
                          builder: (context, _) => SpendingLineChart(
                            dataPoints: state.dailySpending.values.toList(),
                            labels: state.dailySpending.keys.map((d) => '${d.day}/${d.month}').toList(),
                            animationValue: Curves.easeInOutCubic.transform(_chartController.value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                    ],
                  ),
                ),
                if (state.transactions.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('No transactions yet.')),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = state.transactions[index];
                        return TransactionListItem(
                          key: ValueKey(tx.id),
                          transaction: tx,
                          onDelete: () => context.read<TransactionBloc>().add(DeleteTransactionEvent(tx.id)),
                        );
                      },
                      childCount: state.transactions.length,
                    ),
                  ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
