import 'dart:async';
import 'dart:ui' as ui;
import 'package:connectivity_plus/connectivity_plus.dart';
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
import '../widgets/adaptive_home_grid.dart';
import '../widgets/adaptive_scaffold.dart';

class AdaptiveHomePage extends StatefulWidget {
  const AdaptiveHomePage({super.key});

  @override
  State<AdaptiveHomePage> createState() => _AdaptiveHomePageState();
}

class _AdaptiveHomePageState extends State<AdaptiveHomePage>
    with TickerProviderStateMixin {
  late final TransactionBloc _transactionBloc;
  late final SyncBloc _syncBloc;

  late final AnimationController _meterController;
  late final AnimationController _chartController;
  late final AnimationController _shaderController;
  
  StreamSubscription? _connectivitySubscription;
  bool? _wasConnected;

  ui.FragmentProgram? _glowProgram;
  ui.FragmentProgram? _shimmerProgram;

  @override
  void initState() {
    super.initState();
    _transactionBloc = sl<TransactionBloc>();
    _syncBloc = sl<SyncBloc>();

    _transactionBloc.listenToSyncBloc(_syncBloc.stream);
    _transactionBloc.add(LoadTransactions());
    _syncBloc.add(StartSync());

    _meterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shaderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _setupConnectivityListener();
    _loadShaders();
  }

  Future<void> _loadShaders() async {
    try {
      _glowProgram = await ui.FragmentProgram.fromAsset('shaders/spending_glow.frag');
      _shimmerProgram = await ui.FragmentProgram.fromAsset('shaders/sync_shimmer.frag');
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading shaders: $e');
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = !results.contains(ConnectivityResult.none);
      
      if (_wasConnected != null && _wasConnected != isConnected) {
        final message = isConnected ? "Back Online - Syncing data" : "Offline Mode - Data saved locally";
        final icon = isConnected ? Icons.wifi : Icons.wifi_off;

        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(message),
              ],
            ),
            backgroundColor: isConnected ? Colors.green.shade700 : Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        if (isConnected) {
          _syncBloc.add(ConnectivityRestored());
        }
      }
      _wasConnected = isConnected;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _transactionBloc.close();
    _syncBloc.close();
    _meterController.dispose();
    _chartController.dispose();
    _shaderController.dispose();
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
      child: AdaptiveScaffold(
        title: Align(
            alignment: Alignment.centerLeft,
            child: const Text('SpendArc')),
        actions: [
          BlocBuilder<SyncBloc, SyncState>(
            builder: (context, state) {
              return IconButton(
                icon: state is SyncInProgress 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync),
                onPressed: () => _syncBloc.add(StartSync()),
              );
            },
          ),
        ],
        body: BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionLoaded) {
              _animateCharts();
            }
          },
          builder: (context, state) {
            if (state is TransactionLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TransactionLoaded) {
              return BlocBuilder<SyncBloc, SyncState>(
                builder: (context, syncState) {
                  return AdaptiveHomeGrid(
                    state: state,
                    meterAnimation: _meterController,
                    chartAnimation: _chartController,
                    isSyncing: syncState is SyncInProgress,
                    shaderTime: _shaderController.value,
                    glowProgram: _glowProgram,
                    shimmerProgram: _shimmerProgram,
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTransactionSheet,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddTransactionSheet() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var selectedType = TransactionType.expense;
    var selectedCategory = 'General';

    final categories = ['General', 'Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Income'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('New Transaction', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'What is this for?', border: OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), prefixText: '\$ '),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setSheetState(() => selectedCategory = v!),
              ),
              const SizedBox(height: 16),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.add_circle_outline)),
                ],
                selected: {selectedType},
                onSelectionChanged: (v) => setSheetState(() {
                   selectedType = v.first;
                   if (selectedType == TransactionType.income) {
                     selectedCategory = 'Income';
                   }
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text) ?? 0;
                    if (titleCtrl.text.isNotEmpty && amount > 0) {
                      _transactionBloc.add(AddTransactionEvent(Transaction(
                        id: const Uuid().v4(),
                        title: titleCtrl.text,
                        amount: amount,
                        type: selectedType,
                        category: selectedCategory,
                        date: DateTime.now(),
                        updatedAt: DateTime.now(),
                      )));
                      Navigator.pop(sheetContext);
                    }
                  },
                  child: const Text('Save Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
