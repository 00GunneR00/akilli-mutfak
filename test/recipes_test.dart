import 'package:akilli_mutfak/core/dates.dart';
import 'package:akilli_mutfak/core/text.dart';
import 'package:akilli_mutfak/data/database.dart';
import 'package:akilli_mutfak/data/recipe_catalog.dart';
import 'package:akilli_mutfak/data/seed_catalog.dart';
import 'package:akilli_mutfak/features/recipes/recipe_match.dart';
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

  Future<Map<String, Ingredient>> catalog() async =>
      {for (final i in await db.watchIngredients().first) i.id: i};

  test('tüm tarif malzemeleri katalogda var, kimlikler benzersiz', () {
    final names = seedIngredients.map((s) => s.name).toSet();
    for (final r in recipes) {
      for (final i in r.ingredients) {
        expect(names, contains(i), reason: '${r.name}: "$i" katalogda yok');
      }
      expect(recipeCategories.keys, contains(r.category), reason: r.name);
    }
    for (final s in pantryStaples) {
      expect(names, contains(s));
    }
    expect(recipes.map((r) => r.id).toSet(), hasLength(recipes.length));
    expect(recipeUrl(recipesById['rcp_karniyarik']!),
        'https://www.nefisyemektarifleri.com/ara/?s=Karn%C4%B1yar%C4%B1k');
  });

  test('eşleştirme: temel malzemeler eksik sayılmaz, eksiği az olan önde',
      () async {
    final cat = await catalog();
    final pantry = {slugId('Sucuk'), slugId('Yumurta'), slugId('Tereyağı')};
    final matches = matchRecipes(recipes, cat, pantry);

    final sucuklu = matches.firstWhere((m) => m.recipe.name == 'Sucuklu Yumurta');
    expect(sucuklu.ready, isTrue);
    expect(matches.first.ready, isTrue);

    final menemen = matches.firstWhere((m) => m.recipe.name == 'Menemen');
    expect(menemen.missing.map((i) => i.name), ['Domates', 'Sivri Biber']);
    expect(menemen.staples.map((i) => i.name), containsAll(['Pul Biber', 'Tuz']));
    expect(menemen.have, hasLength(2));
  });

  test('eksikler listeye bir kez eklenir', () async {
    final cat = await catalog();
    final missing = [cat[slugId('Domates')]!, cat[slugId('Sivri Biber')]!];

    expect(await db.addMissingToShopping(missing), 2);
    expect(await db.addMissingToShopping(missing), 0);
    final list = await db.watchShopping().first;
    expect(list, hasLength(2));
    expect(list.every((e) => e.item.source == 'plan'), isTrue);
  });

  test('yemek planı eklenir, silinir ve senkron kuyruğuna girer', () async {
    final today = dateOnly(DateTime.now());
    await db.addMealPlan(addDays(today, 1), 'rcp_menemen');
    var week = await db.watchMealPlans(today, addDays(today, 7)).first;
    expect(week.single.recipeId, 'rcp_menemen');
    expect(week.single.day, addDays(today, 1));

    final outbox = await db.select(db.syncOutbox).get();
    expect(outbox.map((e) => e.tbl), contains('meal_plans'));

    await db.deleteMealPlan(week.single.id);
    week = await db.watchMealPlans(today, addDays(today, 7)).first;
    expect(week, isEmpty);
  });
}
