// Haftalık plan önerisi.
//
// Kurallar diyetisyen skill'inden gelir:
// .claude/skills/diyetisyen/SKILL.md (bölüm numaraları yorumlarda geçer).
// Kesin kuralı bozan aday elenir; kalanlar puanlanır (küçük puan = iyi).

import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';

import '../../data/recipe_catalog.dart';
import '../../data/seed_catalog.dart';

enum Meal {
  breakfast('Kahvaltı', '☀️'),
  morningSnack('Kuşluk', '🍎'),
  lunch('Öğle', '🌤️'),
  afternoonSnack('İkindi', '🥤'),
  dinner('Akşam', '🌙');

  const Meal(this.label, this.emoji);
  final String label;
  final String emoji;

  bool get isSnack => this == morningSnack || this == afternoonSnack;

  Slot get slot => switch (this) {
        breakfast => Slot.kahvalti,
        lunch => Slot.ogle,
        dinner => Slot.aksam,
        _ => Slot.ara,
      };

  static Meal? byName(String? name) =>
      Meal.values.where((m) => m.name == name).firstOrNull;
}

enum Goal {
  lose('Kilo vermek'),
  maintain('Korumak'),
  gain('Kilo almak');

  const Goal(this.label);
  final String label;
}

bool isWeekend(DateTime d) =>
    d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

/// Öğün düzeni ve her öğünün günlük enerjideki payı (bölüm 2). Hafta sonu
/// kahvaltı geniş olur: öğleden (öğle yoksa akşamdan) 5 puan alır (4A).
List<(Meal, double)> mealLayout(int mealCount, Goal goal,
    {bool weekend = false}) {
  final layout = _baseLayout(mealCount, goal);
  if (!weekend) return layout;
  final share = {for (final (m, s) in layout) m: s};
  final from = share.containsKey(Meal.lunch) ? Meal.lunch : Meal.dinner;
  // Akşam hiçbir zaman kahvaltıdan hafif olmasın.
  final shift = from == Meal.dinner
      ? min(.05, (share[Meal.dinner]! - share[Meal.breakfast]!) / 2)
      : .05;
  return [
    for (final (m, s) in layout)
      (
        m,
        m == Meal.breakfast
            ? s + shift
            : m == from
                ? s - shift
                : s
      ),
  ];
}

List<(Meal, double)> _baseLayout(int mealCount, Goal goal) {
  final layout = switch (mealCount) {
    2 => [(Meal.breakfast, .45), (Meal.dinner, .55)],
    4 => [
        (Meal.breakfast, .22),
        (Meal.lunch, .28),
        (Meal.afternoonSnack, .10),
        (Meal.dinner, .40),
      ],
    5 => [
        (Meal.breakfast, .20),
        (Meal.morningSnack, .08),
        (Meal.lunch, .27),
        (Meal.afternoonSnack, .10),
        (Meal.dinner, .35),
      ],
    _ => [(Meal.breakfast, .25), (Meal.lunch, .32), (Meal.dinner, .43)],
  };
  if (goal != Goal.lose) return layout;
  // Kilo verirken akşamdan 5 puan kahvaltı/öğleye kayar.
  final hasLunch = layout.any((e) => e.$1 == Meal.lunch);
  return [
    for (final (m, s) in layout)
      (
        m,
        switch (m) {
          Meal.dinner => s - .05,
          Meal.breakfast => s + (hasLunch ? .025 : .05),
          Meal.lunch => s + .025,
          _ => s,
        }
      ),
  ];
}

/// Kullanıcının plan önerisi için seçtiği şartlar (bölüm 1).
class PlanOptions {
  const PlanOptions({
    this.dailyKcal = 2000,
    this.mealCount = 3,
    this.goal = Goal.maintain,
    this.useFridge = true,
    this.vegetarian = false,
    this.quick = false,
    this.dessert = false,
  });

  final int dailyKcal;
  final int mealCount;
  final Goal goal;
  final bool useFridge;
  final bool vegetarian;
  final bool quick;
  final bool dessert;

  static const minKcal = 1200;
  static const maxKcal = 3500;
  static const quickMinutes = 30;

  List<(Meal, double)> get layout => mealLayout(mealCount, goal);
  List<(Meal, double)> layoutFor(DateTime day) =>
      mealLayout(mealCount, goal, weekend: isWeekend(day));
  List<Meal> get meals => [for (final (m, _) in layout) m];

  PlanOptions copyWith({
    int? dailyKcal,
    int? mealCount,
    Goal? goal,
    bool? useFridge,
    bool? vegetarian,
    bool? quick,
    bool? dessert,
  }) =>
      PlanOptions(
        dailyKcal: dailyKcal ?? this.dailyKcal,
        mealCount: mealCount ?? this.mealCount,
        goal: goal ?? this.goal,
        useFridge: useFridge ?? this.useFridge,
        vegetarian: vegetarian ?? this.vegetarian,
        quick: quick ?? this.quick,
        dessert: dessert ?? this.dessert,
      );

  String toJson() => jsonEncode({
        'kcal': dailyKcal,
        'count': mealCount,
        'goal': goal.name,
        'fridge': useFridge,
        'veg': vegetarian,
        'quick': quick,
        'dessert': dessert,
      });

  static PlanOptions fromJson(String? s) {
    if (s == null) return const PlanOptions();
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      return PlanOptions(
        dailyKcal: (j['kcal'] as int).clamp(minKcal, maxKcal),
        mealCount: ((j['count'] as int?) ?? 3).clamp(2, 5),
        goal: Goal.values.firstWhere((g) => g.name == j['goal'],
            orElse: () => Goal.maintain),
        useFridge: j['fridge'] as bool,
        vegetarian: j['veg'] as bool,
        quick: j['quick'] as bool,
        dessert: j['dessert'] as bool,
      );
    } catch (_) {
      return const PlanOptions();
    }
  }
}

class PlannedDish {
  PlannedDish(this.recipe, this.meal, [this.servings = 1]);

  final Recipe recipe;
  final Meal meal;
  double servings;

