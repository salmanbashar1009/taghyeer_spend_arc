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
              body: Center(
                child: SizedBox(
                  height: 80,
                  width: 400,
                  child: SpringSwipeDelete(
                    onDeleted: () {
                      deleteCalled = true;
                    },
                    child: const ListTile(title: Text('Swipe Me')),
                  ),
                ),
              ),
            ),
          ),
        );

        // 1. Identify the widget to swipe
        final locator = find.text('Swipe Me');
        final Offset center = tester.getCenter(locator);

        // 2. Simulate a drag gesture manually to ensure proper 'up' event and velocity
        final gesture = await tester.startGesture(center);

        // Move slightly to the right first (some widgets require initial movement)
        // or go straight to the left
        await gesture.moveBy(const Offset(-100, 0));
        await tester.pump(); // Let the widget acknowledge the move

        await gesture.moveBy(const Offset(-300, 0));
        await tester.pump();

        // 3. Release the gesture
        await gesture.up();

        // 4. Handle the animation and the callback.
        // We use pump() with durations instead of pumpAndSettle()
        // in case the spring physics keep the ticker active for too long.
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 1)); // Ensure any internal timers finish

        expect(deleteCalled, true, reason: 'onDeleted should be called after a full swipe');
      });
}