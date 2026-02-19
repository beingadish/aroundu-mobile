import 'package:aroundu/src/core/widgets/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppNotifier shows and auto dismisses custom notification', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppNotifier.showSuccess(
                    context,
                    'Saved successfully',
                    duration: const Duration(milliseconds: 200),
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(find.text('Saved successfully'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump();
    expect(find.text('Saved successfully'), findsNothing);
  });

  testWidgets('AppNotifier replaces existing notification with latest one', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      AppNotifier.showInfo(
                        context,
                        'First notification',
                        duration: const Duration(seconds: 2),
                      );
                    },
                    child: const Text('First'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppNotifier.showError(
                        context,
                        'Second notification',
                        duration: const Duration(seconds: 2),
                      );
                    },
                    child: const Text('Second'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('First'));
    await tester.pump();
    expect(find.text('First notification'), findsOneWidget);

    await tester.tap(find.text('Second'));
    await tester.pump();
    expect(find.text('First notification'), findsNothing);
    expect(find.text('Second notification'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
