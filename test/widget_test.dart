import 'package:flutter_test/flutter_test.dart';
import 'package:motofind/main.dart';

void main() {
  testWidgets('MotoFind app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MotoFindApp());

    expect(find.text('MotoFind'), findsOneWidget);
  });
}