import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../core/ui.dart';
import '../../data/database.dart';
import '../../data/providers.dart';

/// Aylık israf özeti: bu ay vs. geçen ay, en çok israf edilenler.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final removed = ref.watch(removedProvider);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final month = DateFormat('MMMM y', 'tr').format(now);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: removed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
          data: (all) {
            final thisMonth = all
                .where((e) => !e.item.removedAt!.isBefore(monthStart))
                .toList();
            final lastMonth =
                all.where((e) => e.item.removedAt!.isBefore(monthStart)).toList();
            bool wasted(PantryEntry e) => e.item.outcome == Outcome.wasted;

            final wastedNow = thisMonth.where(wasted).toList();
            final consumedNow = thisMonth.length - wastedNow.length;
            final wastedBefore = lastMonth.where(wasted).length;
            final topWasted = groupBy(wastedNow, (e) => e.ingredient.id)
                .values
                .sortedBy<num>((l) => -l.length)
                .take(3)
                .toList();

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(toBeginningOfSentenceCase(month, 'tr'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text('Özet',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _Headline(
                      wasted: wastedNow.length, wastedBefore: wastedBefore),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.restaurant_rounded,
                          label: 'Tüketildi',
                          value: '$consumedNow',
                          color: Freshness.fresh.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.delete_outline_rounded,
                          label: 'Çöpe gitti',
                          value: '${wastedNow.length}',
                          color: Freshness.expired.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.percent_rounded,
                          label: 'İsraf oranı',
                          value: thisMonth.isEmpty
                              ? '–'
                              : '%${(wastedNow.length * 100 / thisMonth.length).round()}',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (thisMonth.isNotEmpty) ...[
                  const SectionTitle('Tüketilen ve israf edilen'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _RatioCard(consumed: consumedNow, wasted: wastedNow.length),
                  ),
                ],
                if (topWasted.isNotEmpty) ...[
                  const SectionTitle('En çok israf edilenler'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            for (final (i, group) in topWasted.indexed)
                              ListTile(
                                leading: EmojiBadge(group.first.ingredient.emoji,
                                    color: Freshness.expired.color, size: 42),
                                title: Text(group.first.ingredient.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text('${i + 1}. sırada'),
                                trailing: Pill('${group.length} kez',
                                    color: Freshness.expired.color),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                                'İpucu: Bu ürünleri daha küçük miktarlarda almayı dene.'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (wastedNow.isNotEmpty) ...[
                  const SectionTitle('Bu ay çöpe gidenler'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Column(
                        children: [
                          for (final (i, e) in wastedNow.indexed) ...[
                            if (i > 0) const Divider(indent: 72),
                            ListTile(
                              leading: EmojiBadge(e.ingredient.emoji, size: 40),
                              title: Text(e.ingredient.name),
                              subtitle: Text(
                                  '${formatQty(e.item.quantity)} ${e.item.unit}'),
                              trailing: Text(shortDate(e.item.removedAt!),
                                  style: Theme.of(context).textTheme.bodySmall),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (thisMonth.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                    child: Text(
                      'Dolaptan ürün çıkardıkça (tüketildi / çöpe gitti) '
                      'istatistiklerin burada oluşacak.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.wasted, required this.wastedBefore});

  final int wasted;
  final int wastedBefore;

  @override
  Widget build(BuildContext context) {
    final (emoji, title, subtitle) = switch ((wasted, wastedBefore)) {
      (0, _) => ('🌱', 'Bu ay hiç israf yok!', 'Harika gidiyorsun.'),
      (final w, final b) when b > 0 && w < b => (
          '📉',
          'Bu ay $w ürün israf ettin',
          'Geçen aya göre %${((b - w) * 100 / b).round()} daha az 🎉',
        ),
      (final w, final b) when b > 0 && w > b => (
          '📈',
          'Bu ay $w ürün israf ettin',
          'Geçen ay $b idi. Acil tüket listesine göz at.',
        ),
      (final w, _) => ('♻️', 'Bu ay $w ürün israf ettin', 'Geçen ayla aynı seviyede.'),
    };
    return HeroCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.88))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Tüketilen / israf edilen oranını gösteren yatay çubuk.
class _RatioCard extends StatelessWidget {
  const _RatioCard({required this.consumed, required this.wasted});

  final int consumed;
  final int wasted;

  @override
  Widget build(BuildContext context) {
    final consumedColor = Freshness.fresh.color;
    final wastedColor = Freshness.expired.color;
    Widget legend(Color c, String label, int n) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('$label · $n',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (consumed > 0)
                      Expanded(flex: consumed, child: ColoredBox(color: consumedColor)),
                    if (consumed > 0 && wasted > 0) const SizedBox(width: 3),
                    if (wasted > 0)
                      Expanded(flex: wasted, child: ColoredBox(color: wastedColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                legend(consumedColor, 'Tüketildi', consumed),
                legend(wastedColor, 'Çöpe gitti', wasted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