  RecipeTags get tags => recipe.tags!;
  DishRole get role => tags.role;
  int get kcal => (recipe.kcal * servings).round();
}

class PlannedDay {
  PlannedDay(this.day, this.dishes);

  final DateTime day;
  final List<PlannedDish> dishes;

  int get kcal => dishes.fold(0, (s, d) => s + d.kcal);
  int kcalOf(Meal m) =>
      dishes.where((d) => d.meal == m).fold(0, (s, d) => s + d.kcal);
  List<PlannedDish> of(Meal m) => dishes.where((d) => d.meal == m).toList();
}

// ------------------------------------------------------------------ Yardımcı

const _meatCategory = 'Et, Tavuk & Balık';
const _otherMeats = {'Sucuk', 'Pastırma', 'Ton Balığı'};
final _ingredientCategory = {for (final s in seedIngredients) s.name: s.category};

/// Malzemelere bakar: et, tavuk, balık ya da işlenmiş et yok.
bool isVegetarian(Recipe r) => !r.ingredients.any(
    (n) => _ingredientCategory[n] == _meatCategory || _otherMeats.contains(n));

const _centerRoles = {DishRole.anaProtein, DishRole.baklagil, DishRole.anaTekTabak};
const _dough = {'hamur', 'makarna', 'ekmek'};

bool _isCenter(PlannedDish d) =>
    _centerRoles.contains(d.role) ||
    (d.meal == Meal.lunch && d.role == DishRole.kahvaltiYan);

/// Her gün tekrar edebilen sofra sabitleri (kural 10: kahvaltı tabağı).
bool _everyday(PlannedDish d) => d.tags.breakfast == BreakfastKind.tabak;

bool _isHeavyMeze(PlannedDish d) =>
    d.role == DishRole.yanSalata && d.tags.weight == Heft.agir;

const _meatProteins = {
  ProteinSource.kirmiziEt, ProteinSource.islenmisEt, ProteinSource.tavuk,
  ProteinSource.balik,
};

/// Planlanan protein grubuna uyuyor mu; 'etsiz' = kırmızı et ve tavuk dışı.
bool _inGroup(RecipeTags t, String? group) => switch (group) {
      null => true,
      'etsiz' => !{'et', 'tavuk'}.contains(proteinGroup(t)),
      _ => proteinGroup(t) == group,
    };

/// Haftalık denge ve ardışık gün kuralı için protein grubu (bölüm 5.11, 6).
String? proteinGroup(RecipeTags t) {
  if (t.role == DishRole.baklagil) return 'baklagil';
  return switch (t.protein) {
    ProteinSource.kirmiziEt || ProteinSource.islenmisEt => 'et',
    ProteinSource.tavuk => 'tavuk',
    ProteinSource.balik => 'balik',
    ProteinSource.baklagil => 'baklagil',
    _ => null,
  };
}

// ------------------------------------------------------------ Kesin kurallar

/// Öğle yemeği pratik olur; daha uzun sürenler akşam sofrasına (4A).
const lunchMaxMinutes = 45;

/// Hafta içi kahvaltıya yalnızca kısa sürede hazırlanan hamur işi (4).
const weekdayBakeMaxMinutes = 30;

