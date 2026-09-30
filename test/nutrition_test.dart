// Kaloriler tahmin değil hesaplanır: her tarifin porsiyon gramajı ve her
// malzemenin USDA değeri olmalı (.claude/skills/diyetisyen/SKILL.md).

import 'package:akilli_mutfak/data/ingredient_nutrition.g.dart';
import 'package:akilli_mutfak/data/recipe_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('her tarifin her malzemesinin gramajı var', () {
    for (final r in recipes) {
      final portion = recipePortions[r.name];
      expect(portion, isNotNull, reason: '${r.name}: porsiyon gramajı yok');
      expect(portion!.keys.toSet(), r.ingredients.toSet(),
          reason: '${r.name}: gramaj listesi malzemelerle aynı olmalı');
      for (final g in portion.values) {
        expect(g, greaterThan(0), reason: r.name);
      }
    }
    expect(recipePortions.keys.toSet(), recipes.map((r) => r.name).toSet());
  });

  test('her malzemenin USDA besin değeri var', () {
    for (final r in recipes) {
      for (final i in r.ingredients) {
        expect(ingredientNutrition, contains(i), reason: '${r.name}: $i');
      }
    }
  });

  test('kalori gramajlardan hesaplanır ve makrolarla tutarlıdır', () {
    for (final r in recipes) {
      final n = r.nutrients;
      expect(r.kcal, n.kcal.round());
      expect(r.kcal, inInclusiveRange(80, 800), reason: r.name);
      // Atwater: 4·P + 4·K + 9·Y enerjiye yakın olmalı. USDA bazı gıdalarda
      // (mantar, sebze) özel katsayı kullandığı için %15 pay bırakılır.
      final atwater = 4 * n.protein + 4 * n.carb + 9 * n.fat;
      expect(atwater, closeTo(n.kcal, n.kcal * .15), reason: r.name);
    }
  });

  test('örnek hesap: imam bayıldı', () {
    final r = recipes.firstWhere((r) => r.name == 'İmam Bayıldı');
    // 250 g patlıcan (25 kcal/100 g) + 20 g zeytinyağı (884 kcal/100 g) + …
    expect(ingredientNutrition['Zeytinyağı']!.kcal, 884);
    expect(r.kcal, inInclusiveRange(250, 350));
  });
}
