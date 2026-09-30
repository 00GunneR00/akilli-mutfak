import 'package:akilli_mutfak/core/dates.dart';
import 'package:akilli_mutfak/core/text.dart';
import 'package:akilli_mutfak/data/database.dart';
import 'package:akilli_mutfak/data/seed_catalog.dart';
import 'package:akilli_mutfak/features/pantry/restock.dart';
import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(),
        closeStreamsSynchronously: true));
  });
  tearDown(() => db.close());

  Future<Ingredient> ing(String name) async =>
      (await db.watchIngredients().first).firstWhere((i) => i.name == name);

  test('katalog yüklenir ve kimlikler benzersizdir', () async {
    final all = await db.watchIngredients().first;
    expect(all.length, seedIngredients.length);
    expect(all.map((i) => i.id).toSet().length, all.length);
  });

  test('Türkçe arama', () {
    expect(matchScore('Süt', 'sut'), 0);
    expect(matchScore('Kaşar Peyniri', 'peynir'), 1);
    expect(matchScore('Ispanak', 'ISPANAK'), 0);
    expect(matchScore('Domates', 'süt'), isNull);
    expect(slugId('Kaşar Peyniri'), 'ing_kasar_peyniri');
  });

  test('alışveriş işaretlenince dolaba girer, kaldırılınca çıkar', () async {
    final sut = await ing('Süt');
    await db.addToShopping([CartLine(sut, 1)]);
    await db.addToShopping([CartLine(sut, 1)]);

    var list = await db.watchShopping().first;
    expect(list, hasLength(1), reason: 'aynı ürün birleştirilmeli');
    expect(list.single.item.quantity, 2);

    expect(await db.toggleShopping(list.single), isTrue);
    var pantry = await db.watchPantry().first;
    expect(pantry.single.ingredient.name, 'Süt');
    expect(pantry.single.item.quantity, 2);

    list = await db.watchShopping().first;
    await db.toggleShopping(list.single);
    pantry = await db.watchPantry().first;
    expect(pantry, isEmpty);
  });

  test('bitti: dolaptan çıkar, listeye girer, geri alınabilir', () async {
    final sut = await ing('Süt');
    await db.addToPantry([CartLine(sut, 1)]);
    final entry = (await db.watchPantry().first).single;

    final shoppingId = await db.finishPantryItem(entry);
    expect(await db.watchPantry().first, isEmpty);
    final list = await db.watchShopping().first;
    expect(list.single.item.id, shoppingId);
    expect(list.single.item.source, 'finished');

    await db.undoFinishPantryItem(entry.item.id, shoppingId);
    expect(await db.watchPantry().first, hasLength(1));
    expect(await db.watchShopping().first, isEmpty);
  });

  test('azaldı işaretli ürün yenisi alınınca dolaptan düşer', () async {
    final sut = await ing('Süt');
    await db.addToPantry([CartLine(sut, 1)]);
    final old = (await db.watchPantry().first).single;
    await db.setPantryStatus(old.item.id, StockStatus.low);

    await db.addToShopping([CartLine(sut, 1)]);
    await db.toggleShopping((await db.watchShopping().first).single);

    final pantry = await db.watchPantry().first;
    expect(pantry, hasLength(1));
    expect(pantry.single.item.id, isNot(old.item.id));
    expect(pantry.single.item.status, StockStatus.ok);
  });

  test('çöpe giden ürün istatistiğe yansır, geri alınabilir', () async {
    final domates = await ing('Domates');
    await db.addToPantry([CartLine(domates, 1)]);
    final item = (await db.watchPantry().first).single.item;

    await db.setPantryOutcome(item.id, Outcome.wasted);
    expect(await db.watchPantry().first, isEmpty);
    final removed = await db
        .watchRemovedSince(DateTime.now().subtract(const Duration(days: 1)))
        .first;
    expect(removed.single.item.outcome, Outcome.wasted);

    await db.setPantryOutcome(item.id, null);
    expect(await db.watchPantry().first, hasLength(1));
  });

  test('sık alınanlar geçmişe göre sıralanır', () async {
    final roka = await ing('Roka');
    for (var i = 0; i < 3; i++) {
      await db.addToPantry([CartLine(roka, 1)]);
    }
    final frequent = await db.watchFrequent().first;
    expect(frequent.first.name, 'Roka');
    expect(frequent, hasLength(12));
  });

  test('katalog güncellemesi eski kayıtları düzeltir, özel ürünlere dokunmaz',
      () async {
    // Eski sürümden kalma durum: katalog ürünü eski kategoride, özel ürün
    // artık olmayan bir kategoride.
    await (db.update(db.ingredients)..where((t) => t.id.equals('ing_maydanoz')))
        .write(const IngredientsCompanion(category: Value('Sebze')));
    final custom = await db.createCustomIngredient(
        name: 'Ev Yapımı Sucuk', category: 'Et & Tavuk', unit: 'paket');

    await db.seedCatalog();

    expect((await ing('Maydanoz')).category, 'Meyve & Sebze');
    final after = await ing('Ev Yapımı Sucuk');
    expect(after.isCustom, isTrue);
    expect(after.id, custom.id);
    expect(after.category, 'Et, Tavuk & Balık');
    expect(await db.watchIngredients().first, hasLength(seedIngredients.length + 1));
  });

  test('alım aralığı en az 3 alımdan medyanla hesaplanır', () {
    final d = DateTime(2026, 9, 1);
    expect(purchaseInterval([d, addDays(d, 5)]), isNull);
    expect(purchaseInterval([d, addDays(d, 5), addDays(d, 11), addDays(d, 30)]), 6);
  });

  test('bitmiş olabilir önerileri', () async {
    final sut = await ing('Süt');
    final pirinc = await ing('Pirinç');
    await db.addToPantry([CartLine(sut, 1), CartLine(pirinc, 1)]);
    final pantry = await db.watchPantry().first;
    final now = DateTime.now();
    final later = addDays(now, sut.shelfDays);

    // Süt raf ömrü kadar önce alındı, pirinç çok uzun dayanır.
    var hints = restockHints(pantry, const {}, const {}, now: later);
    expect(hints.map((h) => h.entry.ingredient.name), ['Süt']);

    // Geçmişten öğrenilen aralık raf ömrünün yerine geçer.
    final history = {
      sut.id: [addDays(now, -4), addDays(now, -2), now],
    };
    hints = restockHints(pantry, history, const {}, now: addDays(now, 2));
    expect(hints.single.reason, 'Genelde 2 günde bir alıyorsun');

    // Listede bekleyen ürün önerilmez.
    expect(restockHints(pantry, history, {sut.id}, now: addDays(now, 2)), isEmpty);

    // Azaldı her zaman önerilir.
    final riceEntry = pantry.firstWhere((e) => e.ingredient.id == pirinc.id);
    await db.setPantryStatus(riceEntry.item.id, StockStatus.low);
    hints = restockHints(await db.watchPantry().first, const {}, const {}, now: now);
    expect(hints.single.low, isTrue);
  });

  test('tazelik sınıfları', () {
    expect(Freshness.of(-1), Freshness.expired);
    expect(Freshness.of(1), Freshness.critical);
    expect(Freshness.of(3), Freshness.soon);
    expect(Freshness.of(10), Freshness.fresh);
  });
}
