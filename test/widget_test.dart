import 'package:flutter_test/flutter_test.dart';
import 'package:popcornbattlegame/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PopcornBattleApp(isLoggedIn: false));
    expect(find.byType(PopcornBattleApp), findsOneWidget);
  });
}
