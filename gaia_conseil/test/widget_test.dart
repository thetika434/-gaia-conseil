import 'package:flutter_test/flutter_test.dart';
import 'package:gaia_conseil/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GaiaApp());
    expect(find.byType(GaiaApp), findsOneWidget);
  });
}
