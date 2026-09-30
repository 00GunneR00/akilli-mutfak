import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/ui.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../data/seed_catalog.dart';
import '../household/household_screen.dart';
import '../quick_add/quick_add_screen.dart';
import 'restock.dart';

final _lowColor = Freshness.soon.color;

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  /// Kaydırılan satırlar, veritabanı akışı güncellenene kadar gizlenir;
  /// aksi halde Dismissible ağaçta kalıp hata verir.
  final _dismissed = <String>{};

  AppDatabase get _db => ref.read(databaseProvider);

  void _snack(String text, {VoidCallback? undo}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        action: undo == null
            ? null
            : SnackBarAction(label: 'Geri al', onPressed: undo),
      ));
  }

  /// "Bitti": dolaptan çıkar, listede yoksa alışveriş listesine ekler.
  Future<void> _finish(PantryEntry e) async {
    setState(() => _dismissed.add(e.item.id));
    final shoppingId = await _db.finishPantryItem(e);
    if (!mounted) return;
    _snack(
      shoppingId != null
          ? '${e.ingredient.emoji} ${e.ingredient.name} bitti · listeye eklendi'
          : '${e.ingredient.name} bitti · zaten listede',
      undo: () async {
        await _db.undoFinishPantryItem(e.item.id, shoppingId);
        if (mounted) setState(() => _dismissed.remove(e.item.id));
      },
    );
  }

  Future<void> _waste(PantryEntry e) async {
    setState(() => _dismissed.add(e.item.id));
    await _db.setPantryOutcome(e.item.id, Outcome.wasted);
    if (!mounted) return;
    _snack('${e.ingredient.name} çöpe gitti olarak işaretlendi', undo: () async {
      await _db.setPantryOutcome(e.item.id, null);
      if (mounted) setState(() => _dismissed.remove(e.item.id));
    });
  }

  /// Etikete dokununca: Var → Azaldı → Bitti.
  void _cycle(PantryEntry e) {
    if (e.item.status == StockStatus.low) {
      _finish(e);
    } else {
      _db.setPantryStatus(e.item.id, StockStatus.low);
    }
  }

  Future<void> _restock(List<RestockHint> hints) async {
    final added = await _db.addMissingToShopping(
        hints.map((h) => h.entry.ingredient),
        source: 'restock');
    if (!mounted) return;
    _snack(added == 1
        ? '${hints.first.entry.ingredient.name} listeye eklendi'
        : '$added ürün listeye eklendi');
  }

  void _openAdd() => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const QuickAddScreen(target: AddTarget.pantry)),
      );

  void _openItem(PantryEntry e) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _PantryItemSheet(
          entry: e,
          onFinish: () => _finish(e),
          onWaste: () => _waste(e),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pantry = ref.watch(pantryProvider);
    final history = ref.watch(purchaseHistoryProvider).value ?? const {};
    final pending = {
      for (final s in ref.watch(shoppingProvider).value ?? const <ShoppingEntry>[])
        if (s.item.checkedAt == null) s.ingredient.id,
    };

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
            _dismissed.retainAll(entries.map((e) => e.item.id));
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

            final hints = restockHints(visible, history, pending);
            final categoryOrder = categoryShelfDays.keys.toList();
            int rank(String c) {
              final i = categoryOrder.indexOf(c);
              return i < 0 ? categoryOrder.length : i;
            }

            final byCategory = groupBy(visible, (e) => e.ingredient.category)
                .entries
                .sortedBy<num>((g) => rank(g.key));

            return ListView(
              padding: const EdgeInsets.only(bottom: 104),
              children: [
                const _Header(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SummaryCard(
                    total: visible.length,
                    low: visible
                        .where((e) => e.item.status == StockStatus.low)
                        .length,
                    pending: pending.length,
                  ),
                ),
                if (hints.isNotEmpty) ...[
                  SectionTitle(
                    '🛒  Bitmiş olabilir',
                    trailing: hints.length > 1
                        ? TextButton(
                            onPressed: () => _restock(hints),
                            child: const Text('Hepsini listeye ekle'),
                          )
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Column(
                        children: [
                          for (final (i, h) in hints.indexed) ...[
                            if (i > 0) const Divider(indent: 72),
                            _RestockRow(
                              hint: h,
                              onStillHave: () => _db.setPantryStatus(
                                  h.entry.item.id, StockStatus.ok),
                              onAdd: () => _restock([h]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const _Hint(),
                for (final MapEntry(key: cat, value: items) in byCategory) ...[
                  SectionTitle('${categoryEmoji[cat] ?? '🛒'}  $cat',
                      trailing: Text('${items.length}',
                          style: Theme.of(context).textTheme.bodySmall)),
                  for (final e in items)
                    _PantryTile(
                      key: ValueKey(e.item.id),
                      entry: e,
                      onTap: () => _openItem(e),
                      onStatusTap: () => _cycle(e),
                      onFinish: () => _finish(e),
                      onWaste: () => _waste(e),
                    ),
                ],
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.total, required this.low, required this.pending});

  final int total;
  final int low;
  final int pending;

  @override
  Widget build(BuildContext context) {
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
                    Text('Evde',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('$total ürün',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.1)),
                    const SizedBox(height: 4),
                    Text(
                        'Biten ürünü işaretle, alışveriş listesi kendini yazsın.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.kitchen_rounded, size: 44),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                  label: 'Var',
                  value: total - low,
                  color: const Color(0xFF7DD3FC)),
              const SizedBox(width: 8),
              _MiniStat(label: 'Azaldı', value: low, color: _lowColor),
              const SizedBox(width: 8),
              _MiniStat(
                  label: 'Listede',
                  value: pending,
                  color: const Color(0xFFBBF7D0)),
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

class _RestockRow extends StatelessWidget {
  const _RestockRow(
      {required this.hint, required this.onStillHave, required this.onAdd});

  final RestockHint hint;
  final VoidCallback onStillHave;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ing = hint.entry.ingredient;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          EmojiBadge(ing.emoji,
              color: hint.low ? _lowColor : null, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ing.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(hint.reason, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(onPressed: onStillHave, child: const Text('Hâlâ var')),
          IconButton.filledTonal(
            tooltip: 'Listeye ekle',
            icon: const Icon(Icons.add_shopping_cart_rounded),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, size: 16, color: style?.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
                'Etikete dokun: var → azaldı → bitti · Sağa kaydır: bitti · '
                'Sola: çöpe gitti',
                style: style),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.low, required this.onTap});

  final bool low;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = low ? _lowColor : Theme.of(context).colorScheme.primary;
    return Material(
      color: color.withValues(alpha: 0.12),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(low ? Icons.hourglass_bottom_rounded : Icons.check_rounded,
                  size: 16, color: color),
              const SizedBox(width: 4),
              Text(low ? 'Azaldı' : 'Var',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
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
    required this.onTap,
    required this.onStatusTap,
    required this.onFinish,
    required this.onWaste,
  });

  final PantryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onStatusTap;
  final VoidCallback onFinish;
  final VoidCallback onWaste;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final low = item.status == StockStatus.low;

    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      background: SwipeBackground(
        color: Freshness.fresh.color,
        icon: Icons.add_shopping_cart_rounded,
        label: 'Bitti',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: SwipeBackground(
        color: Freshness.expired.color,
        icon: Icons.delete_outline_rounded,
        label: 'Çöpe gitti',
        alignment: Alignment.centerRight,
      ),
      onDismissed: (dir) =>
          dir == DismissDirection.startToEnd ? onFinish() : onWaste(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  EmojiBadge(entry.ingredient.emoji,
                      color: low ? _lowColor : null, size: 44),
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
                        Text('${formatQty(item.quantity)} ${item.unit}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(low: low, onTap: onStatusTap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ürün detayı: miktar, var/azaldı ve çıkış seçenekleri.
class _PantryItemSheet extends ConsumerStatefulWidget {
  const _PantryItemSheet(
      {required this.entry, required this.onFinish, required this.onWaste});

  final PantryEntry entry;
  final VoidCallback onFinish;
  final VoidCallback onWaste;

  @override
  ConsumerState<_PantryItemSheet> createState() => _PantryItemSheetState();
}

class _PantryItemSheetState extends ConsumerState<_PantryItemSheet> {
  late double _qty = widget.entry.item.quantity;
  late String _status = widget.entry.item.status;

  AppDatabase get _db => ref.read(databaseProvider);
  String get _id => widget.entry.item.id;

  void _close(VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final ing = widget.entry.ingredient;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                EmojiBadge(ing.emoji, size: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ing.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                          'Eklendi: ${shortDate(widget.entry.item.addedAt)}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: StockStatus.ok,
                    icon: Icon(Icons.check_rounded),
                    label: Text('Var')),
                ButtonSegment(
                    value: StockStatus.low,
                    icon: Icon(Icons.hourglass_bottom_rounded),
                    label: Text('Azaldı')),
              ],
              selected: {_status},
              onSelectionChanged: (s) {
                setState(() => _status = s.single);
                _db.setPantryStatus(_id, s.single);
              },
            ),
            const SizedBox(height: 10),
            QuantityStepper(
              value: _qty,
              unit: widget.entry.item.unit,
              onChanged: (q) {
                setState(() => _qty = q);
                _db.updatePantryItem(_id, quantity: q);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('Bitti'),
                    onPressed: () => _close(widget.onFinish),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Freshness.expired.color),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Çöpe gitti'),
                    onPressed: () => _close(widget.onWaste),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Bitti dersen alışveriş listesine eklenir.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
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
