import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:forever_young/app.dart';
import 'package:forever_young/providers/settings_provider.dart';

void main() {
  testWidgets('App should render splash screen', (WidgetTester tester) async {
    final settingsProvider = SettingsProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settingsProvider,
        child: const ForeverYoungApp(),
      ),
    );

    // Verify that the splash screen shows the app name
    expect(find.text('Forever Young'), findsOneWidget);
  });
}
