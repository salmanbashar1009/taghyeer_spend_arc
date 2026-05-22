import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/widgets/arc_meter.dart';

void main() {
  testWidgets('ArcMeter renders percentage text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArcMeter(
            spent: 3000,
            budget: 5000,
            animationValue: 1.0,
          ),
        ),
      ),
    );

    expect(find.textContaining('60%'), findsOneWidget);
    expect(find.textContaining('3000'), findsOneWidget);
    expect(find.textContaining('5000'), findsOneWidget);
  });

  testWidgets('ArcMeter handles zero budget gracefully', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArcMeter(
            spent: 100,
            budget: 0,
            animationValue: 1.0,
          ),
        ),
      ),
    );

    expect(find.textContaining('0%'), findsOneWidget);
  });
}