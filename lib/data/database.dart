import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:uuid/uuid.dart';

import '../core/dates.dart';
import '../core/text.dart';
import 'seed_catalog.dart';

part 'database.g.dart';

const _uuid = Uuid();

// Senkronizasyona hazır şema: UUID kimlik, householdId, updatedAt ve yumuşak
// silme (deletedAt). Aile paylaşımı eklendiğinde satırlar olduğu gibi taşınır.

class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get emoji => text()();
  TextColumn get unit => text()();
  RealColumn get defaultQty => real()();
  IntColumn get shelfDays => integer()();
  IntColumn get popularity => integer().withDefault(const Constant(0))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PantryItems extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get ingredientId => text().references(Ingredients, #id)();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  DateTimeColumn get expiryDate => dateTime()();
  DateTimeColumn get addedAt => dateTime()();

  /// null: hâlâ dolapta. Aksi halde [Outcome.consumed] / [Outcome.wasted].
  TextColumn get outcome => text().nullable()();
  DateTimeColumn get removedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Yanlışlıkla eklenenler: istatistiklere dahil edilmez.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ShoppingItems extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get ingredientId => text().references(Ingredients, #id)();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  DateTimeColumn get checkedAt => dateTime().nullable()();

  /// İşaretlenince oluşturulan dolap kaydı; işaret kaldırılırsa geri alınır.
  TextColumn get pantryItemId => text().nullable()();

  /// 'manual' veya ileride yemek planından gelenler için 'plan'.
  TextColumn get source => text().withDefault(const Constant('manual'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Haftalık yemek planı: bir güne atanmış tarif (tarifler kodda, `recipe_catalog`).
class MealPlans extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();

  /// Yalnızca tarih (yerel gece yarısı).
  DateTimeColumn get day => dateTime()();
  TextColumn get recipeId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sunucuya gönderilmeyi bekleyen satırlar; SQLite tetikleyicileri doldurur.
/// [seq] her değişiklikte artar, gönderim sırasında gelen yeni değişiklik
/// böylece yanlışlıkla silinmez.
class SyncOutbox extends Table {
  TextColumn get tbl => text()();
  TextColumn get rowId => text()();
  IntColumn get seq => integer()();

  @override
  Set<Column> get primaryKey => {tbl, rowId};
}

class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

abstract final class Outcome {
  static const consumed = 'consumed';
  static const wasted = 'wasted';
}

class PantryEntry {
  PantryEntry(this.item, this.ingredient);
  final PantryItem item;
  final Ingredient ingredient;
}

class ShoppingEntry {
  ShoppingEntry(this.item, this.ingredient);
  final ShoppingItem item;
  final Ingredient ingredient;
}

/// Hızlı ekleme sepetindeki bir satır.
class CartLine {
  CartLine(this.ingredient, this.quantity, this.expiry);
  final Ingredient ingredient;
  double quantity;
  DateTime expiry;
}

/// Sunucudan gelen değişiklikler uygulanırken bu anahtar varsa tetikleyiciler
/// susar; aksi halde her çekilen satır geri gönderilirdi.
const syncApplyingKey = 'sync.applying';

/// Senkronize edilen tablolar ve outbox'a hangi satırların gireceği.
const _outboxTriggers = {
  'ingredients': 'NEW.is_custom = 1',
  'pantry_items': '1',
  'shopping_items': '1',
  'meal_plans': '1',
};

@DriftDatabase(tables: [
  Ingredients,
  PantryItems,
  ShoppingItems,
  MealPlans,
  KeyValues,
  SyncOutbox,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'akilli_mutfak'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createOutboxTriggers();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(syncOutbox);
          if (from < 3) await m.createTable(mealPlans);
          await _createOutboxTriggers();
          if (from < 2) await enqueueAllForSync();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Her açılışta katalogu ekler/günceller; sözlük güncellemeleri
          // böylece migration gerektirmeden kullanıcılara ulaşır.
          await seedCatalog();
        },
      );

  Future<void> _createOutboxTriggers() async {
    for (final MapEntry(key: table, value: condition) in _outboxTriggers.entries) {
      for (final op in ['INSERT', 'UPDATE']) {
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS ${table}_outbox_${op.toLowerCase()}
          AFTER $op ON $table
          WHEN $condition AND NOT EXISTS
            (SELECT 1 FROM key_values WHERE key = '$syncApplyingKey')
          BEGIN
            INSERT OR REPLACE INTO sync_outbox (tbl, row_id, seq)
            VALUES ('$table', NEW.id,
              (SELECT COALESCE(MAX(seq), 0) + 1 FROM sync_outbox));
          END''');
      }
    }
  }

  /// Tüm hane verisini (katalog hariç) yeniden gönderim kuyruğuna alır.
  Future<void> enqueueAllForSync() async {
    for (final MapEntry(key: table, value: condition) in _outboxTriggers.entries) {
      await customStatement('''
        INSERT OR REPLACE INTO sync_outbox (tbl, row_id, seq)
        SELECT '$table', id,
          (SELECT COALESCE(MAX(seq), 0) FROM sync_outbox) + ROW_NUMBER() OVER ()
        FROM $table WHERE ${condition.replaceAll('NEW.', '')}''');
    }
  }

  Future<String?> getValue(String key) async =>
      (await (select(keyValues)..where((t) => t.key.equals(key)))
              .getSingleOrNull())
          ?.value;

  Future<void> setValue(String key, String value) => into(keyValues)
      .insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: value));

  Future<void> removeValue(String key) =>
      (delete(keyValues)..where((t) => t.key.equals(key))).go();

  /// Başka bir haneye katılınca yerel veriyi o haneye taşır; sonraki
  /// senkronizasyonda aileninkiyle birleşir.
  Future<void> switchHousehold(String newId) async {
    await transaction(() async {
      final now = DateTime.now();
      await setValue('householdId', newId);
      await update(pantryItems).write(PantryItemsCompanion(
          householdId: Value(newId), updatedAt: Value(now)));
      await update(shoppingItems).write(ShoppingItemsCompanion(
          householdId: Value(newId), updatedAt: Value(now)));
      await update(mealPlans).write(
          MealPlansCompanion(householdId: Value(newId), updatedAt: Value(now)));
      await enqueueAllForSync();
      await (delete(keyValues)..where((t) => t.key.like('sync.pulled.%'))).go();
    });
    _householdId = newId;
  }

  /// Katalogu ekler; değişen katalog öğelerini (kategori, emoji, birim, raf
  /// ömrü…) günceller. Kullanıcının kendi eklediği ürünlere dokunmaz, yalnızca
  /// eski kategori adlarını yenilerine taşır.
  @visibleForTesting
  Future<void> seedCatalog() async {
    final now = DateTime.now();
    await batch((b) {
      b.insertAll(
        ingredients,
        [
          for (final s in seedIngredients)
            IngredientsCompanion.insert(
              id: slugId(s.name),
              name: s.name,
              category: s.category,
              emoji: s.emoji,
              unit: s.unit,
              defaultQty: s.qty,
              shelfDays: s.days,
              popularity: Value(s.pop),
              updatedAt: now,
            ),
        ],
        onConflict: DoUpdate<$IngredientsTable, Ingredient>.withExcluded(
          (old, excluded) => IngredientsCompanion.custom(
            category: excluded.category,
            emoji: excluded.emoji,
            unit: excluded.unit,
            defaultQty: excluded.defaultQty,
            shelfDays: excluded.shelfDays,
            popularity: excluded.popularity,
            updatedAt: excluded.updatedAt,
          ),
          where: (old, excluded) =>
              old.isCustom.not() &
              (old.category.equalsExp(excluded.category).not() |
                  old.emoji.equalsExp(excluded.emoji).not() |
                  old.unit.equalsExp(excluded.unit).not() |
                  old.defaultQty.equalsExp(excluded.defaultQty).not() |
                  old.shelfDays.equalsExp(excluded.shelfDays).not() |
                  old.popularity.equalsExp(excluded.popularity).not()),
        ),
      );
      for (final MapEntry(key: from, value: to) in legacyCategories.entries) {
        b.update(
          ingredients,
          IngredientsCompanion(category: Value(to), updatedAt: Value(now)),
          where: (t) => t.category.equals(from),
        );
      }
    });
  }

  String? _householdId;

  Future<String> householdId() async {
    if (_householdId != null) return _householdId!;
    final stored = await getValue('householdId');
    if (stored != null) return _householdId = stored;
    final id = _uuid.v4();
    await into(keyValues)
        .insert(KeyValuesCompanion.insert(key: 'householdId', value: id));
    return _householdId = id;
  }

  // ---------------------------------------------------------------- Malzemeler

  Stream<List<Ingredient>> watchIngredients() =>
      (select(ingredients)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  /// Son 90 günde en çok eklenenler; geçmiş azsa genel popülerliğe göre tamamlanır.
  Stream<List<Ingredient>> watchFrequent({int limit = 12}) {
    final since = DateTime.now().subtract(const Duration(days: 90));
    return customSelect(
      'SELECT i.* FROM ingredients i '
      'LEFT JOIN pantry_items p ON p.ingredient_id = i.id '
      'AND p.deleted_at IS NULL AND p.added_at >= ?1 '
      'GROUP BY i.id '
      'ORDER BY COUNT(p.id) DESC, i.popularity DESC, i.name ASC '
      'LIMIT ?2',
      variables: [Variable.withDateTime(since), Variable.withInt(limit)],
      readsFrom: {ingredients, pantryItems},
    ).watch().map((rows) => rows.map((r) => ingredients.map(r.data)).toList());
  }

  Future<Ingredient> createCustomIngredient({
    required String name,
    required String category,
    required String unit,
  }) async {
    final base = slugId(name);
    var id = base;
    // Aynı isimde bir katalog öğesi varsa onu kullan.
    final existing = await (select(ingredients)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (existing != null) return existing;
    final companion = IngredientsCompanion.insert(
      id: id,
      name: name.trim(),
      category: category,
      emoji: categoryEmoji[category] ?? '🛒',
      unit: unit,
      defaultQty: 1,
      shelfDays: categoryShelfDays[category] ?? 30,
      isCustom: const Value(true),
      updatedAt: DateTime.now(),
    );
    await into(ingredients).insert(companion);
    return (select(ingredients)..where((t) => t.id.equals(id))).getSingle();
  }

  // --------------------------------------------------------------------- Dolap

  JoinedSelectStatement<HasResultSet, dynamic> _pantryJoin() =>
      select(pantryItems).join([
        innerJoin(ingredients, ingredients.id.equalsExp(pantryItems.ingredientId)),
      ]);

  List<PantryEntry> _mapPantry(List<TypedResult> rows) => [
        for (final r in rows)
          PantryEntry(r.readTable(pantryItems), r.readTable(ingredients)),
      ];

  Stream<List<PantryEntry>> watchPantry() {
    final q = _pantryJoin()
      ..where(pantryItems.outcome.isNull() & pantryItems.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.asc(pantryItems.expiryDate),
        OrderingTerm.asc(ingredients.name),
      ]);
    return q.watch().map(_mapPantry);
  }

  /// Tüketilen / çöpe giden ürünler (istatistik ekranı için).
  Stream<List<PantryEntry>> watchRemovedSince(DateTime since) {
    final q = _pantryJoin()
      ..where(pantryItems.outcome.isNotNull() &
          pantryItems.deletedAt.isNull() &
          pantryItems.removedAt.isBiggerOrEqualValue(since))
      ..orderBy([OrderingTerm.desc(pantryItems.removedAt)]);
    return q.watch().map(_mapPantry);
  }

  Future<void> addToPantry(List<CartLine> lines) async {
    final hh = await householdId();
    final now = DateTime.now();
    await batch((b) {
      b.insertAll(pantryItems, [
        for (final l in lines)
          PantryItemsCompanion.insert(
            id: _uuid.v4(),
            householdId: hh,
            ingredientId: l.ingredient.id,
            quantity: l.quantity,
            unit: l.ingredient.unit,
            expiryDate: dateOnly(l.expiry),
            addedAt: now,
            updatedAt: now,
          ),
      ]);
    });
  }

  Future<void> updatePantryItem(String id,
      {double? quantity, DateTime? expiry}) {
    return (update(pantryItems)..where((t) => t.id.equals(id))).write(
      PantryItemsCompanion(
        quantity: quantity == null ? const Value.absent() : Value(quantity),
        expiryDate: expiry == null ? const Value.absent() : Value(dateOnly(expiry)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// [outcome]: [Outcome.consumed] veya [Outcome.wasted]; null geri alır.
  Future<void> setPantryOutcome(String id, String? outcome) {
    final now = DateTime.now();
    return (update(pantryItems)..where((t) => t.id.equals(id))).write(
      PantryItemsCompanion(
        outcome: Value(outcome),
        removedAt: Value(outcome == null ? null : now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deletePantryItem(String id) {
    final now = DateTime.now();
    return (update(pantryItems)..where((t) => t.id.equals(id))).write(
      PantryItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  // ---------------------------------------------------------- Alışveriş listesi

  Stream<List<ShoppingEntry>> watchShopping() {
    final q = select(shoppingItems).join([
      innerJoin(ingredients, ingredients.id.equalsExp(shoppingItems.ingredientId)),
    ])
      ..where(shoppingItems.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.asc(shoppingItems.checkedAt, nulls: NullsOrder.first),
        OrderingTerm.asc(ingredients.category),
        OrderingTerm.asc(ingredients.name),
      ]);
    return q.watch().map((rows) => [
          for (final r in rows)
            ShoppingEntry(r.readTable(shoppingItems), r.readTable(ingredients)),
        ]);
  }

  /// Listede işaretlenmemiş aynı ürün varsa miktarı artırır.
  Future<void> addToShopping(List<CartLine> lines) async {
    final hh = await householdId();
    await transaction(() async {
      for (final l in lines) {
        final now = DateTime.now();
        final existing = await (select(shoppingItems)
              ..where((t) =>
                  t.ingredientId.equals(l.ingredient.id) &
                  t.checkedAt.isNull() &
                  t.deletedAt.isNull()))
            .getSingleOrNull();
        if (existing != null) {
          await (update(shoppingItems)..where((t) => t.id.equals(existing.id)))
              .write(ShoppingItemsCompanion(
            quantity: Value(existing.quantity + l.quantity),
            updatedAt: Value(now),
          ));
        } else {
          await into(shoppingItems).insert(ShoppingItemsCompanion.insert(
            id: _uuid.v4(),
            householdId: hh,
            ingredientId: l.ingredient.id,
            quantity: l.quantity,
            unit: l.ingredient.unit,
            createdAt: now,
            updatedAt: now,
          ));
        }
      }
    });
  }

  /// Döngünün kalbi: işaretlenen ürün tahmini SKT ile dolaba girer,
  /// işaret kaldırılırsa dolaptan geri çıkar. İşaretlenince SKT'yi döndürür.
  Future<DateTime?> toggleShopping(ShoppingEntry e) async {
    final hh = await householdId();
    return transaction(() async {
      final now = DateTime.now();
      if (e.item.checkedAt == null) {
        final pantryId = _uuid.v4();
        final expiry = addDays(now, e.ingredient.shelfDays);
        await into(pantryItems).insert(PantryItemsCompanion.insert(
          id: pantryId,
          householdId: hh,
          ingredientId: e.ingredient.id,
          quantity: e.item.quantity,
          unit: e.item.unit,
          expiryDate: expiry,
          addedAt: now,
          updatedAt: now,
        ));
        await (update(shoppingItems)..where((t) => t.id.equals(e.item.id)))
            .write(ShoppingItemsCompanion(
          checkedAt: Value(now),
          pantryItemId: Value(pantryId),
          updatedAt: Value(now),
        ));
        return expiry;
      }
      final pantryId = e.item.pantryItemId;
      if (pantryId != null) {
        // Sadece hâlâ dolapta duruyorsa geri al; tüketildiyse dokunma.
        await (update(pantryItems)
              ..where((t) => t.id.equals(pantryId) & t.outcome.isNull()))
            .write(PantryItemsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ));
      }
      await (update(shoppingItems)..where((t) => t.id.equals(e.item.id)))
          .write(ShoppingItemsCompanion(
        checkedAt: const Value(null),
        pantryItemId: const Value(null),
        updatedAt: Value(now),
      ));
      return null;
    });
  }

  Future<void> deleteShoppingItem(String id) {
    final now = DateTime.now();
    return (update(shoppingItems)..where((t) => t.id.equals(id))).write(
      ShoppingItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<void> clearCheckedShopping() {
    final now = DateTime.now();
    return (update(shoppingItems)
          ..where((t) => t.checkedAt.isNotNull() & t.deletedAt.isNull()))
        .write(ShoppingItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  // ------------------------------------------------------------ Yemek planı

  /// Tariflerin eksik malzemelerini listeye ekler; listede zaten alınmayı
  /// bekleyenleri atlar. Eklenen ürün sayısını döndürür.
  Future<int> addMissingToShopping(Iterable<Ingredient> missing) async {
    final hh = await householdId();
    return transaction(() async {
      final pending = (await (select(shoppingItems)
                ..where((t) => t.checkedAt.isNull() & t.deletedAt.isNull()))
              .get())
          .map((s) => s.ingredientId)
          .toSet();
      var added = 0;
      for (final i in missing) {
        if (!pending.add(i.id)) continue;
        final now = DateTime.now();
        await into(shoppingItems).insert(ShoppingItemsCompanion.insert(
          id: _uuid.v4(),
          householdId: hh,
          ingredientId: i.id,
          quantity: i.defaultQty,
          unit: i.unit,
          source: const Value('plan'),
          createdAt: now,
          updatedAt: now,
        ));
        added++;
      }
      return added;
    });
  }

  Stream<List<MealPlan>> watchMealPlans(DateTime from, DateTime to) {
    return (select(mealPlans)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.day.isBiggerOrEqualValue(dateOnly(from)) &
              t.day.isSmallerThanValue(dateOnly(to)))
          ..orderBy([
            (t) => OrderingTerm.asc(t.day),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  Future<void> addMealPlan(DateTime day, String recipeId) async {
    final hh = await householdId();
    final now = DateTime.now();
    await into(mealPlans).insert(MealPlansCompanion.insert(
      id: _uuid.v4(),
      householdId: hh,
      day: dateOnly(day),
      recipeId: recipeId,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> deleteMealPlan(String id) {
    final now = DateTime.now();
    return (update(mealPlans)..where((t) => t.id.equals(id))).write(
        MealPlansCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }
}
