import 'package:flutter_test/flutter_test.dart';
import 'package:rebost/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const RebostApp());
    await tester.pump();

    // Verify the app loads (shows loading or login screen)
    expect(find.text('Rebost'), findsAny);
  });
}