/// Bir öğünün şablon ve kesin kural ihlali (bölüm 4, 4A ve 5); yoksa null.
String? mealViolation(List<PlannedDish> dishes, Meal meal,
    {bool weekend = false}) {
  if (dishes.isEmpty) return 'boş öğün';
  for (final d in dishes) {
    if (d.recipe.tags == null) return '${d.recipe.name}: etiket yok';
    final slotOk = d.role == DishRole.tatli
        ? !meal.isSnack && meal != Meal.breakfast
        : d.tags.meals.contains(meal.slot);
    if (!slotOk) return '${d.recipe.name} ${meal.label} öğününe uygun değil';
  }
  int count(bool Function(PlannedDish) f) => dishes.where(f).length;
  bool has(DishRole r) => dishes.any((d) => d.role == r);

  // Kural 5: aynı ana bileşen.
  final seen = <String>{};
  for (final d in dishes) {
    for (final b in d.tags.base) {
      if (!seen.add(b)) return 'ana bileşen tekrarı: $b';
    }
  }
  // Kural 7.
  if (count((d) => d.role == DishRole.corba) > 1) return 'iki çorba';
  if (count((d) => d.role == DishRole.tatli) > 1) return 'iki tatlı';

  if (meal.isSnack) {
    return dishes.length == 1 && dishes.single.role == DishRole.araOgun
        ? null
        : 'ara öğün tek bir ara öğün tarifi olmalı';
  }
  if (has(DishRole.araOgun)) return 'ara öğün tarifi ana öğünde';

  if (meal == Meal.breakfast) return _breakfastViolation(dishes, weekend);

  // 4A: öğle pratik olur.
  if (meal == Meal.lunch) {
    for (final d in dishes) {
      if (d.role != DishRole.tatli && d.recipe.minutes > lunchMaxMinutes) {
        return '${d.recipe.name} emek ister, akşam sofrasına';
      }
    }
  }

  final centers = dishes.where(_isCenter).toList();
  if (centers.length > 1) return 'iki protein merkezi'; // kural 1
  final center = centers.firstOrNull;
  final sebze = dishes.where((d) => d.role == DishRole.sebzeYemegi).toList();
  final sides = dishes.where((d) =>
      d.role == DishRole.yanSalata || d.role == DishRole.yanYogurt).toList();
  final tahil = dishes.where((d) => d.role == DishRole.yanTahil).toList();
  final dessert = dishes.where((d) => d.role == DishRole.tatli).firstOrNull;
  if (sebze.length > 1 || tahil.length > 1) return 'aynı türden iki yan';
  if (sides.length > 1) return 'iki salata/yoğurt'; // kural 7
  if ((center != null || sebze.isNotEmpty) &&
      sides.any((d) => _meatProteins.contains(d.tags.protein))) {
    return 'yemeğin yanına etli/balıklı salata'; // kural 7
  }

  final tekTabak = center != null && center.role != DishRole.anaProtein &&
      center.role != DishRole.baklagil;
  // Kural 2.
  if (tekTabak && tahil.isNotEmpty) return 'tek tabak + pilav';
  // Tek tabağın yanına (öğle ya da akşam) yalnızca hafif salata/yoğurt.
  if (tekTabak && sides.any((d) => d.tags.weight != Heft.hafif)) {
    return 'tek tabak yanına hafif salata';
  }
  if (center != null && center.tags.base.any(_dough.contains) &&
      dishes.any((d) => d != center && d.tags.base.any(_dough.contains))) {
    return 'hamur/ekmek üst üste';
  }
  // Kural 3.
  final heavy = dishes.where(_isHeavyMeze).toList();
  if (heavy.isNotEmpty) {
    if (meal != Meal.dinner) return 'ağır meze yalnızca akşam';
    final main = center ?? sebze.firstOrNull;
    if (main != null &&
        (main.tags.weight == Heft.agir || main.tags.cooking == Cooking.kizartma)) {
      return 'ağır meze + ağır/kızartma ana yemek';
    }
  }
  // Kural 4.
  if (center != null && center.tags.fastfood) {
    for (final d in dishes) {
      if (d == center) continue;
      final light = d.role == DishRole.yanYogurt ||
          (d.role == DishRole.yanSalata && d.tags.weight == Heft.hafif);
      if (!light) return 'fast-food yanına yalnızca hafif salata/yoğurt';
    }
  }
  // Kural 9a: dünya mutfağı yemeğinin yanına Türk mezesi/yanı gelmez.
  final lead = center ?? sebze.firstOrNull;
  if (lead != null && lead.tags.world) {
    for (final d in dishes) {
      if (d == lead || d.role == DishRole.corba || d.role == DishRole.tatli) {
        continue;
      }
      if (!d.tags.worldOk) return '${lead.recipe.name} yanına ${d.recipe.name} uymaz';
    }
  }
  // Kural 6.
  final creamySoup =
      dishes.any((d) => d.role == DishRole.corba && d.tags.creamy);
  if (creamySoup &&
      dishes.any((d) => d.role != DishRole.corba &&
          d.role != DishRole.tatli && d.tags.creamy)) {
    return 'kremalı + kremalı';
  }
  // Tatlı: ağır öğüne konmaz.
  if (dessert != null) {
    final main = center ?? sebze.firstOrNull;
    if (main == null || main.tags.weight == Heft.agir) return 'ağır öğüne tatlı';
  }

  final plates = dishes.length - (dessert == null ? 0 : 1);
  final hasSoup = has(DishRole.corba);
  if (meal == Meal.lunch) {
    if (plates > 3) return 'öğlede en fazla 3 tabak';
    if (tekTabak) {
      // Şablon 1: tek tabak + en fazla 1 hafif yan.
      if (hasSoup || sebze.isNotEmpty) return 'tek tabak şablonu';
      return null;
    }
    if (center != null || sebze.isNotEmpty) {
      // Şablon 2: [çorba] + yemek + en fazla 1 yan.
      if (center != null && sebze.isNotEmpty) return 'öğlede tek yemek';
      if (tahil.length + sides.length > 1) return 'öğlede en fazla 1 yan';
      return null;
    }
    // Şablon 3: çorba + doyurucu salata.
    if (hasSoup && sides.length == 1 && tahil.isEmpty &&
        sides.single.role == DishRole.yanSalata &&
        sides.single.tags.weight == Heft.orta) {
      return null;
    }
    return 'öğle şablonu';
  }

  // Akşam.
  if (plates < 2 || plates > 4) return 'akşamda 2–4 tabak';
  if (center == null) {
    // Etsiz sebze yemeği ancak yoğurt/yumurta/peynirle protein merkezi olur.
    if (sebze.isEmpty) return 'akşamda protein merkezi yok';
    final protein = sebze.single.tags.protein != ProteinSource.yok ||
        sides.any((d) => d.role == DishRole.yanYogurt);
    if (!protein) return 'sebze yemeği protein eşi olmadan';
    if (tahil.isNotEmpty) return 'sebze merkezli akşama pilav';
    return null;
  }
  if (sebze.isNotEmpty) {
    if (center.role != DishRole.anaProtein) return 'sebze ikinci yemek yalnızca et/tavuk/balıkla';
    if (tahil.isNotEmpty) return 'ikinci yemek + pilav';
  }
  return null;
}

/// Kahvaltı düzenleri (bölüm 4): Türk kahvaltısı (kahvaltı tabağı + sıcak ya
/// da hamur işi; hafta sonu ikisi birden), tek başına pratik ya da batı tarzı.
String? _breakfastViolation(List<PlannedDish> dishes, bool weekend) {
  final kinds = [for (final d in dishes) d.tags.breakfast];
  if (kinds.contains(null)) return 'kahvaltılık olmayan tabak';
  int n(BreakfastKind k) => kinds.where((x) => x == k).length;
  if (n(BreakfastKind.bati) + n(BreakfastKind.pratik) > 0) {
    return dishes.length == 1 ? null : 'batı/pratik kahvaltı tek başına gelir';
  }
  if (n(BreakfastKind.tabak) != 1) return 'Türk kahvaltısında kahvaltı tabağı yok';
  if (n(BreakfastKind.sicak) > 1 || n(BreakfastKind.hamur) > 1) {
    return 'kahvaltıda iki sıcak ya da iki hamur işi';
  }
  if (dishes.length > (weekend ? 3 : 2)) {
    return 'hafta içi kahvaltı: tabak + sıcak ya da hamur işi';
  }
  if (!weekend &&
      dishes.any((d) =>
          d.tags.breakfast == BreakfastKind.hamur &&
          d.recipe.minutes > weekdayBakeMaxMinutes)) {
    return 'uzun hamur işi hafta sonuna';
  }
  return null;
}

