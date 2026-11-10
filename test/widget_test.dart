import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langkah/core/providers/theme_provider.dart';
import 'package:langkah/main.dart';

void main() {
  testWidgets('Langkah app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(LangkahApp(themeProvider: ThemeProvider()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
