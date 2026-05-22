import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taghyeer_spend_arc/features/transactions/presentation/widgets/spring_swipe_delete.dart';

void main() {
  testWidgets('SpringSwipeDelete renders child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpringSwipeDelete(
            onDeleted: () {},
            child: const ListTile(title: Text('Test Item')),
          ),
        ),
      ),
    );

    expect(find.text('Test Item'), findsOneWidget);
  });

  testWidgets('SpringSwipeDelete calls onDeleted after sufficient swipe',
          (tester) async {
        var deleteCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 80,
                width: 400,
                child: SpringSwipeDelete(
                  onDeleted: () => deleteCalled = true,
                  child: const ListTile(title: Text('Swipe Me')),
                ),
              ),
            ),
          ),
        );

        // Start gesture and drag left past threshold
        final locator = find.text('Swipe Me');
        await tester.drag(locator, const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Allow the delayed callback to fire
        await tester.pump(const Duration(milliseconds: 300));

        expect(deleteCalled, true);
      });
}