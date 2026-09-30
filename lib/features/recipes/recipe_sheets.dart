import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/dates.dart';
import '../../core/text.dart';
import '../../core/ui.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../data/recipe_catalog.dart';
import 'recipe_match.dart';

String dayLabel(DateTime day) {
  final diff = daysLeft(day);
  return switch (diff) {
    0 => 'Bugün',
    1 => 'Yarın',
    _ => toBeginningOfSentenceCase(DateFormat('EEEE', 'tr').format(day), 'tr'),
  };
}

Future<void> openRecipeOnWeb(BuildContext context, Recipe r) async {
  final ok = await launchUrl(Uri.parse(recipeUrl(r)),
      mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif açılamadı')));
  }
}

Future<void> addMissing(
    BuildContext context, WidgetRef ref, Iterable<Ingredient> missing) async {
  final messenger = ScaffoldMessenger.of(context);
  final added =
      await ref.read(databaseProvider).addMissingToShopping(missing);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(added == 0
          ? 'Eksikler zaten alışveriş listende'
          : '$added ürün alışveriş listesine eklendi 🛒'),
    ));
}

Future<void> showRecipeDetail(BuildContext context, String recipeId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RecipeDetailSheet(recipeId: recipeId),
    );

class _RecipeDetailSheet extends ConsumerWidget {
  const _RecipeDetailSheet({required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref
        .watch(recipeMatchesProvider)
        ?.firstWhere((m) => m.recipe.id == recipeId);
    if (match == null) return const SizedBox(height: 200);
    final r = match.recipe;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final warn = Freshness.critical.color;

    final grams = recipePortions[r.name] ?? const <String, num>{};
    Widget row(Ingredient i, {required IconData icon, required Color color, String? tag}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(i.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(i.name,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              if (grams[i.name] case final g?)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('${formatQty(g.toDouble())} g', style: text.bodySmall),
                ),
              if (tag != null) Pill(tag, color: color),
            ],
          ),
        );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(
            children: [
              EmojiBadge(r.emoji, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: text.titleLarge),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      Pill('${r.minutes} dk',
                          color: scheme.primary, icon: Icons.schedule_rounded),
                      Pill('${r.kcal} kcal / porsiyon',
                          color: scheme.primary,
                          icon: Icons.local_fire_department_rounded),
                      Pill(r.category, color: scheme.primary),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(match.ready ? Icons.check_circle_rounded : Icons.kitchen_rounded,
                    color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    match.ready
                        ? 'Tüm malzemeler dolabında, hemen yapabilirsin!'
                        : '${match.required} malzemeden ${match.have.length} tanesi dolabında',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _NutritionCard(recipe: r),
          const SectionTitle('Malzemeler (1 porsiyon)',
              padding: EdgeInsets.fromLTRB(0, 20, 0, 6)),
          for (final i in match.have)
            row(i, icon: Icons.check_circle_rounded, color: scheme.primary),
          for (final i in match.missing)
            row(i, icon: Icons.radio_button_unchecked_rounded, color: warn, tag: 'eksik'),
          for (final i in match.staples)
            row(i,
                icon: Icons.inventory_2_outlined,
                color: scheme.onSurfaceVariant,
                tag: 'temel'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: match.ready
                ? null
                : () => addMissing(context, ref, match.missing),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: Text(match.ready
                ? 'Eksik malzeme yok'
                : 'Eksikleri listeye ekle (${match.missing.length})'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final day = await pickPlanDay(context);
              if (day == null) return;
              await ref.read(databaseProvider).addMealPlan(day, r.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${r.name} · ${dayLabel(day)} planına eklendi')));
              }
            },
            icon: const Icon(Icons.event_available_rounded),
            label: const Text('Haftalık plana ekle'),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => openRecipeOnWeb(context, r),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Tarifi aç · nefisyemektarifleri.com'),
          ),
        ],
      ),
    );
  }
}

/// Bir porsiyonun enerji ve makroları; kaynağı açıkça yazılır.
class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final n = recipe.nutrients;
    Widget cell(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: text.bodySmall),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              cell('${recipe.kcal}', 'kcal'),
              cell('${n.protein.round()} g', 'protein'),
              cell('${n.carb.round()} g', 'karbonhidrat'),
              cell('${n.fat.round()} g', 'yağ'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '1 porsiyon · Aşağıdaki gramajlar ve USDA besin veritabanı '
            '(SR Legacy) değerleriyle hesaplandı.',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Önümüzdeki 7 günden birini seçtirir.
Future<DateTime?> pickPlanDay(BuildContext context) {
  final today = dateOnly(DateTime.now());
  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text('Hangi gün?',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (var i = 0; i < 7; i++)
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(dayLabel(addDays(today, i)),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(DateFormat('d MMMM', 'tr').format(addDays(today, i))),
                onTap: () => Navigator.pop(context, addDays(today, i)),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Plana yemek eklerken tarif seçici; dolaba en uygun olanlar üstte.
Future<Recipe?> pickRecipe(BuildContext context) =>
    showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RecipePicker(),
    );

class _RecipePicker extends ConsumerStatefulWidget {
  const _RecipePicker();

  @override
  ConsumerState<_RecipePicker> createState() => _RecipePickerState();
}

class _RecipePickerState extends ConsumerState<_RecipePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(recipeMatchesProvider) ?? const [];
    final q = normalizeTr(_query);
    final list =
        q.isEmpty ? all : all.where((m) => normalizeTr(m.recipe.name).contains(q)).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'Yemek ara…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final m = list[i];
                return ListTile(
                  leading: EmojiBadge(m.recipe.emoji, size: 42),
                  title: Text(m.recipe.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${m.recipe.category} · ${m.recipe.minutes} dk · ${m.recipe.kcal} kcal'),
                  trailing: MissingPill(m),
                  onTap: () => Navigator.pop(context, m.recipe),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MissingPill extends StatelessWidget {
  const MissingPill(this.match, {super.key});
  final RecipeMatch match;

  @override
  Widget build(BuildContext context) => match.ready
      ? Pill('Hazır', color: Theme.of(context).colorScheme.primary, icon: Icons.check_rounded)
      : Pill('${match.missing.length} eksik', color: Freshness.critical.color);
}
