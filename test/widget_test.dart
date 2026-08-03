import 'package:flutter_test/flutter_test.dart';

import 'package:lol_tabu/main.dart';

void main() {
  testWidgets('Home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const LoLTabuApp());
    await tester.pumpAndSettle();

    expect(find.text('LoL Tabu'), findsOneWidget);
  });
}
