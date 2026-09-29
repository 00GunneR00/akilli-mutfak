import 'package:akilli_mutfak/core/dates.dart';
import 'package:akilli_mutfak/core/text.dart';
import 'package:akilli_mutfak/data/database.dart';
import 'package:akilli_mutfak/data/seed_catalog.dart';
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
    await db.addToShopping([CartLine(sut, 1, DateTime.now())]);
    await db.addToShopping([CartLine(sut, 1, DateTime.now())]);

    var list = await db.watchShopping().first;
    expect(list, hasLength(1), reason: 'aynı ürün birleştirilmeli');
    expect(list.single.item.quantity, 2);

    final expiry = await db.toggleShopping(list.single);
    expect(daysLeft(expiry!), sut.shelfDays);
    var pantry = await db.watchPantry().first;
    expect(pantry.single.ingredient.name, 'Süt');
    expect(pantry.single.item.quantity, 2);

    list = await db.watchShopping().first;
    await db.toggleShopping(list.single);
    pantry = await db.watchPantry().first;
    expect(pantry, isEmpty);
  });

  test('çöpe giden ürün istatistiğe yansır, geri alınabilir', () async {
    final domates = await ing('Domates');
    await db.addToPantry([CartLine(domates, 1, DateTime.now())]);
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
      await db.addToPantry([CartLine(roka, 1, DateTime.now())]);
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

  test('tazelik sınıfları', () {
    expect(Freshness.of(-1), Freshness.expired);
    expect(Freshness.of(1), Freshness.critical);
    expect(Freshness.of(3), Freshness.soon);
    expect(Freshness.of(10), Freshness.fresh);
  });
}
