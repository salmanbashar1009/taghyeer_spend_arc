import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/transactions/presentation/bloc/transaction_bloc.dart';
import '../../features/transactions/presentation/bloc/transaction_state.dart';
import '../../features/transactions/presentation/widgets/arc_meter.dart';
import '../../features/transactions/presentation/widgets/spending_line_chart.dart';
import '../widgets/summary_card.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with TickerProviderStateMixin {
  late final AnimationController _meterController;
  late final AnimationController _chartController;
  late final AnimationController _shaderController;

  ui.FragmentProgram? _glowProgram;

  @override
  void initState() {
    super.initState();
    _meterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _shaderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) return const Center(child: CircularProgressIndicator());
          if (state is TransactionLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _meterController,
                    builder: (context, _) => Center(
                      child: ArcMeter(
                        spent: state.totalSpent,
                        budget: state.totalIncome,
                        animationValue: Curves.easeOutBack.transform(_meterController.value),
                        glowShader: _glowProgram?.fragmentShader(),
                        shaderTime: _shaderController.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SummaryCard(
                    totalIncome: state.totalIncome,
                    totalSpent: state.totalSpent,
                  ),
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 16),
                      child: Text(
                        'Spending Trends',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _chartController,
                    builder: (context, _) => SpendingLineChart(
                      dataPoints: state.dailySpending.values.toList(),
                      labels: state.dailySpending.keys.map((d) => '${d.day}/${d.month}').toList(),
                      animationValue: Curves.easeInOutCubic.transform(_chartController.value),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
