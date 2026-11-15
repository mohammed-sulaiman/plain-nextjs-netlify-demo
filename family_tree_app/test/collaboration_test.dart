import 'dart:async';
import 'dart:typed_data';

import 'package:family_tree/data/repository.dart';
import 'package:family_tree/data/sample_data.dart';
import 'package:family_tree/main.dart';
import 'package:family_tree/models/models.dart';
import 'package:family_tree/services/collaboration.dart';
import 'package:family_tree/state/account.dart';
import 'package:family_tree/state/settings_store.dart';
import 'package:family_tree/state/tree_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory repository that can play a viewer and simulate edits made by
/// another member.
class FakeRepository implements TreeRepository {
  FamilyData stored;
  final bool editable;
  final changes = StreamController<void>.broadcast();
  int loads = 0;
  bool disposed = false;

  FakeRepository(this.stored, {this.editable = true});

  @override
  bool get isCloud => true;
  @override
  bool get canEdit => editable;
  @override
  Stream<void>? get remoteChanges => changes.stream;
  @override
  void dispose() => disposed = true;

  @override
  Future<FamilyData> load() async {
    loads++;
    return FamilyData.fromJson(stored.toJson());
  }

  @override
  Future<void> savePerson(Person p) async => stored.persons[p.id] = p;
  @override
  Future<void> deletePerson(String id) async => stored.persons.remove(id);
  @override
  Future<void> saveUnion(Union u) async => stored.unions.add(u);
  @override
  Future<void> deleteUnion(String id) async =>
      stored.unions.removeWhere((u) => u.id == id);
  @override
  Future<void> saveLink(ParentLink l) async => stored.links.add(l);
  @override
  Future<void> deleteLink(String id) async =>
      stored.links.removeWhere((l) => l.id == id);
  @override
  Future<void> replaceAll(FamilyData data) async => stored = data;
  @override
  Future<String> storePhoto(String personId, Uint8List bytes) async => '';
}

void main() {
  group('invite codes', () {
    test('normalises typed codes and pasted links', () {
      expect(
        CollaborationService.normalizeCode(' ab12 cd-34ef '),
        'AB12CD34EF',
      );
      expect(
        CollaborationService.normalizeCode(
          'https://family.example.com/?invite=ab12cd34ef',
        ),
        'AB12CD34EF',
      );
    });

    test('invite link uses the web origin', () {
      expect(
        CollaborationService.inviteLink(
          'AB12CD34EF',
          webBase: Uri.parse('https://family.example.com/'),
        ),
        'https://family.example.com/?invite=AB12CD34EF',
      );
      expect(CollaborationService.inviteLink('AB12CD34EF'), isNull);
    });
  });

  group('shared tree store', () {
    test('viewers cannot change anything', () async {
      final repo = FakeRepository(sampleFamily(), editable: false);
      final store = TreeStore(repo);
      await store.load();
      final someone = store.data.persons.values.first;
      final before = store.data.persons.length;

      expect(store.canEdit, isFalse);
      await expectLater(
        store.savePerson(someone.copyWith(givenName: 'X')),
        throwsStateError,
      );
      await expectLater(store.deletePerson(someone.id), throwsStateError);
      await expectLater(store.addUnion(someone.id, 'x'), throwsStateError);
      await expectLater(store.replaceAll(FamilyData()), throwsStateError);
      expect(store.data.persons.length, before);
      expect(store.data[someone.id]!.givenName, someone.givenName);
    });

    test('edits by another member reload the tree once per burst', () async {
      final repo = FakeRepository(sampleFamily());
      final store = TreeStore(repo);
      await store.load();
      final focus = store.focusId;
      final loadsBefore = repo.loads;

      // A collaborator adds a person (three quick events).
      final p = Person(id: 'remote-1', givenName: 'Remote');
      repo.stored.persons[p.id] = p;
      for (var i = 0; i < 3; i++) {
        repo.changes.add(null);
      }
      await Future<void>.delayed(const Duration(milliseconds: 900));

      expect(repo.loads, loadsBefore + 1);
      expect(store.data['remote-1']?.givenName, 'Remote');
      expect(store.focusId, focus, reason: 'silent reload keeps the focus');
      expect(store.loading, isFalse);
    });

    test('switching trees disposes the previous repository', () async {
      final first = FakeRepository(sampleFamily());
      final store = TreeStore(first);
      await store.load();
      final second = FakeRepository(FamilyData());
      await store.switchRepository(second);
      expect(first.disposed, isTrue);
      expect(store.data.isEmpty, isTrue);
      expect(store.focusId, isNull);

      // Events from the old tree are ignored.
      final loads = second.loads;
      first.changes.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      expect(second.loads, loads);
    });
  });

  testWidgets('viewer sees no editing controls', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsStore()..locale = const Locale('ar');
    final store = TreeStore(FakeRepository(sampleFamily(), editable: false));
    final account = AccountController(store);
    await tester.runAsync(store.load);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      FamilyTreeApp(settings: settings, store: store, account: account),
    );
    await tester.pumpAndSettle();

    expect(find.text('إضافة شخص'), findsNothing, reason: 'no add FAB');
    expect(find.byTooltip('مشاركة الشجرة'), findsOneWidget);

    final ahmed = store.data.persons.values.lastWhere(
      (p) => p.givenName == 'أحمد',
    );
    store.setFocus(ahmed.id);
    await tester.pumpAndSettle();
    await tester.tap(find.text('أحمد الحسني').first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('عرض التفاصيل'), findsOneWidget);
    expect(find.text('تعديل'), findsNothing);
    expect(find.text('إضافة قريب'), findsNothing);

    await tester.tap(find.text('عرض التفاصيل'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('تعديل'), findsNothing);
    expect(find.text('إضافة'), findsNothing);
    expect(find.byTooltip('إزالة الربط'), findsNothing);
  });
}
