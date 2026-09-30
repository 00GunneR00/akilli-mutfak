import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../core/ui.dart';
import '../../data/providers.dart';
import 'meal_planner.dart';
import 'recipe_match.dart';
import 'recipe_sheets.dart';

const _optionsKey = 'plan.options';

final _kcalFormat = NumberFormat.decimalPattern('tr');
String formatKcal(int kcal) => '${_kcalFormat.format(kcal)} kcal';

/// "1,5 porsiyon"; tam porsiyonda boş.
String servingsLabel(double s) =>
    s == 1 ? '' : '${_kcalFormat.format(s)} porsiyon';

/// Şartlara göre (kalori, öğün sayısı, hedef, tercihler) 7 günlük plan önerir;
/// kurallar diyetisyen skill'inden gelir (meal_planner.dart).
class PlanSuggestScreen extends ConsumerStatefulWidget {
  const PlanSuggestScreen({super.key, required this.hasExistingPlan});

  final bool hasExistingPlan;

  @override
  ConsumerState<PlanSuggestScreen> createState() => _PlanSuggestScreenState();
}

class _PlanSuggestScreenState extends ConsumerState<PlanSuggestScreen> {
  PlanOptions _options = const PlanOptions();
  int _seed = Random().nextInt(1 << 30);
  List<PlannedDay>? _plan;
  late bool _replace = widget.hasExistingPlan;
  bool _saving = false;

  List<DateTime> get _days {
    final today = dateOnly(DateTime.now());
    return [for (var d = 0; d < 7; d++) addDays(today, d)];
  }

  @override
  void initState() {
    super.initState();
    ref.read(databaseProvider).getValue(_optionsKey).then((s) {
      if (!mounted) return;
      _options = PlanOptions.fromJson(s);
      _regenerate();
    });
  }

  MealPlanner _planner() {
    final matches = ref.read(recipeMatchesProvider) ?? const [];
    return MealPlanner(_options,
        fridgeRatio: {for (final m in matches) m.recipe.id: m.ratio});
  }

  void _regenerate({bool reshuffle = false}) {
    if (reshuffle) _seed = Random().nextInt(1 << 30);
    setState(() => _plan = _planner().week(_days, seed: _seed));
  }

  void _setOptions(PlanOptions o) {
    _options = o;
    ref.read(databaseProvider).setValue(_optionsKey, o.toJson());
    _regenerate();
  }

  void _rerollDay(int index) {
    setState(() => _plan = _planner().reroll(_plan!, index, Random()));
  }