/// Gün içi kurallar: kızartma (5.8), ara öğün türleri, hedefe göre sınırlar.
String? dayViolation(PlannedDay day, PlanOptions o) {
  if (day.dishes.where((d) => d.tags.cooking == Cooking.kizartma).length > 1) {
    return 'günde birden fazla kızartma';
  }
  // 4A: dünya mutfağı aynı gün hem öğle hem akşam olmaz.
  bool worldMeal(Meal m) =>
      day.of(m).any((d) => d.tags.world && d.role != DishRole.corba);
  if (worldMeal(Meal.lunch) && worldMeal(Meal.dinner)) {
    return 'öğle ve akşam ikisi de dünya mutfağı';
  }
  final snacks = day.dishes.where((d) => d.meal.isSnack).toList();
  final kinds = snacks.map((d) => d.tags.snack).toList();
  if (kinds.toSet().length < kinds.length) return 'aynı türden iki ara öğün';
  for (final s in snacks) {
    if (s.meal == Meal.morningSnack &&
        !_morningKinds.contains(s.tags.snack)) {
      return 'kuşluğa ağır ara öğün';
    }
    if (s.tags.proteinPowder && o.goal != Goal.gain) {
      return 'protein tozu yalnızca kilo almada';
    }
    if (o.goal == Goal.lose && s.kcal > 200) return 'kilo verirken ara öğün > 200';
  }
  if (o.mealCount == 5 && !snacks.any((d) => _freshKinds.contains(d.tags.snack))) {
    return 'meyve/sebze ara öğünü yok';
  }
  for (final d in day.dishes) {
    if (d.role == DishRole.tatli && d.kcal > o.dailyKcal * .1) {
      return 'tatlı günlük enerjinin %10\'undan fazla';
    }
  }
  return null;
}

const _morningKinds = {
  SnackKind.meyve, SnackKind.yogurt, SnackKind.smoothie, SnackKind.sebze,
};
const _freshKinds = {SnackKind.meyve, SnackKind.smoothie, SnackKind.sebze};

// ------------------------------------------------------------------ Planlayıcı

/// Hafta boyunca biriken kullanımlar (kural 10 ve haftalık sınırlar).
class _WeekState {
  final used = <String, int>{};
  var shakes = 0;
  var desserts = 0;
  var heavyDesserts = 0;

  var westernBreakfasts = 0;

  void add(PlannedDay d) {
    for (final x in d.dishes) {
      used.update(x.recipe.id, (n) => n + 1, ifAbsent: () => 1);
      if (x.tags.snack == SnackKind.shake) shakes++;
      if (x.tags.breakfast == BreakfastKind.bati) westernBreakfasts++;
      if (x.role == DishRole.tatli) {
        desserts++;
        if (x.tags.weight == Heft.agir) heavyDesserts++;
      }
    }
  }

}

class MealPlanner {
  MealPlanner(
    this.options, {
    Iterable<Recipe>? catalog,
    this.fridgeRatio = const {},
  }) {
    for (final r in catalog ?? recipes) {
      final t = r.tags;
      if (t == null || r.kcal <= 0) continue;
      if (options.vegetarian && !isVegetarian(r)) continue;
      if (options.quick && r.minutes > PlanOptions.quickMinutes) continue;
      if (t.proteinPowder && options.goal != Goal.gain) continue;
      if (options.goal == Goal.lose && t.role == DishRole.araOgun) {
        if (r.kcal * .75 > 200) continue;
        if (t.snack == SnackKind.shake && r.kcal > 250) continue;
      }
      _all.add(r);
    }
  }

  final PlanOptions options;

  /// Tarif kimliği → dolapta bulunan malzeme oranı (0–1).
  final Map<String, double> fridgeRatio;

  final _all = <Recipe>[];

  static const _attempts = 6;
  static const _tries = 160;
  static const _portionSteps = [.75, 1.0, 1.25, 1.5];
  static const _sideSteps = [.75, 1.0, 1.25];

  int get _shakeCap => switch (options.goal) {
        Goal.lose => 1,
        Goal.maintain => 3,
        Goal.gain => 7,
      };

  final _pools = <String, List<Recipe>>{};

  /// [key] filtreyi benzersiz adlandırır; havuz bir kez hesaplanır (öneri
  /// her gün için yüzlerce aday ürettiği için).
  List<Recipe> _pool(String key, bool Function(RecipeTags t) test,
          {int? maxMinutes}) =>
      _pools.putIfAbsent(
          key,
          () => _all
              .where((r) =>
                  test(r.tags!) && (maxMinutes == null || r.minutes <= maxMinutes))
              .toList());

  List<PlannedDay> week(List<DateTime> days, {int seed = 0}) {
    final rng = Random(seed);
    List<PlannedDay>? best;
    var bestScore = double.infinity;
    for (var a = 0; a < _attempts; a++) {
      final groups = _dinnerGroups(days.length, rng);
      final lunchGroups = _lunchGroups(groups, rng);
      final dessertDays = _dessertDays(days.length, rng);
      final state = _WeekState();
      final built = <PlannedDay>[];
      for (final (i, date) in days.indexed) {
        final prev = i == 0 ? null : _dinnerGroup(built[i - 1]);
        final day = _bestDay(date, rng,
                state: state,
                dinnerGroup: groups[i],
                lunchGroup: lunchGroups[i],
                dessert: dessertDays.contains(i),
                neighbours: {?prev},
                week: built) ??
            _bestDay(date, rng,
                state: state, neighbours: {?prev}, week: built) ??
            PlannedDay(date, []);
        state.add(day);
        built.add(day);
      }
      final score = weekScore(built);
      if (score < bestScore) {
        bestScore = score;
        best = built;
      }
    }
    return best!;
  }

