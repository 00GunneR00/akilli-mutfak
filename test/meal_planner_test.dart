// Plan önerisinin diyetisyen kurallarına uyduğunu doğrular
// (.claude/skills/diyetisyen/SKILL.md).

import 'dart:math';

import 'package:akilli_mutfak/core/dates.dart';
import 'package:akilli_mutfak/data/database.dart';
import 'package:akilli_mutfak/data/recipe_catalog.dart';
import 'package:akilli_mutfak/features/recipes/meal_planner.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _centers = {DishRole.anaProtein, DishRole.baklagil, DishRole.anaTekTabak};

void main() {
  final today = dateOnly(DateTime.now());
  final days = [for (var d = 0; d < 7; d++) addDays(today, d)];

  test('her tarifin kalorisi ve etiketi var', () {
    for (final r in recipes) {
      expect(r.kcal, inInclusiveRange(50, 1200), reason: r.name);
      expect(r.tags, isNotNull, reason: '${r.name}: etiket yok');
      expect(r.tags!.base, isNotEmpty, reason: r.name);
      expect((r.tags!.role == DishRole.araOgun) == (r.tags!.snack != null),
          isTrue, reason: r.name);
    }
    expect(recipeTags.keys.toSet(), recipes.map((r) => r.name).toSet(),
        reason: 'etiketi olup tarifi olmayan isim');
  });

  group('diyetisyen kuralları', () {
    PlannedDish dish(String name, Meal meal) => PlannedDish(
        recipes.firstWhere((r) => r.name == name,
            orElse: () => throw ArgumentError(name)),
        meal);
    String? check(Meal meal, List<String> names, {bool weekend = false}) =>
        mealViolation([for (final n in names) dish(n, meal)], meal,
            weekend: weekend);

    test('kötü tabaklar elenir', () {
      // Kullanıcının bildirdiği öneri.
      expect(check(Meal.dinner, ['Tavuk Dürüm', 'Ev Yapımı Rus Salatası']), isNotNull);
      expect(check(Meal.lunch, ['Tavuk Dürüm', 'Ev Yapımı Rus Salatası']), isNotNull);
      // references/ornekler.md
      expect(check(Meal.dinner, ['Kıymalı Makarna', 'Pirinç Pilavı']), isNotNull);
      expect(check(Meal.dinner, ['Izgara Köfte', 'Tavuk Şiş']), isNotNull);
      expect(check(Meal.dinner, ['Mercimek Çorbası', 'Mercimek Köftesi', 'Izgara Köfte']),
          isNotNull);
      expect(check(Meal.dinner, ['Mantar Çorbası', 'Kremalı Mantarlı Tavuk']), isNotNull);
      expect(check(Meal.breakfast, ['Kaşarlı Tost', 'Pişi']), isNotNull);
      expect(check(Meal.dinner, ['Etli Patates Yemeği', 'Patates Salatası']), isNotNull);
      expect(check(Meal.dinner, ['Yoğurtlu Mantı', 'Cacık']), isNotNull);
      expect(check(Meal.breakfast, ['Karnıyarık']), isNotNull);
      expect(check(Meal.dinner, ['Çıtır Tavuk', 'Ev Yapımı Rus Salatası']), isNotNull);
      expect(check(Meal.lunch, ['Izgara Köfte', 'Piyaz']), isNotNull,
          reason: 'ağır meze yalnızca akşam');
      expect(check(Meal.afternoonSnack, ['Revani']), isNotNull);
      expect(check(Meal.dinner, ['Zeytinyağlı Pırasa', 'Çoban Salatası']), isNotNull,
          reason: 'etsiz sebze yemeği protein eşi olmadan');
    });

    test('Türk mutfağı adetleri (4A)', () {
      // Kullanıcının bildirdiği: emek isteyen yemek öğlede.
      expect(check(Meal.lunch, ['İmam Bayıldı']), isNotNull);
      expect(check(Meal.lunch, ['Etli Lahana Sarması', 'Cacık']), isNotNull);
      expect(check(Meal.dinner, ['Mercimek Çorbası', 'Izgara Köfte', 'İmam Bayıldı']),
          isNull);
      // Pratik yemekler öğle ve akşam olur.
      expect(check(Meal.lunch, ['Köri Soslu Tavuk', 'Pirinç Pilavı']), isNull);
      expect(check(Meal.dinner, ['Köri Soslu Tavuk', 'Pirinç Pilavı']), isNull);
      expect(check(Meal.lunch, ['Kıymalı Makarna', 'Çoban Salatası']), isNull);
      // Dünya mutfağının yanına Türk mezesi/yanı gelmez.
      expect(check(Meal.dinner, ['Köri Soslu Tavuk', 'Cacık']), isNotNull);
      expect(check(Meal.dinner, ['Köri Soslu Tavuk', 'Bulgur Pilavı']), isNotNull);
      expect(check(Meal.lunch, ['Spagetti Bolonez', 'Roka Salatası']), isNull);
    });

    test('kahvaltı Türk kahvaltısı düzeninde', () {
      // Kullanıcının bildirdiği uyumsuz kahvaltı.
      expect(check(Meal.breakfast, ['Yulaf Lapası', 'Peynirli Poğaça']), isNotNull);
      expect(check(Meal.breakfast, ['Yulaf Lapası']), isNull);
      expect(check(Meal.breakfast, ['Menemen']), isNotNull, reason: 'tabaksız');
      expect(check(Meal.breakfast, ['Kahvaltı Tabağı', 'Menemen']), isNull);
      expect(check(Meal.breakfast, ['Kahvaltı Tabağı', 'Susamlı Simit']), isNull);
      expect(check(Meal.breakfast, ['Kahvaltı Tabağı', 'Menemen', 'Peynirli Poğaça']),
          isNotNull, reason: 'hafta içi serpme yok');
      expect(
          check(Meal.breakfast, ['Kahvaltı Tabağı', 'Menemen', 'Peynirli Poğaça'],
              weekend: true),
          isNull);
      expect(check(Meal.breakfast, ['Kahvaltı Tabağı', 'Su Böreği']), isNotNull,
          reason: 'uzun hamur işi hafta sonu');
      expect(check(Meal.breakfast, ['Kahvaltı Tabağı', 'Su Böreği'], weekend: true),
          isNull);
      expect(check(Meal.breakfast, ['Kahvaltı Tabağı', 'Menemen', 'Sucuklu Yumurta'],
              weekend: true),
          isNotNull, reason: 'iki yumurtalı');
      expect(check(Meal.breakfast, ['Kaşarlı Tost']), isNull);
      expect(check(Meal.breakfast, ['Kaşarlı Tost', 'Kahvaltı Tabağı']), isNotNull);
    });

    test('iyi tabaklar geçer', () {
      expect(check(Meal.lunch, ['Tavuk Dürüm', 'Çoban Salatası']), isNull);
      expect(check(Meal.dinner, ['Mercimek Çorbası', 'Izgara Köfte', 'Bulgur Pilavı']),
          isNull);
      expect(check(Meal.dinner, ['Kuru Fasulye', 'Pirinç Pilavı', 'Cacık']), isNull);
      expect(check(Meal.dinner, ['Sebze Çorbası', 'Izgara Köfte', 'Piyaz']), isNull);
      expect(check(Meal.dinner, ['Fırında Levrek', 'Zeytinyağlı Pırasa', 'Çoban Salatası']),
          isNull);
      expect(check(Meal.dinner, ['Domates Çorbası', 'Yoğurtlu Mantı', 'Roka Salatası']),
          isNull);
      expect(check(Meal.dinner, ['Domates Çorbası', 'Yoğurtlu Mantı', 'Çoban Salatası']),
          isNotNull, reason: 'domates tekrarı');
      expect(check(Meal.breakfast, ['Kahvaltı Tabağı', 'Menemen']), isNull);
      expect(check(Meal.lunch, ['Mercimek Çorbası', 'Sezar Salata']), isNull);
      expect(check(Meal.afternoonSnack, ['Elma ve Badem']), isNull);
    });

    test('öğün dağılımında akşam en ağır', () {
      for (final n in [2, 3, 4, 5]) {
        for (final g in Goal.values) {
          for (final weekend in [false, true]) {
            final layout = mealLayout(n, g, weekend: weekend);
            expect(layout.fold(0.0, (s, e) => s + e.$2), closeTo(1, 1e-9));
            final dinner = layout.firstWhere((e) => e.$1 == Meal.dinner).$2;
            for (final (m, s) in layout) {
              expect(dinner, greaterThanOrEqualTo(s - 1e-9),
                  reason: '$n öğün, $g, hafta sonu: $weekend, $m');
            }
          }
          // Hafta sonu kahvaltı daha geniş.
          double breakfast(bool w) =>
              mealLayout(n, g, weekend: w).firstWhere((e) => e.$1 == Meal.breakfast).$2;
          expect(breakfast(true), greaterThanOrEqualTo(breakfast(false)));
        }
      }
    });
  });

  void expectValidWeek(List<PlannedDay> week, PlanOptions o) {
    final used = <String, int>{};
    String? prevDinner;
    for (final d in week) {
      expect(d.dishes, isNotEmpty, reason: '${d.day} boş');
      for (final meal in o.meals) {
        expect(mealViolation(d.of(meal), meal, weekend: isWeekend(d.day)), isNull,
            reason: '${meal.label}: ${d.of(meal).map((x) => x.recipe.name)}');
      }
      expect(dayViolation(d, o), isNull,
          reason: d.dishes.map((x) => x.recipe.name).join(', '));
      for (final x in d.dishes) {
        // Kural 10: kahvaltı tabağı her gün gelebilir.
        if (x.tags.breakfast != BreakfastKind.tabak) {
          used.update(x.recipe.id, (n) => n + 1, ifAbsent: () => 1);
        }
        if (o.vegetarian) expect(isVegetarian(x.recipe), isTrue);
        if (o.quick) {
          expect(x.recipe.minutes, lessThanOrEqualTo(PlanOptions.quickMinutes));
        }
      }
      final center =
          d.of(Meal.dinner).firstWhereOrNull((x) => _centers.contains(x.role));
      final group = center == null ? null : proteinGroup(center.tags);
      if (group != null) {
        expect(group, isNot(prevDinner), reason: 'ardışık akşam aynı protein');
      }
      prevDinner = group;
    }
    for (final MapEntry(key: id, value: n) in used.entries) {
      final r = recipesById[id]!;
      expect(n, lessThanOrEqualTo(_centers.contains(r.tags!.role) ? 1 : 2),
          reason: r.name);
    }
  }

  group('plan önerisi', () {
    const scenarios = <PlanOptions>[
      PlanOptions(),
      PlanOptions(dailyKcal: 1500, mealCount: 5, goal: Goal.lose),
      PlanOptions(dailyKcal: 2800, mealCount: 5, goal: Goal.gain),
      PlanOptions(dailyKcal: 2200, mealCount: 4, dessert: true),
      PlanOptions(dailyKcal: 1800, mealCount: 2),
      PlanOptions(vegetarian: true, mealCount: 4),
      PlanOptions(quick: true, dailyKcal: 1800),
    ];

    for (final o in scenarios) {
      test('kurallara uyar: ${o.toJson()}', () {
        for (var seed = 0; seed < 8; seed++) {
          final planner = MealPlanner(o);
          final week = planner.week(days, seed: seed);
          expectValidWeek(week, o);
          final avg = week.fold(0, (s, d) => s + d.kcal) / week.length;
          expect(avg, closeTo(o.dailyKcal, o.dailyKcal * .07),
              reason: 'seed $seed');
          if (!o.vegetarian && !o.quick) {
            expect(planner.balanceViolations(week), lessThanOrEqualTo(1),
                reason: 'seed $seed');
          }
        }
      });
    }

    test('haftalık denge: balık ve baklagil en az 2', () {
      for (var seed = 0; seed < 10; seed++) {
        final week = MealPlanner(const PlanOptions()).week(days, seed: seed);
        final groups = [
          for (final d in week)
            for (final x in d.dishes)
              if (_centers.contains(x.role)) proteinGroup(x.tags),
        ];
        expect(groups.where((g) => g == 'balik').length, greaterThanOrEqualTo(2));
        expect(groups.where((g) => g == 'baklagil').length, greaterThanOrEqualTo(2));
      }
    });

    test('ara öğünler hedefe uyar', () {
      final week = MealPlanner(
              const PlanOptions(dailyKcal: 1600, mealCount: 5, goal: Goal.lose))
          .week(days, seed: 3);
      final snacks = [for (final d in week) ...d.dishes.where((x) => x.meal.isSnack)];
      expect(snacks, hasLength(14));
      expect(snacks.every((x) => x.kcal <= 200 && !x.tags.proteinPowder), isTrue);
      expect(snacks.where((x) => x.tags.snack == SnackKind.shake).length,
          lessThanOrEqualTo(1));
    });

    test('yenile yalnızca o günü değiştirir, kurallar korunur', () {
      const o = PlanOptions(mealCount: 4);
      final planner = MealPlanner(o);
      final week = planner.week(days, seed: 5);
      final after = planner.reroll(week, 2, Random(9));
      for (final i in [0, 1, 3, 4, 5, 6]) {
        expect(identical(after[i], week[i]), isTrue);
      }
      expectValidWeek(after, o);
    });

    test('ayarlar saklanıp geri okunur', () {
      const o = PlanOptions(
          dailyKcal: 1800, mealCount: 5, goal: Goal.gain, vegetarian: true, dessert: true);
      final back = PlanOptions.fromJson(o.toJson());
      expect(back.dailyKcal, 1800);
      expect(back.mealCount, 5);
      expect(back.goal, Goal.gain);
      expect(back.vegetarian, isTrue);
      expect(back.dessert, isTrue);
      expect(PlanOptions.fromJson('bozuk').mealCount, 3);
      // Önceki sürümün kaydı (öğün sayısı yok) da okunur.
      expect(
          PlanOptions.fromJson('{"kcal":2000,"meals":["lunch"],"fridge":true,'
                  '"veg":false,"quick":false,"dessert":false}')
              .mealCount,
          3);
    });
  });

  test('öneri uygulanınca mevcut plan değişir, sıra ve porsiyon korunur', () async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(),
        closeStreamsSynchronously: true));
    addTearDown(db.close);
    await db.addMealPlan(today, 'rcp_karniyarik');
    await db.applyMealPlan({
      today: [
        (recipeId: 'rcp_menemen', meal: 'breakfast', servings: 1.5),
        (recipeId: 'rcp_tavuk_sote', meal: 'dinner', servings: 1.0),
      ],
    }, replace: true);
    final plans = await db.watchMealPlans(today, addDays(today, 1)).first;
    expect(plans.map((p) => p.recipeId), ['rcp_menemen', 'rcp_tavuk_sote']);
    expect(plans.first.meal, 'breakfast');
    expect(plans.first.servings, 1.5);
  });
}
