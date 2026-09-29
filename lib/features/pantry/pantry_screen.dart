import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/ui.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../household/household_screen.dart';
import '../quick_add/quick_add_screen.dart';

enum _Filter {
  all('Tümü'),
  urgent('Acil'),
  soon('Bu hafta'),
  fresh('Taze');

  const _Filter(this.label);
  final String label;

  bool matches(Freshness f) => switch (this) {
        all => true,
        urgent => f == Freshness.expired || f == Freshness.critical,
        soon => f == Freshness.soon,
        fresh => f == Freshness.fresh,
      };
}

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  /// Kaydırılan satırlar, veritabanı akışı güncellenene kadar gizlenir;
  /// aksi halde Dismissible ağaçta kalıp hata verir.
  final _dismissed = <String>{};
  _Filter _filter = _Filter.all;

  Future<void> _remove(PantryEntry e, String outcome) async {
    setState(() => _dismissed.add(e.item.id));
    final db = ref.read(databaseProvider);
    await db.setPantryOutcome(e.item.id, outcome);
    if (!mounted) return;
    final wasted = outcome == Outcome.wasted;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(wasted
            ? '${e.ingredient.name} çöpe gitti olarak işaretlendi'
            : '${e.ingredient.name} tüketildi 👍'),
        action: SnackBarAction(
          label: 'Geri al',
          onPressed: () async {
            await db.setPantryOutcome(e.item.id, null);
            if (mounted) setState(() => _dismissed.remove(e.item.id));
          },
        ),
      ));
  }

  void _openAdd() => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const QuickAddScreen(target: AddTarget.pantry)),
      );

  void _openItem(PantryEntry e) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) =>
            _PantryItemSheet(entry: e, onRemove: (o) => _remove(e, o)),
      );

  @override
  Widget build(BuildContext context) {
    final pantry = ref.watch(pantryProvider);

    return Scaffold(
      floatingActionButton: (pantry.value?.isEmpty ?? true)
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ürün ekle'),
            ),
      body: SafeArea(
        bottom: false,
        child: pantry.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
          data: (entries) {
            final ids = entries.map((e) => e.item.id).toSet();
            _dismissed.retainAll(ids);
            final visible =
                entries.where((e) => !_dismissed.contains(e.item.id)).toList();
            if (visible.isEmpty) {
              return Column(
                children: [
                  const _Header(),
                  Expanded(
                    child: EmptyState(
                      emoji: '🧊',
                      title: 'Dolabın boş',
                      message:
                          'Ürün ekle ya da alışveriş listende işaretlediğin '
                          'ürünler buraya otomatik gelsin.',
                      actionLabel: 'İlk ürünü ekle',
                      onAction: _openAdd,
                    ),
                  ),
                ],
              );
            }

            final freshness = {
              for (final e in visible)
                e.item.id: Freshness.of(daysLeft(e.item.expiryDate)),
            };
            int count(_Filter f) =>
                visible.where((e) => f.matches(freshness[e.item.id]!)).length;
            final useSoon = visible
                .where((e) => freshness[e.item.id] != Freshness.fresh)
                .take(10)
                .toList();
            final filtered = visible
                .where((e) => _filter.matches(freshness[e.item.id]!))
                .toList();

            return ListView(
              padding: const EdgeInsets.only(bottom: 104),
              children: [
                const _Header(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _HealthCard(
                    total: visible.length,
                    urgent: count(_Filter.urgent),
                    soon: count(_Filter.soon),
                    fresh: count(_Filter.fresh),
                  ),
                ),
                if (useSoon.isNotEmpty) ...[
                  const SectionTitle('Önce bunları tüket'),
                  SizedBox(
                    height: 148,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: useSoon.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _UseSoonCard(
                        entry: useSoon[i],
                        onTap: () => _openItem(useSoon[i]),
                      ),
                    ),
                  ),
                ],
                SectionTitle('Tüm ürünler',
                    trailing: Text('${visible.length} ürün',
                        style: Theme.of(context).textTheme.bodySmall)),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final f in _Filter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${f.label} · ${count(f)}'),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
                const _SwipeHint(),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('Bu grupta ürün yok',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                for (final e in filtered)
                  _PantryTile(
                    key: ValueKey(e.item.id),
                    entry: e,
                    freshness: freshness[e.item.id]!,
                    onTap: () => _openItem(e),
                    onRemove: (o) => _remove(e, o),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Günaydın ☀️'
        : hour < 18
            ? 'İyi günler 👋'
            : 'İyi akşamlar 🌙';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text('Dolabım',
                    style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
          const SyncStatusButton(),
        ],
      ),
    );
  }
}

/// Dolap sağlığı: acil olmayan ürünlerin oranı.
class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.total,
    required this.urgent,
    required this.soon,
    required this.fresh,
  });

  final int total;
  final int urgent;
  final int soon;
  final int fresh;

  @override
  Widget build(BuildContext context) {
    final score = total == 0 ? 1.0 : (total - urgent) / total;
    final message = switch (urgent) {
      0 => 'Harika! Acil tüketilecek ürün yok.',
      1 => '1 ürün acil tüketilmeli.',
      final n => '$n ürün acil tüketilmeli.',
    };
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dolap sağlığı',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('%${(score * 100).round()}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            height: 1.1)),
                    const SizedBox(height: 4),
                    Text(message,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
              ),
              SizedBox.square(
                dimension: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                    const Center(
                        child: Icon(Icons.kitchen_rounded, size: 28)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(label: 'Acil', value: urgent, color: Freshness.critical.color),
              const SizedBox(width: 8),
              _MiniStat(label: 'Bu hafta', value: soon, color: Freshness.soon.color),
              const SizedBox(width: 8),
              _MiniStat(label: 'Taze', value: fresh, color: const Color(0xFF7DD3FC)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
            ),
            Text('$value',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _UseSoonCard extends StatelessWidget {
  const _UseSoonCard({required this.entry, required this.onTap});

  final PantryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = daysLeft(entry.item.expiryDate);
    final f = Freshness.of(days);
    return SizedBox(
      width: 136,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmojiBadge(entry.ingredient.emoji, color: f.color, size: 44),
                const Spacer(),
                Text(entry.ingredient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Pill(expiryLabel(days), color: f.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PantryTile extends StatelessWidget {
  const _PantryTile({
    super.key,
    required this.entry,
    required this.freshness,
    required this.onTap,
    required this.onRemove,
  });

  final PantryEntry entry;
  final Freshness freshness;
  final VoidCallback onTap;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final days = daysLeft(item.expiryDate);

    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      background: SwipeBackground(
        color: Freshness.fresh.color,
        icon: Icons.check_circle_outline_rounded,
        label: 'Tüketildi',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: SwipeBackground(
        color: Freshness.expired.color,
        icon: Icons.delete_outline_rounded,
        label: 'Çöpe gitti',
        alignment: Alignment.centerRight,
      ),
      onDismissed: (dir) => onRemove(dir == DismissDirection.startToEnd
          ? Outcome.consumed
          : Outcome.wasted),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  EmojiBadge(entry.ingredient.emoji, color: freshness.color),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.ingredient.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 3),
                        Text(
                          '${formatQty(item.quantity)} ${item.unit} · SKT ${shortDate(item.expiryDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pill(expiryLabel(days), color: freshness.color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ürün detayı: miktar (kısmi kullanım), SKT düzeltme ve çıkış seçenekleri.
class _PantryItemSheet extends ConsumerStatefulWidget {
  const _PantryItemSheet({required this.entry, required this.onRemove});

  final PantryEntry entry;
  final ValueChanged<String> onRemove;

  @override
  ConsumerState<_PantryItemSheet> createState() => _PantryItemSheetState();
}

class _PantryItemSheetState extends ConsumerState<_PantryItemSheet> {
  late double _qty = widget.entry.item.quantity;
  late DateTime _expiry = widget.entry.item.expiryDate;

  AppDatabase get _db => ref.read(databaseProvider);
  String get _id => widget.entry.item.id;

  void _finish(String outcome) {
    Navigator.pop(context);
    widget.onRemove(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final ing = widget.entry.ingredient;
    final f = Freshness.of(daysLeft(_expiry));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                EmojiBadge(ing.emoji, color: f.color, size: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ing.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Pill(ing.category,
                          color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            QuantityStepper(
              value: _qty,
              unit: widget.entry.item.unit,
              onChanged: (q) {
                setState(() => _qty = q);
                _db.updatePantryItem(_id, quantity: q);
              },
            ),
            const SizedBox(height: 10),
            ExpiryPickerTile(
              expiry: _expiry,
              onChanged: (d) {
                setState(() => _expiry = d);
                _db.updatePantryItem(_id, expiry: d);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Tüketildi'),
                    onPressed: () => _finish(Outcome.consumed),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Freshness.expired.color),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Çöpe gitti'),
                    onPressed: () => _finish(Outcome.wasted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant),
              onPressed: () {
                _db.deletePantryItem(_id);
                Navigator.pop(context);
              },
              child: const Text('Yanlışlıkla eklendi, sil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        children: [
          Icon(Icons.swipe_rounded, size: 16, color: style?.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Sağa kaydır: tüketildi · Sola kaydır: çöpe gitti',
                style: style),
          ),
        ],
      ),
    );
  }
}
