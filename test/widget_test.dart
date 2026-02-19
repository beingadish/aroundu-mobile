import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroundu/app.dart';

void main() {
  testWidgets('AroundU app boots on splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: AroundUApp()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