  /// Tek günü yeniden kurar; haftanın diğer günleri ve dengesi korunur.
  List<PlannedDay> reroll(List<PlannedDay> week, int index, Random rng) {
    final state = _WeekState();
    for (final (i, d) in week.indexed) {
      if (i != index) state.add(d);
    }
    // Aynı günün eski seçimleri tekrar gelmesin.
    for (final d in week[index].dishes) {
      state.used.update(d.recipe.id, (n) => n + 1, ifAbsent: () => 1);
    }
    final old = week[index];
    final neighbours = {
      if (index > 0) ?_dinnerGroup(week[index - 1]),
      if (index < week.length - 1) ?_dinnerGroup(week[index + 1]),
    };
    final others = [...week]..removeAt(index);
    final dessert = old.dishes.any((d) => d.role == DishRole.tatli);
    final day = _bestDay(old.day, rng,
            state: state,
            dinnerGroup: _dinnerGroup(old),
            lunchGroup: switch (_groupOf(old, Meal.lunch)) {
              final g? when g == 'et' || g == 'tavuk' => g,
              _ => options.vegetarian ? null : 'etsiz',
            },
            dessert: dessert,
            neighbours: neighbours,
            week: others,
            tries: _tries * 2) ??
        _bestDay(old.day, rng,
            state: state,
            dessert: dessert,
            neighbours: neighbours,
            week: others,
            tries: _tries * 2) ??
        old;
    return [...week]..[index] = day;
  }

  // Bölüm 8: önce akşam protein merkezleri haftaya dağıtılır.
  List<String?> _dinnerGroups(int n, Random rng) {
    if (!options.meals.contains(Meal.dinner)) return List.filled(n, null);
    final base = options.vegetarian
        ? ['baklagil', 'baklagil', 'baklagil', 'baklagil', null, null, null]
        : ['balik', 'baklagil', 'et', 'tavuk', 'balik', 'baklagil', 'et'];
    final wanted = [for (var i = 0; i < n; i++) base[i % base.length]];
    for (var t = 0; t < 40; t++) {
      wanted.shuffle(rng);
      var ok = true;
      for (var i = 1; i < n; i++) {
        if (wanted[i] != null && wanted[i] == wanted[i - 1]) ok = false;
      }
      if (ok) break;
    }
    return wanted;
  }

  Set<int> _dessertDays(int n, Random rng) {
    if (!options.dessert) return const {};
    final all = [for (var i = 0; i < n; i++) i]..shuffle(rng);
    return all.take(min(3, n)).toSet();
  }

  /// Öğle protein planı (bölüm 8): haftada 1 tavuk, 1 kırmızı et, kalanı
  /// etsiz. Pratik öğle yemeklerinin çoğu kıymalı olduğundan plan yapılmazsa
  /// kırmızı et sınırı aşılır. Aynı günün akşamıyla çakışmaz.
  List<String?> _lunchGroups(List<String?> dinnerGroups, Random rng) {
    final n = dinnerGroups.length;
    if (options.vegetarian || !options.meals.contains(Meal.lunch)) {
      return List.filled(n, null);
    }
    final groups = List<String?>.filled(n, 'etsiz');
    for (final g in ['tavuk', 'et']) {
      final days = [
        for (var i = 0; i < n; i++)
          if (groups[i] == 'etsiz' && dinnerGroups[i] != g) i,
      ];
      if (days.isNotEmpty) groups[days[rng.nextInt(days.length)]] = g;
    }
    return groups;
  }

  String? _groupOf(PlannedDay d, Meal meal) {
    final center = d.of(meal).where(_isCenter).firstOrNull;
    return center == null ? null : proteinGroup(center.tags);
  }

  String? _dinnerGroup(PlannedDay d) => _groupOf(d, Meal.dinner);

  PlannedDay? _bestDay(
    DateTime date,
    Random rng, {
    required _WeekState state,
    String? dinnerGroup,
    String? lunchGroup,
    bool dessert = false,
    Set<String> neighbours = const {},
    required List<PlannedDay> week,
    int tries = _tries,
  }) {
    PlannedDay? best;
    var bestScore = double.infinity;
    for (var i = 0; i < tries; i++) {
      final day = _candidate(date, rng, dinnerGroup, lunchGroup, dessert);
      if (day == null) continue;
      if (!_weekOk(day, state, neighbours)) continue;
      final score = dayScore(day) + _balanceDelta(week, day);
      if (score < bestScore) {
        bestScore = score;
        best = day;
      }
    }
    return best;
  }

  /// Haftalık kesin kurallar (10–11) ve sınırlar.
  bool _weekOk(PlannedDay day, _WeekState state, Set<String> neighbours) {
    var shakes = state.shakes;
    final today = <String, int>{};
    for (final d in day.dishes) {
      if (_everyday(d)) continue;
      // Aynı gün farklı öğünlerdeki tekrar da sayılır.
      final n = today.update(d.recipe.id, (n) => n + 1, ifAbsent: () => 1);
      final used = (state.used[d.recipe.id] ?? 0) + n - 1;
      final cap = _isCenter(d) || _centerRoles.contains(d.role) ? 1 : 2;
      if (used >= cap) return false;
      if (d.tags.snack == SnackKind.shake && ++shakes > _shakeCap) return false;
      if (d.tags.breakfast == BreakfastKind.bati && state.westernBreakfasts >= 2) {
        return false;
      }
      if (d.role == DishRole.tatli) {
        if (state.desserts >= 3) return false;
        if (d.tags.weight == Heft.agir && state.heavyDesserts >= 1) return false;
      }
    }
    final group = _dinnerGroup(day);
    return group == null || !neighbours.contains(group);
  }

  PlannedDay? _candidate(DateTime date, Random rng, String? dinnerGroup,
      String? lunchGroup, bool dessert) {
    final day = PlannedDay(date, []);
    final weekend = isWeekend(date);
    final layout = options.layoutFor(date);
    for (final (meal, share) in layout) {
      final budget = share * options.dailyKcal;
      final dishes = switch (meal) {
        Meal.breakfast => _breakfast(rng, weekend, budget),
        Meal.lunch => _lunch(rng, lunchGroup, budget),
        Meal.dinner => _dinner(rng, dinnerGroup, budget),
        _ => _snack(meal, rng),
      };
      if (dishes == null) return null;
      day.dishes.addAll(dishes);
    }
    if (dessert) _addDessert(day, rng);
    for (final (meal, _) in layout) {
      if (mealViolation(day.of(meal), meal, weekend: weekend) != null) {
        return null;
      }
    }
    _portion(day);
    if (dayViolation(day, options) != null) return null;
    return day;
  }

