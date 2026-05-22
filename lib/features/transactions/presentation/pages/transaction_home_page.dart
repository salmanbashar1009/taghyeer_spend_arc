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
import '../widgets/arc_meter.dart';
import '../widgets/spending_line_chart.dart';
import '../widgets/transaction_list_item.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
     with TickerProviderStateMixin {

  late final TransactionBloc _transactionBloc;
  late final SyncBloc _syncBloc;

  late final AnimationController _meterController;
  late final AnimationController _chartController;

  @override
  void initState() {
    super.initState();

    // Create ONCE — same instance used throughout this page's lifecycle
    _transactionBloc = sl<TransactionBloc>();
    _syncBloc = sl<SyncBloc>();

    // Wire inter-bloc communication
    _transactionBloc.listenToSyncBloc(_syncBloc.stream);

    // Kick off initial data load + sync
    _transactionBloc.add(LoadTransactions());
    _syncBloc.add(StartSync());

    // Animation controllers for chart/meter entrance
    _meterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    // FIX: Close blocs since we own their lifecycle
    // (BlocProvider.value does NOT auto-close)
    _transactionBloc.close();
    _syncBloc.close();
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
        BlocProvider.value(value: _transactionBloc),
        BlocProvider.value(value: _syncBloc),
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
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () => _syncBloc.add(StartSync()),
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
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is TransactionLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TransactionError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          _transactionBloc.add(LoadTransactions()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is TransactionLoaded) {
              return _buildContent(context, state);
            }
            return const Center(child: Text('Welcome to SpendArc'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTransactionSheet,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  /// ── FIX: Static header + scrollable list ──
  /// Arc meter and chart are FIXED. Only the transaction list scrolls.
  Widget _buildContent(BuildContext context, TransactionLoaded state) {
    final dailySpending = state.dailySpending;
    final spendingValues = dailySpending.values.toList();
    final spendingLabels = dailySpending.keys
        .map((d) => '${d.day}/${d.month}')
        .toList();

    return Column(
      children: [
        // ═══════════════════════════════════════════
        // STATIC HEADER — does NOT scroll
        // ═══════════════════════════════════════════
        ArcMeter(
          spent: state.totalSpent,
          budget: state.totalIncome,
          animationValue: Curves.easeOutCubic.transform(
            _meterController.value,
          ),
        ),

        // Summary chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              _SummaryChip(
                label: 'Spent',
                value: '\$${state.totalSpent.toStringAsFixed(0)}',
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                label: 'Income',
                value: '\$${state.totalIncome.toStringAsFixed(0)}',
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),

        // Line chart — also static
        if (spendingValues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    'Last 7 Days',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                SpendingLineChart(
                  dataPoints: spendingValues,
                  labels: spendingLabels,
                  animationValue:
                  Curves.easeOut.transform(_chartController.value),
                ),
              ],
            ),
          ),

        // Divider between static and scrollable
        const Divider(height: 1),

        // ═══════════════════════════════════════════
        // SCROLLABLE LIST — only this part scrolls
        // ═══════════════════════════════════════════
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _syncBloc.add(StartSync());
              _transactionBloc.add(LoadTransactions());
            },
            child: state.transactions.isEmpty
                ? ListView(
              children: const [
                SizedBox(height: 80),
                Center(
                  child: Text(
                    'No transactions yet.\nTap + to add one!',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
                : ListView.builder(
              padding: const EdgeInsets.only(
                  top: 8, bottom: 80), // bottom padding for FAB
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final tx = state.transactions[index];
                return TransactionListItem(
                  transaction: tx,
                  onDelete: () {
                    // FIX: Use stored bloc reference, not context.read
                    _transactionBloc.add(
                      DeleteTransactionEvent(tx.id),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// FIX: Use _transactionBloc directly instead of context.read
  /// The bottom sheet is rendered in the root navigator overlay,
  /// which is OUTSIDE the BlocProvider tree. context.read would fail.
  void _showAddTransactionSheet() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var selectedType = TransactionType.expense;
    var selectedCategory = 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
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
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'General', 'Food', 'Transport', 'Shopping',
                      'Bills', 'Entertainment', 'Health',
                      'Salary', 'Freelance', 'Investment',
                    ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) =>
                        setSheetState(() => selectedCategory = v ?? 'General'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        final amount = double.tryParse(amountCtrl.text) ?? 0;
                        if (title.isEmpty || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in all fields')),
                          );
                          return;
                        }

                        final tx = Transaction(
                          id: const Uuid().v4(),
                          title: title,
                          amount: amount,
                          type: selectedType,
                          category: selectedCategory,
                          date: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        // FIX: Use stored bloc reference directly
                        // NOT context.read — the sheet is outside BlocProvider
                        _transactionBloc.add(AddTransactionEvent(tx));
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Add Transaction'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}