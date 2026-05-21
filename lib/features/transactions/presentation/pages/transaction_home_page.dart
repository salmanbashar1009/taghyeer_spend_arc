import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/sync/sync_bloc.dart';
import '../bloc/sync/sync_event.dart';
import '../bloc/sync/sync_state.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/transaction_home_content.dart';

class TransactionHomePage extends StatefulWidget {
  const TransactionHomePage({super.key});

  @override
  State<TransactionHomePage> createState() => _TransactionHomePageState();
}

class _TransactionHomePageState extends State<TransactionHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _meterController;
  late final AnimationController _chartController;

  // Track which transaction was just deleted for particle effect
  Offset? _particleOrigin;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _meterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final syncBloc = sl<SyncBloc>();
    final transactionBloc = sl<TransactionBloc>();
    transactionBloc.listenToSyncBloc(syncBloc.stream);

    // Initial data load
    transactionBloc.add(LoadTransactions());

    // Trigger initial sync
    syncBloc.add(StartSync());
  }

  @override
  void dispose() {
    _meterController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  void _animateCharts() {
    _meterController.forward(from: 0);
    _chartController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<TransactionBloc>()),
        BlocProvider.value(value: sl<SyncBloc>()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SpendArc'),
          actions: [
            BlocBuilder<SyncBloc, SyncState>(
              builder: (context, state) {
                if (state is SyncInProgress) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () {
                    context.read<SyncBloc>().add(StartSync());
                  },
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionLoaded) {
              _animateCharts();
            }
            if (state is TransactionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is TransactionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TransactionError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            if (state is TransactionLoaded) {
              return AnimatedBuilder(
                animation: Listenable.merge([_meterController, _chartController]),
                builder: (context, _) {
                  return TransactionHomeContent(
                    state: state,
                    meterAnimationValue: Curves.easeOutCubic.transform(
                      _meterController.value,
                    ),
                    chartAnimationValue: Curves.easeOut.transform(
                      _chartController.value,
                    ),
                    showParticles: _showParticles,
                    particleOrigin: _particleOrigin,
                    onParticleComplete: () {
                      setState(() {
                        _showParticles = false;
                        _particleOrigin = null;
                      });
                    },
                  );
                },
              );
            }

            return const Center(child: Text('Welcome to SpendArc'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTransactionSheet(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var selectedType = TransactionType.expense;
    var selectedCategory = 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add Transaction',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (v) =>
                      setSheetState(() => selectedType = v.first),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text) ?? 0;
                    if (titleCtrl.text.isEmpty || amount <= 0) return;

                    final tx = TransactionEntity(
                      id: const Uuid().v4(),
                      title: titleCtrl.text,
                      amount: amount,
                      type: selectedType,
                      category: selectedCategory,
                      date: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    // Use the bloc from the outer context (sheet's parent)
                    sheetContext.read<TransactionBloc>().add(
                          AddTransactionEvent(tx),
                        );
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
