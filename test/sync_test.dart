import 'package:akilli_mutfak/data/database.dart';
import 'package:akilli_mutfak/data/sync.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(),
        closeStreamsSynchronously: true));
  });
  tearDown(() => db.close());

  Future<List<SyncOutboxData>> outbox() => db.select(db.syncOutbox).get();

  Future<Ingredient> ing(String name) async =>
      (await db.watchIngredients().first).firstWhere((i) => i.name == name);

  Map<String, dynamic> remotePantry(String id, String hh,
          {required DateTime updatedAt, double quantity = 1}) =>
      {
        'id': id,
        'household_id': hh,
        'ingredient_id': 'ing_sut',
        'quantity': quantity,
        'unit': 'L',
        'expiry_date': '2026-10-05T00:00:00Z',
        'added_at': '2026-09-29T10:00:00Z',
        'outcome': null,
        'removed_at': null,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'deleted_at': null,
      };

  test('katalog outbox\'a girmez, kullanıcı verisi girer', () async {
    expect(await outbox(), isEmpty);

    await db.addToPantry([CartLine(await ing('Süt'), 1, DateTime.now())]);
    await db.createCustomIngredient(
        name: 'Ev Yapımı Reçel', category: 'Kahvaltılık', unit: 'adet');

    final entries = await outbox();
    expect(entries.map((e) => e.tbl).toSet(), {'pantry_items', 'ingredients'});

    // Aynı satır tekrar değişince tek kayıt kalır, seq artar.
    final item = (await db.watchPantry().first).single.item;
    final before = entries.firstWhere((e) => e.rowId == item.id).seq;
    await db.updatePantryItem(item.id, quantity: 3);
    final after = await outbox();
    expect(after.where((e) => e.rowId == item.id), hasLength(1));
    expect(after.firstWhere((e) => e.rowId == item.id).seq, greaterThan(before));
  });

  test('sunucudan gelen satır outbox\'a girmez, daha yenisi kazanır', () async {
    final hh = await db.householdId();
    final t0 = DateTime(2026, 9, 29, 12);

    await applyRemoteRows(db, 'pantry_items',
        [remotePantry('p1', hh, updatedAt: t0, quantity: 2)]);
    expect(await outbox(), isEmpty);
    expect((await db.watchPantry().first).single.item.quantity, 2);

    // Eski sürüm üzerine yazmaz.
    await applyRemoteRows(db, 'pantry_items', [
      remotePantry('p1', hh,
          updatedAt: t0.subtract(const Duration(minutes: 1)), quantity: 9)
    ]);
    expect((await db.watchPantry().first).single.item.quantity, 2);

    // Yeni sürüm yazar.
    await applyRemoteRows(db, 'pantry_items', [
      remotePantry('p1', hh,
          updatedAt: t0.add(const Duration(minutes: 1)), quantity: 5)
    ]);
    expect((await db.watchPantry().first).single.item.quantity, 5);

    // Bayrak temizlendi: yerel düzenleme yine kuyruğa girer.
    await db.updatePantryItem('p1', quantity: 1);
    expect((await outbox()).single.rowId, 'p1');
  });

  test('bilinmeyen malzeme için yer tutucu eklenir', () async {
    final hh = await db.householdId();
    await applyRemoteRows(db, 'pantry_items', [
      {
        ...remotePantry('p2', hh, updatedAt: DateTime(2026, 9, 29)),
        'ingredient_id': 'ing_yeni_urun',
      }
    ]);
    final entry = (await db.watchPantry().first).single;
    expect(entry.ingredient.name, 'Yeni urun');
  });

  test('sunucudan gelen yemek planı doğru güne yazılır', () async {
    final hh = await db.householdId();
    await applyRemoteRows(db, 'meal_plans', [
      {
        'id': 'mp1',
        'household_id': hh,
        'day': '2026-10-02',
        'recipe_id': 'rcp_menemen',
        'created_at': '2026-09-29T10:00:00Z',
        'updated_at': '2026-09-29T10:00:00Z',
        'deleted_at': null,
      }
    ]);
    final plans = await db.watchMealPlans(DateTime(2026, 10, 1), DateTime(2026, 10, 3)).first;
    expect(plans.single.day, DateTime(2026, 10, 2));
    expect(await outbox(), isEmpty);
  });

  test('haneye katılınca yerel veri yeni haneye taşınır', () async {
    await db.addToPantry([CartLine(await ing('Süt'), 1, DateTime.now())]);
    await db.delete(db.syncOutbox).go();
    await db.setValue('sync.pulled.pantry_items', 'x');

    await db.switchHousehold('yeni-hane');

    expect(await db.householdId(), 'yeni-hane');
    final item = (await db.watchPantry().first).single.item;
    expect(item.householdId, 'yeni-hane');
    expect((await outbox()).single.rowId, item.id);
    expect(await db.getValue('sync.pulled.pantry_items'), isNull);
  });
}
