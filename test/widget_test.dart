import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // アプリをビルドして最初のフレームをトリガー
    await tester.pumpWidget(const ProviderScope(child: App()));

    // アプリが正常に起動することを確認
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
