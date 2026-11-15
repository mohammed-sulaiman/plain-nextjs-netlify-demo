import 'package:family_tree/data/repository.dart';
import 'package:family_tree/data/sample_data.dart';
import 'package:family_tree/main.dart';
import 'package:family_tree/state/account.dart';
import 'package:family_tree/state/settings_store.dart';
import 'package:family_tree/state/tree_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TreeStore> pumpApp(WidgetTester tester, {Locale locale = const Locale('ar'), bool sample = false}) async {
  SharedPreferences.setMockInitialValues({});
  final settings = SettingsStore()..locale = locale;
  final store = TreeStore(LocalTreeRepository());
  final account = AccountController(store);
  await tester.runAsync(() async {
    await account.init();
    if (sample) await store.replaceAll(sampleFamily());
  });
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(FamilyTreeApp(settings: settings, store: store, account: account));
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('empty state renders', (tester) async {
    await pumpApp(tester);
    expect(find.text('ابدأ شجرة عائلتك'), findsOneWidget);
  });

  testWidgets('tree renders with sample family in both languages', (tester) async {
    for (final loc in const [Locale('ar'), Locale('en')]) {
      final store = await pumpApp(tester, locale: loc, sample: true);
      expect(store.data.persons.isNotEmpty, isTrue);
      expect(find.text('أحمد الحسني').evaluate().isNotEmpty || find.textContaining('أحمد').evaluate().isNotEmpty, isTrue);
    }
  });

  testWidgets('screens open without errors', (tester) async {
    final store = await pumpApp(tester, sample: true);
    final ahmed = store.data.persons.values.lastWhere((p) => p.givenName == 'أحمد');
    store.setFocus(ahmed.id);
    await tester.pumpAndSettle();

    // Tap a card -> action sheet -> details.
    await tester.tap(find.text('أحمد الحسني').first);
    // Cards also listen for double taps, so wait out the double-tap timeout.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرض التفاصيل'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('الخط الزمني'), 300,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    expect(find.text('الخط الزمني'), findsOneWidget);
    expect(find.textContaining('الزواج من ليلى'), findsOneWidget);

    // Edit screen.
    await tester.tap(find.byTooltip('تعديل'));
    await tester.pumpAndSettle();
    expect(find.text('تعديل الشخص'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    // Relationship calculator.
    await tester.tap(find.byTooltip('حاسبة القرابة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الشخص الثاني'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'سالم');
    await tester.pumpAndSettle();
    await tester.tap(find.text('سالم الحسني').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('ابن العم'), findsWidgets);
    expect(find.text('12.5%'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    // Display options and settings.
    await tester.tap(find.byTooltip('خيارات العرض'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('النسب'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<dynamic>).evaluate().isEmpty
        ? find.byIcon(Icons.more_vert)
        : find.byType(PopupMenuButton<dynamic>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('التقويم'), findsOneWidget);
  });
}
