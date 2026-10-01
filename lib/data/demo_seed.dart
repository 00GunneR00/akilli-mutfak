// Tanıtım videosu için örnek hane verisi. Yalnızca `--dart-define=DEMO=true`
// ile açılan ayrı demo veritabanına yazılır; gerçek veriye ve sunucuya dokunmaz.

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/dates.dart';
import '../core/text.dart';
import 'database.dart';

const _uuid = Uuid();

/// (ürün, miktar, kaç gün önce alındı, azaldı mı)
const _pantry = <(String, double, int, bool)>[
  ('Tavuk Göğsü', 1, 1, false),
  ('Kıyma', 0.5, 1, false),
  ('Domates', 1.5, 2, false),
  ('Salatalık', 1, 2, false),
  ('Sivri Biber', 0.5, 2, false),
  ('Kapya Biber', 0.5, 2, false),
  ('Soğan', 2, 10, false),
  ('Patates', 2, 12, false),
  ('Havuç', 1, 6, false),
  ('Mantar', 1, 1, false),
  ('Limon', 4, 5, false),
  ('Maydanoz', 1, 2, false),
  ('Süt', 1, 3, true),
  ('Yoğurt', 1, 4, false),
  ('Beyaz Peynir', 1, 6, false),
  ('Kaşar Peyniri', 1, 8, false),
  ('Yumurta', 4, 6, true),
  ('Tereyağı', 1, 14, false),
  ('Zeytin', 1, 15, false),
  ('Ekmek', 1, 3, false),
  ('Kırmızı Mercimek', 1, 40, false),
  ('Pirinç', 2, 30, false),
  ('Bulgur', 1, 30, false),
  ('Tel Şehriye', 1, 30, false),
  ('Un', 2, 45, false),
  ('Domates Salçası', 1, 20, false),
  ('Makarna', 2, 25, false),
];

/// Alım alışkanlığı: "Genelde N günde bir alıyorsun" ipucu için eski alımlar.
const _history = <(String, List<int>)>[
  ('Ekmek', [15, 12, 9, 6]),
  ('Süt', [21, 15, 9]),
  ('Yumurta', [34, 20]),
];

/// Bu ay ve geçen ay dolaptan çıkanlar: (ürün, kaç gün önce, çöpe mi gitti)
const _removed = <(String, int, bool)>[
  ('Muz', 3, false), ('Elma', 4, false), ('Tavuk But', 5, false),
  ('Kırmızı Mercimek', 7, false), ('Beyaz Peynir', 8, false), ('Domates', 9, false),
  ('Salatalık', 10, false), ('Yoğurt', 11, false), ('Kıyma', 13, false),
  ('Patlıcan', 14, false), ('Portakal', 16, false), ('Makarna', 18, false),
  ('Ispanak', 12, true), ('Marul', 19, true),
  // Geçen ay
  ('Marul', 34, true), ('Ispanak', 36, true), ('Muz', 38, true),
  ('Ekmek', 40, true), ('Maydanoz', 42, true), ('Yoğurt', 45, true),
  ('Domates', 37, false), ('Süt', 41, false),
];

const _shopping = <(String, double)>[
  ('Patlıcan', 1),
  ('Muz', 1),
  ('Ayran', 4),
  ('Çilek', 1),
];

/// Demo veritabanını her açılışta sıfırlayıp doldurur; her çekim aynı
/// başlangıçtan başlar.
Future<void> seedDemo(AppDatabase db) async {
  await db.delete(db.shoppingItems).go();
  await db.delete(db.pantryItems).go();
  await db.delete(db.mealPlans).go();

  final catalog = {
    for (final i in await db.select(db.ingredients).get()) i.id: i,
  };
  Ingredient? ing(String name) => catalog[slugId(name)];

  final hh = await db.householdId();
  final now = DateTime.now();
  DateTime ago(int days) => addDays(now, -days)
      .add(Duration(hours: now.hour, minutes: now.minute));

  PantryItemsCompanion item(Ingredient i, double qty, DateTime added,
          {String status = StockStatus.ok,
          String? outcome,
          DateTime? removedAt}) =>
      PantryItemsCompanion.insert(
        id: _uuid.v4(),
        householdId: hh,
        ingredientId: i.id,
        quantity: qty,
        unit: i.unit,
        expiryDate: addDays(added, i.shelfDays),
        addedAt: added,
        status: Value(status),
        statusAt: Value(status == StockStatus.low ? ago(0) : null),
        outcome: Value(outcome),
        removedAt: Value(removedAt),
        updatedAt: now,
      );

  await db.batch((b) {
    for (final (name, qty, days, low) in _pantry) {
      final i = ing(name);
      if (i == null) continue;
      b.insert(db.pantryItems,
          item(i, qty, ago(days), status: low ? StockStatus.low : StockStatus.ok));
    }
    for (final (name, days) in _history) {
      final i = ing(name);
      if (i == null) continue;
      for (final d in days) {
        b.insert(db.pantryItems,
            item(i, i.defaultQty, ago(d),
                outcome: Outcome.consumed, removedAt: ago(d - 1)));
      }
    }
    for (final (name, days, wasted) in _removed) {
      final i = ing(name);
      if (i == null) continue;
      b.insert(db.pantryItems,
          item(i, i.defaultQty, ago(days + 5),
              outcome: wasted ? Outcome.wasted : Outcome.consumed,
              removedAt: ago(days)));
    }
    for (final (name, qty) in _shopping) {
      final i = ing(name);
      if (i == null) continue;
      b.insert(
          db.shoppingItems,
          ShoppingItemsCompanion.insert(
            id: _uuid.v4(),
            householdId: hh,
            ingredientId: i.id,
            quantity: qty,
            unit: i.unit,
            createdAt: now,
            updatedAt: now,
          ));
    }
  });
}

/// Demo verisinde katalogda bulunmayan ürün adları (test için).
Iterable<String> demoNames() => {
      for (final e in _pantry) e.$1,
      for (final e in _history) e.$1,
      for (final e in _removed) e.$1,
      for (final e in _shopping) e.$1,
    };
