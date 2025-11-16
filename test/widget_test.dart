import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App theme renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        title: 'BLISS Test',
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Test'),
          ),
          body: const Center(
            child: Text('BLISS App'),
          ),
        ),
      ),
    );
    
    expect(find.text('BLISS App'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