  Recipe? _pick(List<Recipe> pool, Random rng) =>
      pool.isEmpty ? null : pool[rng.nextInt(pool.length)];

  /// Çoğunlukla Türk kahvaltısı; hafta içi bazen pratik ya da batı tarzı,
  /// hafta sonu serpme (tabak + sıcak + hamur işi).
  List<PlannedDish>? _breakfast(Random rng, bool weekend, double budget) {
    Recipe? pick(BreakfastKind kind, {bool short = false}) => _pick(
        _pool('kahvalti:${kind.name}:$short', (t) => t.breakfast == kind,
            maxMinutes: short ? weekdayBakeMaxMinutes : null),
        rng);
    final plate = _Plate(Meal.breakfast, budget);

    final roll = rng.nextDouble();
    if (roll < (weekend ? .1 : .15)) {
      plate.addMain(pick(BreakfastKind.bati));
    } else if (!weekend && roll < .35) {
      plate.addMain(pick(BreakfastKind.pratik));
    } else {
      plate.addMain(pick(BreakfastKind.tabak));
      final extra = rng.nextDouble();
      if (weekend) {
        if (extra < .85) plate.addIfFits(pick(BreakfastKind.sicak));
        if (extra > .25) plate.addIfFits(pick(BreakfastKind.hamur));
      } else if (extra < .6) {
        plate.addIfFits(pick(BreakfastKind.sicak));
      } else if (extra < .9) {
        plate.addIfFits(pick(BreakfastKind.hamur, short: true));
      }
    }
    return plate.dishes.isEmpty ? null : plate.dishes;
  }

  List<PlannedDish>? _snack(Meal meal, Random rng) {
    final r = _pick(
        _pool('ara:${meal.name}', (t) =>
            t.role == DishRole.araOgun &&
            (meal != Meal.morningSnack || _morningKinds.contains(t.snack))),
        rng);
    return r == null ? null : [PlannedDish(r, meal)];
  }

  List<PlannedDish>? _lunch(Random rng, String? group, double budget) {
    // Grup verilmişse (öğle protein planı) öğlenin ana yemeği o gruptan olur.
    bool ogle(RecipeTags t) =>
        t.meals.contains(Slot.ogle) &&
        (!{DishRole.anaProtein, DishRole.baklagil, DishRole.anaTekTabak,
                    DishRole.kahvaltiYan, DishRole.sebzeYemegi}
                .contains(t.role) ||
            _inGroup(t, group));
    Recipe? pick(String key, bool Function(RecipeTags t) f) => _pick(
        _pool('ogle:$group:$key', (t) => f(t) && ogle(t),
            maxMinutes: lunchMaxMinutes),
        rng);
    final plate = _Plate(Meal.lunch, budget);

    final roll = rng.nextDouble();
    if (roll < .1 && group != 'et' && group != 'tavuk' && budget <= 500) {
      // Şablon 3: çorba + doyurucu salata.
      plate.addMain(pick('corba', (t) => t.role == DishRole.corba));
      plate.add(pick('salataOrta',
          (t) => t.role == DishRole.yanSalata && t.weight == Heft.orta));
    } else if (roll < .5) {
      // Şablon 1: tek tabak (+ hafif yan).
      plate.addMain(pick('tek', (t) =>
          t.role == DishRole.anaTekTabak || t.role == DishRole.kahvaltiYan));
      if (rng.nextDouble() < .7) {
        plate.addIfFits(pick('hafifYan', (t) =>
            t.role == DishRole.yanYogurt ||
            (t.role == DishRole.yanSalata && t.weight == Heft.hafif)));
      }
    } else {
      // Şablon 2: [çorba] + ev yemeği + en fazla 1 yan.
      plate.addMain(pick('ev', (t) =>
          {DishRole.anaProtein, DishRole.baklagil, DishRole.sebzeYemegi}
              .contains(t.role)));
      if (rng.nextDouble() < .8) {
        plate.addIfFits(pick('yan', (t) =>
            {DishRole.yanTahil, DishRole.yanSalata, DishRole.yanYogurt}
                .contains(t.role) &&
            t.weight != Heft.agir));
      }
      if (rng.nextDouble() < .4) {
        plate.addIfFits(pick('corba', (t) => t.role == DishRole.corba));
      }
    }
    return plate.dishes.isEmpty ? null : plate.sorted();
  }

  List<PlannedDish>? _dinner(Random rng, String? group, double budget) {
    Recipe? pick(String key, bool Function(RecipeTags t) f) => _pick(
        _pool('aksam:$key', (t) => f(t) && t.meals.contains(Slot.aksam)), rng);
    final plate = _Plate(Meal.dinner, budget);

    // Vejetaryende grupsuz akşamlar sebze yemeği + yoğurtla da kurulabilir.
    final vegDish = options.vegetarian && group == null && rng.nextDouble() < .35;
    // Akşam sofrası çoğunlukla ev yemeğidir; tek tabak (makarna, mantı…) ara
    // sıra (4A).
    Recipe? home() => pick('ev:$group', (t) =>
        (t.role == DishRole.anaProtein || t.role == DishRole.baklagil) &&
        _inGroup(t, group));
    Recipe? single() => pick('tek:$group',
        (t) => t.role == DishRole.anaTekTabak && _inGroup(t, group));
    final center = vegDish
        ? pick('sebze', (t) => t.role == DishRole.sebzeYemegi)
        : rng.nextDouble() < .2
            ? single() ?? home()
            : home() ?? single();
    if (center == null) return null;
    plate.addMain(center);
    final role = center.tags!.role;

    if (vegDish) {
      plate.add(pick('yogurt', (t) => t.role == DishRole.yanYogurt));
      return plate.sorted();
    }
    // Eklemeler rastgele sırayla, bütçeye sığdıkça (bölüm 3).
    final soupChance = options.mealCount >= 3 ? .85 : .6;
    final extras = <Recipe? Function()>[
      if (rng.nextDouble() < soupChance)
        () => pick('corba', (t) => t.role == DishRole.corba),
      if (role == DishRole.anaProtein && rng.nextDouble() < .3)
        () => pick('sebze', (t) => t.role == DishRole.sebzeYemegi)
      else if (role != DishRole.anaTekTabak &&
          rng.nextDouble() < (role == DishRole.baklagil ? .65 : .55))
        () => pick('tahil', (t) => t.role == DishRole.yanTahil),
      if (rng.nextDouble() < .8)
        () => pick('salata', (t) =>
            t.role == DishRole.yanSalata || t.role == DishRole.yanYogurt),
    ]..shuffle(rng);
    for (final e in extras) {
      plate.addIfFits(e());
    }
    // Akşam en az iki tabaktır: sığmadıysa hafif bir salata ya da yoğurt.
    if (plate.dishes.length < 2) {
      plate.add(pick('hafif', (t) =>
          (t.role == DishRole.yanSalata || t.role == DishRole.yanYogurt) &&
          t.weight == Heft.hafif));
    }
    return plate.sorted();
  }

