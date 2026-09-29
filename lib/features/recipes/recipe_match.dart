import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/text.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../data/recipe_catalog.dart';

/// Bir tarifin dolaptakilerle karşılaştırması.
class RecipeMatch {
  RecipeMatch(this.recipe, this.have, this.missing, this.staples);

  final Recipe recipe;
  final List<Ingredient> have;
  final List<Ingredient> missing;

  /// Evde olduğu varsayılan temel malzemeler (tuz, yağ, baharat…).
  final List<Ingredient> staples;

  int get required => have.length + missing.length;
  double get ratio => required == 0 ? 1 : have.length / required;
  bool get ready => missing.isEmpty;
}

/// Tarifleri dolaptakilere göre eşleştirir: önce eksiği en az olanlar.
List<RecipeMatch> matchRecipes(
  Iterable<Recipe> recipes,
  Map<String, Ingredient> catalog,
  Set<String> pantryIds,
) {
  final matches = <RecipeMatch>[];
  for (final r in recipes) {
    final have = <Ingredient>[], missing = <Ingredient>[], staples = <Ingredient>[];
    for (final name in r.ingredients) {
      final ing = catalog[slugId(name)];
      if (ing == null) continue;
      if (pantryIds.contains(ing.id)) {
        have.add(ing);
      } else if (pantryStaples.contains(name)) {
        staples.add(ing);
      } else {
        missing.add(ing);
      }
    }
    matches.add(RecipeMatch(r, have, missing, staples));
  }
  matches.sort((a, b) {
    final m = a.missing.length.compareTo(b.missing.length);
    if (m != 0) return m;
    final h = b.ratio.compareTo(a.ratio);
    return h != 0 ? h : a.recipe.name.compareTo(b.recipe.name);
  });
  return matches;
}

/// Tüm tariflerin eşleşmesi; dolap ya da katalog değişince yeniden hesaplanır.
final recipeMatchesProvider = Provider<List<RecipeMatch>?>((ref) {
  final ingredients = ref.watch(ingredientsProvider).value;
  final pantry = ref.watch(pantryProvider).value;
  if (ingredients == null || pantry == null) return null;
  return matchRecipes(
    recipes,
    {for (final i in ingredients) i.id: i},
    {for (final e in pantry) e.item.ingredientId},
  );
});

/// Bugünden başlayan 7 günlük plan.
final weekPlanProvider = StreamProvider<List<MealPlan>>((ref) {
  final today = dateOnly(DateTime.now());
  return ref
      .watch(databaseProvider)
      .watchMealPlans(today, addDays(today, 7));
});
