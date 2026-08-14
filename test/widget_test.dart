import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:queue_token_app/main.dart';

void main() {
  testWidgets('App renders SplashScreen and transitions to PhoneAuthScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    await tester.pumpWidget(const QTokenApp());

    // Verify SplashScreen initial state
    expect(find.text('LineZero'), findsOneWidget);

    // Advance time past splash delay (2000ms)
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Verify PhoneAuthScreen loaded
    expect(find.textContaining('Sign in'), findsAtLeastNWidgets(1));
  });
}