  void _addDessert(PlannedDay day, Random rng) {
    final r = _pick(_pool('tatli', (t) => t.role == DishRole.tatli), rng);
    if (r == null) return;
    // Akşam ağırsa öğleye; o da ağırsa o gün tatlı yok.
    for (final meal in [Meal.dinner, Meal.lunch]) {
      final main = day.of(meal).where((d) =>
          _isCenter(d) || d.role == DishRole.sebzeYemegi).firstOrNull;
      if (main != null && main.tags.weight != Heft.agir) {
        day.dishes.add(PlannedDish(r, meal));
        return;
      }
    }
  }

  /// Bölüm 3: önce ana tabak porsiyonu, gerekirse bir yan tabak ayarlanır.
  void _portion(PlannedDay day) {
    final target = options.dailyKcal;
    for (final (meal, share) in options.layoutFor(day.day)) {
      final dishes = day.of(meal);
      final mealTarget = target * share;
      final dessert =
          dishes.where((d) => d.role == DishRole.tatli).firstOrNull;
      if (dessert != null) {
        if (dessert.recipe.kcal > target * .1) dessert.servings = .5;
        if (dessert.kcal > target * .1) day.dishes.remove(dessert);
      }
      final main = dishes.firstWhereOrNull((d) =>
              meal.isSnack ||
              d.role == DishRole.kahvaltiAna ||
              _isCenter(d)) ??
          dishes.firstWhereOrNull((d) => d.role == DishRole.sebzeYemegi);
      if (main == null) continue;
      final side = dishes.firstWhereOrNull((d) =>
          d != main &&
          {DishRole.corba, DishRole.yanTahil, DishRole.yanSalata,
            DishRole.kahvaltiYan, DishRole.kahvaltiAna}
              .contains(d.role));
      final rest = day.of(meal).where((d) => d != main && d != side)
          .fold(0, (s, d) => s + d.kcal);
      var bestErr = double.infinity;
      var bestMain = 1.0, bestSide = 1.0;
      for (final ms in _portionSteps) {
        for (final ss in side == null ? const [1.0] : _sideSteps) {
          final kcal = rest +
              main.recipe.kcal * ms +
              (side == null ? 0 : side.recipe.kcal * ss);
          final err = (kcal - mealTarget).abs() / mealTarget +
              (ms == 1 ? 0 : .02) +
              (ss == 1 ? 0 : .02);
          if (err < bestErr) {
            bestErr = err;
            bestMain = ms;
            bestSide = ss;
          }
        }
      }
      main.servings = bestMain;
      side?.servings = bestSide;
    }
  }

  // ------------------------------------------------------------------ Puanlar

  /// Bölüm 8: günün puanı (küçük = iyi).
  double dayScore(PlannedDay day) {
    final target = options.dailyKcal;
    final lose = options.goal == Goal.lose;
    var score = 3 * (day.kcal - target).abs() / target;
    final mealKcal = <Meal, int>{};
    for (final (meal, share) in options.layoutFor(day.day)) {
      final kcal = mealKcal[meal] = day.kcalOf(meal);
      final t = target * share;
      score += 2 * max(0, (kcal - t).abs() / t - .15);
    }
    score += .075 * day.dishes.where((d) => d.servings != 1).length;

    // Akşam en doyurucu; hafta içi öğle kahvaltıdan ağır (9.3, 4A hafta sonu).
    final b = mealKcal[Meal.breakfast] ?? 0,
        l = mealKcal[Meal.lunch] ?? 0,
        d = mealKcal[Meal.dinner] ?? 0;
    if (d < l || d < b) score += .3;
    if (!isWeekend(day.day) && mealKcal.containsKey(Meal.lunch) && l < b) {
      score += .3;
    }

    // 4A gün içi uyum: öğle ve akşam aynı tarzda olmasın, öğle hafif olsun.
    PlannedDish? lead(Meal m) =>
        day.of(m).firstWhereOrNull(_isCenter) ??
        day.of(m).firstWhereOrNull((x) => x.role == DishRole.sebzeYemegi);
    final lunchLead = lead(Meal.lunch), dinnerLead = lead(Meal.dinner);
    if (lunchLead != null && dinnerLead != null) {
      bool single(PlannedDish x) => x.role == DishRole.anaTekTabak;
      bool veggie(PlannedDish x) =>
          x.role == DishRole.sebzeYemegi ||
          x.tags.cooking == Cooking.zeytinyagli;
      if (single(lunchLead) && single(dinnerLead)) score += .3;
      if (veggie(lunchLead) && veggie(dinnerLead)) score += .3;
      if (lunchLead.tags.weight == Heft.agir &&
          dinnerLead.tags.weight != Heft.agir) {
        score += .3;
      }
    }

    final fried = day.dishes.where((x) => x.tags.cooking == Cooking.kizartma).length;
    score += fried * (lose ? .3 : .15);
    score += day.dishes.where(_isHeavyMeze).length * (lose ? .2 : .1);

    // Her gün sebze yemeği ya da salata (tablo 6).
    final veg = day.dishes.any((x) =>
        x.role == DishRole.sebzeYemegi ||
        (x.role == DishRole.yanSalata && x.tags.weight != Heft.agir) ||
        x.tags.snack == SnackKind.sebze ||
        x.tags.snack == SnackKind.smoothie);
    if (!veg) score += .5;

    // Öğle ve akşam aynı protein olmasın.
    String? g(Meal m) =>
        day.of(m).where(_isCenter).map((x) => proteinGroup(x.tags)).firstOrNull;
    final lg = g(Meal.lunch), dg = g(Meal.dinner);
    if (lg != null && lg == dg) score += .3;

    // 4 öğünde meyve/sebze ara öğünü, kilo almada enerji yoğun ara öğün.
    for (final s in day.dishes.where((x) => x.meal.isSnack)) {
      if (options.goal == Goal.gain) {
        if (!{SnackKind.shake, SnackKind.kuruyemis, SnackKind.tahilli}
            .contains(s.tags.snack)) {
          score += .1;
        }
      } else if (options.mealCount == 4 && !_freshKinds.contains(s.tags.snack)) {
        score += .1;
      }
    }

    if (options.useFridge && day.dishes.isNotEmpty) {
      final ratio = day.dishes.fold(0.0,
              (s, x) => s + (fridgeRatio[x.recipe.id] ?? 0)) /
          day.dishes.length;
      score -= .3 * ratio;
    }
    return score;
  }