  Future<void> _apply() async {
    final plan = _plan;
    if (plan == null) return;
    setState(() => _saving = true);
    await ref.read(databaseProvider).applyMealPlan({
      for (final d in plan)
        d.day: [
          for (final x in d.dishes)
            (recipeId: x.recipe.id, meal: x.meal.name, servings: x.servings),
        ],
    }, replace: _replace);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
        const SnackBar(content: Text('Haftalık plan oluşturuldu 🍽️')));
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final avg = plan == null || plan.isEmpty
        ? 0
        : plan.fold(0, (s, d) => s + d.kcal) ~/ plan.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan öner')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _OptionsCard(options: _options, onChanged: _setOptions),
          if (plan != null) ...[
            SectionTitle(
              'Önerilen hafta',
              padding: const EdgeInsets.fromLTRB(4, 20, 0, 6),
              trailing: TextButton.icon(
                onPressed: () => _regenerate(reshuffle: true),
                icon: const Icon(Icons.shuffle_rounded, size: 18),
                label: const Text('Hepsini yenile'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Text(
                  'Günlük ortalama ${formatKcal(avg)} · hedef '
                  '${formatKcal(_options.dailyKcal)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            for (final (i, d) in plan.indexed)
              _SuggestedDayCard(
                day: d,
                options: _options,
                onReroll: () => _rerollDay(i),
              ),
          ],
          const SizedBox(height: 16),
          const _Disclaimer(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.hasExistingPlan)
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  dense: true,
                  title: const Text('Mevcut planın yerine koy'),
                  subtitle: Text(_replace
                      ? 'Bu haftaki yemekler silinip öneri yazılır'
                      : 'Öneri mevcut yemeklerin yanına eklenir'),
                  value: _replace,
                  onChanged: (v) => setState(() => _replace = v),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: plan == null || _saving ? null : _apply,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Planı uygula'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.options, required this.onChanged});

  final PlanOptions options;
  final ValueChanged<PlanOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget chip(String label, bool selected, ValueChanged<bool> onSelected) =>
        FilterChip(label: Text(label), selected: selected, onSelected: onSelected);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Günlük kalori', style: text.titleSmall),
                const Spacer(),
                Text(formatKcal(options.dailyKcal),
                    style: text.titleMedium?.copyWith(color: scheme.primary)),
              ],
            ),
            Slider(
              value: options.dailyKcal.toDouble(),
              min: PlanOptions.minKcal.toDouble(),
              max: PlanOptions.maxKcal.toDouble(),
              divisions: (PlanOptions.maxKcal - PlanOptions.minKcal) ~/ 100,
              label: formatKcal(options.dailyKcal),
              onChanged: (v) => onChanged(options.copyWith(dailyKcal: v.round())),
            ),
            Text('Günde kaç öğün?', style: text.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  for (final n in [2, 3, 4, 5])
                    ButtonSegment(value: n, label: Text('$n')),
                ],
                selected: {options.mealCount},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    onChanged(options.copyWith(mealCount: s.single)),
              ),
            ),
            const SizedBox(height: 6),
            Text(options.meals.map((m) => '${m.emoji} ${m.label}').join('  ·  '),
                style: text.bodySmall),
            const SizedBox(height: 14),
            Text('Hedef', style: text.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<Goal>(
                segments: [
                  for (final g in Goal.values)
                    ButtonSegment(value: g, label: Text(g.label)),
                ],
                selected: {options.goal},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    onChanged(options.copyWith(goal: s.single)),
              ),
            ),
            const SizedBox(height: 14),
            Text('Tercihler', style: text.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                chip('🧊  Dolaptakileri kullan', options.useFridge,
                    (v) => onChanged(options.copyWith(useFridge: v))),
                chip('🥦  Vejetaryen', options.vegetarian,
                    (v) => onChanged(options.copyWith(vegetarian: v))),
                chip('⏱️  Pratik (≤${PlanOptions.quickMinutes} dk)', options.quick,
                    (v) => onChanged(options.copyWith(quick: v))),
                chip('🍮  Tatlı ekle', options.dessert,
                    (v) => onChanged(options.copyWith(dessert: v))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedDayCard extends StatelessWidget {
  const _SuggestedDayCard(
      {required this.day, required this.options, required this.onReroll});

  final PlannedDay day;
  final PlanOptions options;
  final VoidCallback onReroll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final target = options.dailyKcal;
    final onTarget = (day.kcal - target).abs() <= target * 0.07;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(dayLabel(day.day), style: text.titleMedium),
                  const SizedBox(width: 8),
                  Pill(formatKcal(day.kcal),
                      color: onTarget ? scheme.primary : Freshness.soon.color,
                      icon: Icons.local_fire_department_rounded),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Bu günü yenile',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: onReroll,
                  ),
                ],
              ),
              if (day.dishes.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Bu şartlara uyan yemek bulunamadı',
                      style: text.bodySmall),
                ),
              for (final meal in options.meals)
                if (day.of(meal) case final dishes when dishes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 2, right: 12),
                    child: Row(
                      children: [
                        Text('${meal.emoji}  ${meal.label}',
                            style: text.labelMedium
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                        const Spacer(),
                        Text(formatKcal(day.kcalOf(meal)),
                            style: text.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  for (final x in dishes)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => showRecipeDetail(context, x.recipe.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Text(x.recipe.emoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(x.recipe.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  if (servingsLabel(x.servings)
                                      case final s when s.isNotEmpty)
                                    Text(s, style: text.bodySmall),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text('${x.kcal} kcal', style: text.bodySmall),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: style?.color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Öneriler sağlıklı yetişkinler için genel beslenme ilkelerine göre '
            'hazırlanır ve tahmini kalori içerir. Gebelik, kronik hastalık ya da '
            'özel bir sağlık durumun varsa bir diyetisyene danış.',
            style: style,
          ),
        ),
      ],
    );
  }
}
