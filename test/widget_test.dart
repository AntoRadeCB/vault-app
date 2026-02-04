import 'package:flutter_test/flutter_test.dart';
import 'package:vault_app/main.dart';

void main() {
  testWidgets('VaultApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const VaultApp());
    expect(find.text('Reselling Vinted 2025'), findsOneWidget);
  });
}