  /// Tablo 6 dışına çıkan grup sayısı (kısa planlarda orantılı).
  int balanceViolations(List<PlannedDay> week) {
    final f = week.length / 7;
    final c = _WeekCounts(week);
    var v = 0;
    if (options.vegetarian) {
      if (c.legume < (4 * f).round()) v++;
    } else {
      if (c.fish < (2 * f).round()) v++;
      if (c.legume < (2 * f).round()) v++;
      if (c.red > (3 * f).ceil()) v++;
      if (c.processed > f.ceil()) v++;
      if (c.chicken < (2 * f).floor() || c.chicken > (3 * f).ceil()) v++;
    }
    if (c.fried > (2 * f).ceil()) v++;
    if (c.heavy > (3 * f).ceil()) v++;
    if (c.world > (3 * f).ceil()) v++;
    if (c.dinnerSingle > (2 * f).ceil()) v++;
    return v;
  }

  /// Bölüm 8: haftanın toplam puanı.
  double weekScore(List<PlannedDay> week) {
    var score = week.fold(0.0, (s, d) => s + dayScore(d));
    final ids = [
      for (final d in week)
        for (final x in d.dishes)
          if (!_everyday(x)) x.recipe.id,
    ];
    score += .6 * (ids.length - ids.toSet().length);
    return score + .8 * balanceViolations(week);
  }

  double _balanceDelta(List<PlannedDay> week, PlannedDay day) {
    // Eksik haftada yalnızca üst sınırları aşmak cezalandırılır; alt sınırlar
    // grup planıyla sağlanır ve hafta sonunda puanlanır.
    final c = _WeekCounts([...week, day]);
    const p = 1.5;
    return (c.fried > 2 ? p : 0) +
        (c.processed > 1 ? p : 0) +
        (c.red > 3 ? p : 0) +
        (!options.vegetarian && c.chicken > 3 ? p : 0) +
        (c.heavy > 3 ? p : 0) +
        (c.world > 3 ? p : 0) +
        (c.dinnerSingle > 2 ? p : 0);
  }
}

/// Bir öğünü kurarken enerji bütçesini izler (bölüm 3): ana tabak en küçük
/// porsiyonuyla (0,75) sayılır, diğer tabaklar ancak bütçeye sığarsa eklenir.
class _Plate {
  _Plate(this.meal, this.budget);

  final Meal meal;
  final double budget;
  final dishes = <PlannedDish>[];
  var _kcal = 0.0;

  void addMain(Recipe? r) {
    if (r == null) return;
    dishes.add(PlannedDish(r, meal));
    _kcal += r.kcal * .75;
  }

  void add(Recipe? r) {
    if (r == null) return;
    dishes.add(PlannedDish(r, meal));
    _kcal += r.kcal;
  }

  void addIfFits(Recipe? r) {
    if (r != null && _kcal + r.kcal <= budget * 1.1) add(r);
  }

  static const _order = [
    DishRole.kahvaltiAna, DishRole.kahvaltiYan, DishRole.corba,
    DishRole.anaProtein, DishRole.baklagil, DishRole.anaTekTabak,
    DishRole.sebzeYemegi, DishRole.yanTahil, DishRole.yanSalata,
    DishRole.yanYogurt, DishRole.tatli,
  ];

  /// Sofra sırası: çorba, yemek, yanlar.
  List<PlannedDish> sorted() =>
      dishes.sortedBy<num>((d) => _order.indexOf(d.role));
}

/// Tablo 6 için sayımlar; protein grupları ana yemeklere göre sayılır.
class _WeekCounts {
  _WeekCounts(List<PlannedDay> week) {
    for (final d in week) {
      for (final x in d.dishes) {
        if (x.tags.cooking == Cooking.kizartma) fried++;
        if (x.tags.protein == ProteinSource.islenmisEt) processed++;
        if (!_isCenter(x)) continue;
        if (x.tags.weight == Heft.agir) heavy++;
        if (x.tags.world) world++;
        if (x.meal == Meal.dinner && x.role == DishRole.anaTekTabak) {
          dinnerSingle++;
        }
        if (x.tags.protein == ProteinSource.kirmiziEt) red++;
        switch (proteinGroup(x.tags)) {
          case 'balik':
            fish++;
          case 'baklagil':
            legume++;
          case 'tavuk':
            chicken++;
        }
      }
    }
  }

  var fish = 0, legume = 0, red = 0, processed = 0, chicken = 0;
  var fried = 0, heavy = 0, world = 0, dinnerSingle = 0;
}
