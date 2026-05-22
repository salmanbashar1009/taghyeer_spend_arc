import 'dart:async';
import 'dart:ui' as ui;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/injection_container.dart';
import '../../features/transactions/domain/entities/transaction_entity.dart';
import '../../features/transactions/presentation/bloc/sync/sync_bloc.dart';
import '../../features/transactions/presentation/bloc/sync/sync_event.dart';
import '../../features/transactions/presentation/bloc/sync/sync_state.dart';
import '../../features/transactions/presentation/bloc/transaction_bloc.dart';
import '../../features/transactions/presentation/bloc/transaction_event.dart';
import '../../features/transactions/presentation/bloc/transaction_state.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  late final TransactionBloc _transactionBloc;
  late final SyncBloc _syncBloc;
  
  StreamSubscription? _connectivitySubscription;
  bool? _wasConnected;

  @override
  void initState() {
    super.initState();
    _transactionBloc = sl<TransactionBloc>();
    _syncBloc = sl<SyncBloc>();

    _transactionBloc.listenToSyncBloc(_syncBloc.stream);
    _transactionBloc.add(LoadTransactions());
    _syncBloc.add(StartSync());

    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = !results.contains(ConnectivityResult.none);
      if (_wasConnected != null && _wasConnected != isConnected) {
        final message = isConnected ? "Back Online - Syncing" : "Offline - Local Mode";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isConnected ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (isConnected) _syncBloc.add(ConnectivityRestored());
      }
      _wasConnected = isConnected;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _transactionBloc.close();
    _syncBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _transactionBloc),
        BlocProvider.value(value: _syncBloc),
      ],
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
          ],
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('New Transaction', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), prefixText: '\$ '),
              ),
              const SizedBox(height: 12),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                  ButtonSegment(value: TransactionType.income, label: Text('Income')),
                ],
                selected: {selectedType},
                onSelectionChanged: (v) => setSheetState(() => selectedType = v.first),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text) ?? 0;
                    if (titleCtrl.text.isNotEmpty && amount > 0) {
                      _transactionBloc.add(AddTransactionEvent(Transaction(
                        id: const Uuid().v4(),
                        title: titleCtrl.text,
                        amount: amount,
                        type: selectedType,
                        category: 'General',
                        date: DateTime.now(),
                        updatedAt: DateTime.now(),
                      )));
                      Navigator.pop(sheetContext);
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
