import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foods_app/main.dart';

void main() {
  testWidgets('App renders SplashScreen on launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'isLoggedIn': false});

    await tester.pumpWidget(MyApp(isLoggedIn: false));

    expect(find.text('HOTEL'), findsOneWidget);
  });

  testWidgets('App shows SplashScreen when not logged in', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'isLoggedIn': false});

    await tester.pumpWidget(MyApp(isLoggedIn: false));

    expect(find.text('Good Food  •  Good Mood'), findsOneWidget);
  });

  testWidgets('App shows SplashScreen when already logged in', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'isLoggedIn': true});

    await tester.pumpWidget(MyApp(isLoggedIn: true));

    expect(find.text('HOTEL'), findsOneWidget);
  });
}