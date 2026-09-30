import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../core/text.dart';
import '../../core/ui.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../data/recipe_catalog.dart';
import 'meal_planner.dart';
import 'plan_suggest_screen.dart';
import 'recipe_match.dart';
import 'recipe_sheets.dart';

enum _Tab { suggestions, plan }

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  _Tab _tab = _Tab.suggestions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ne pişirsem?',
                            style: text.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text('Yemekler', style: text.headlineMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<_Tab>(
                  segments: const [
                    ButtonSegment(
                        value: _Tab.suggestions,
                        icon: Icon(Icons.auto_awesome_rounded),
                        label: Text('Öneriler')),
                    ButtonSegment(
                        value: _Tab.plan,
                        icon: Icon(Icons.calendar_month_rounded),
                        label: Text('Haftalık plan')),
                  ],
                  selected: {_tab},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
            ),
            Expanded(
              child: switch (_tab) {
                _Tab.suggestions => const _Suggestions(),
                _Tab.plan => const _WeekPlan(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ Öneriler

const _all = 'Tümü';
const _ready = 'Hemen yapılabilir';

class _Suggestions extends ConsumerStatefulWidget {
  const _Suggestions();

  @override
  ConsumerState<_Suggestions> createState() => _SuggestionsState();
}

class _SuggestionsState extends ConsumerState<_Suggestions> {
  String _filter = _all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(recipeMatchesProvider);
    if (matches == null) return const Center(child: CircularProgressIndicator());

    final readyCount = matches.where((m) => m.ready).length;
    final almost = matches.where((m) => m.missing.length == 1).length;
    final q = normalizeTr(_query);
    final visible = matches.where((m) {
      if (q.isNotEmpty && !normalizeTr(m.recipe.name).contains(q)) return false;
      return switch (_filter) {
        _all => true,
        _ready => m.ready,
        final c => m.recipe.category == c,
      };
    }).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: HeroCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$readyCount yemek',
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
                      const SizedBox(height: 4),
                      const Text('dolabındakilerle hemen yapılabilir',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        almost == 0
                            ? 'Dolabına ürün ekledikçe öneriler artar.'
                            : '$almost yemek için sadece 1 malzeme eksik.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.restaurant_menu_rounded, size: 44),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Yemek ara… (ör. mercimek, köfte)',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final (label, value) in [
                (_all, _all),
                ('✅  $_ready', _ready),
                for (final MapEntry(key: c, value: e) in recipeCategories.entries)
                  ('$e  $c', c),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _filter == value,
                    onSelected: (_) => setState(() => _filter = value),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              _filter == _ready
                  ? 'Şu an tüm malzemeleri dolabında olan bir yemek yok. '
                      'Eksiği az olanlara göz at.'
                  : 'Aramana uygun yemek bulunamadı.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (final m in visible)
          _RecipeCard(match: m, onTap: () => showRecipeDetail(context, m.recipe.id)),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.match, required this.onTap});

  final RecipeMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = match.recipe;
    final scheme = Theme.of(context).colorScheme;
    final missingNames = match.missing.map((i) => i.name).toList();
    final subtitle = match.ready
        ? 'Tüm malzemeler dolabında'
        : 'Eksik: ${missingNames.take(3).join(', ')}'
            '${missingNames.length > 3 ? ' +${missingNames.length - 3}' : ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                EmojiBadge(r.emoji, size: 52,
                    color: match.ready ? scheme.primary : null),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text('${r.category} · ${r.minutes} dk · ${r.kcal} kcal',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: match.ratio,
                          minHeight: 6,
                          color: match.ready ? scheme.primary : Freshness.soon.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                MissingPill(match),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- Haftalık plan

class _WeekPlan extends ConsumerWidget {
  const _WeekPlan();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(weekPlanProvider).value;
    final matches = ref.watch(recipeMatchesProvider);
    if (plans == null || matches == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final byId = {for (final m in matches) m.recipe.id: m};
    final today = dateOnly(DateTime.now());
    final byDay = groupBy(plans, (MealPlan p) => dateOnly(p.day));

    // Haftanın tüm eksikleri (aynı malzeme bir kez).
    final missing = <String, Ingredient>{};
    for (final p in plans) {
      for (final i in byId[p.recipeId]?.missing ?? const <Ingredient>[]) {
        missing[i.id] = i;
      }
    }

    Future<void> add(DateTime day) async {
      final r = await pickRecipe(context);
      if (r != null) await ref.read(databaseProvider).addMealPlan(day, r.id);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        HeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${plans.length} yemek planlandı',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          missing.isEmpty
                              ? 'Planlananların malzemeleri tamam.'
                              : 'Bu hafta ${missing.length} malzeme eksik.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.calendar_month_rounded, size: 40),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PlanSuggestScreen(hasExistingPlan: plans.isNotEmpty)),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Plan öner (kalori ve tercihlere göre)'),
                ),
              ),
              if (missing.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    onPressed: () => addMissing(context, ref, missing.values),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: Text('Eksikleri listeye ekle (${missing.length})'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (var d = 0; d < 7; d++)
          _DayCard(
            day: addDays(today, d),
            plans: byDay[addDays(today, d)] ?? const [],
            matches: byId,
            onAdd: () => add(addDays(today, d)),
          ),
      ],
    );
  }
}

class _DayCard extends ConsumerWidget {
  const _DayCard({
    required this.day,
    required this.plans,
    required this.matches,
    required this.onAdd,
  });

  final DateTime day;
  final List<MealPlan> plans;
  final Map<String, RecipeMatch> matches;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isToday = daysLeft(day) == 0;
    // Öneriyle eklenenler öğün sırasına, elle eklenenler sona.
    final sorted = plans.sortedBy<num>(
        (p) => Meal.byName(p.meal)?.index ?? Meal.values.length);
    int kcalOf(MealPlan p) =>
        ((matches[p.recipeId]?.recipe.kcal ?? 0) * p.servings).round();
    final kcal = sorted.fold(0, (s, p) => s + kcalOf(p));
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
              color: isToday ? scheme.primary : scheme.outlineVariant,
              width: isToday ? 1.5 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(dayLabel(day), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Text(DateFormat('d MMMM', 'tr').format(day),
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  if (kcal > 0)
                    Text('≈ ${formatKcal(kcal)}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.primary, fontWeight: FontWeight.w700)),
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Yemek ekle'),
                  ),
                ],
              ),
              if (plans.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Henüz yemek yok',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              for (final p in sorted)
                if (matches[p.recipeId] case final m?)
                  ListTile(
                    contentPadding: const EdgeInsets.only(right: 0),
                    leading: EmojiBadge(m.recipe.emoji, size: 42),
                    title: Text(m.recipe.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        [
                          if (Meal.byName(p.meal) case final meal?) meal.label,
                          if (servingsLabel(p.servings) case final s
                              when s.isNotEmpty)
                            s,
                          '${kcalOf(p)} kcal',
                          m.ready
                              ? 'Malzemeler tamam'
                              : 'Eksik: ${m.missing.map((i) => i.name).join(', ')}',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    onTap: () => showRecipeDetail(context, m.recipe.id),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Plandan çıkar',
                      onPressed: () =>
                          ref.read(databaseProvider).deleteMealPlan(p.id),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
