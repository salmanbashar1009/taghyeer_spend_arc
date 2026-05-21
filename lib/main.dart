import 'package:flutter/material.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/pages/transaction_home_page.dart';

import 'core/di/injection_container.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  /// initialize all dependencies
  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendArc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 14, height: 1.4),
        ),
      ),
      home: const TransactionHomePage(),
    );
  }
}
