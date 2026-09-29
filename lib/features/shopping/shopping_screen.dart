import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/ui.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../data/seed_catalog.dart';
import '../quick_add/quick_add_screen.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final _dismissed = <String>{};

  Future<void> _toggle(ShoppingEntry e) async {
    final expiry = await ref.read(databaseProvider).toggleShopping(e);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(expiry != null
          ? '${e.ingredient.emoji} ${e.ingredient.name} dolaba eklendi · SKT ${shortDate(expiry)}'
          : '${e.ingredient.name} dolaptan geri alındı'),
    ));
  }

  Future<void> _delete(ShoppingEntry e) async {
    setState(() => _dismissed.add(e.item.id));
    await ref.read(databaseProvider).deleteShoppingItem(e.item.id);
  }

  void _openAdd() => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const QuickAddScreen(target: AddTarget.shopping)),
      );

  @override
  Widget build(BuildContext context) {
    final shopping = ref.watch(shoppingProvider);

    return Scaffold(
      floatingActionButton: (shopping.value?.isEmpty ?? true)
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ürün ekle'),
            ),
      body: SafeArea(
        bottom: false,
        child: shopping.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
          data: (entries) {
            _dismissed.retainAll(entries.map((e) => e.item.id));
            final visible =
                entries.where((e) => !_dismissed.contains(e.item.id)).toList();
            if (visible.isEmpty) {
              return Column(
                children: [
                  const _Title(),
                  Expanded(
                    child: EmptyState(
                      emoji: '🛒',
                      title: 'Liste boş',
                      message:
                          'Markette aldıklarını işaretle, dolabın kendiliğinden dolsun.',
                      actionLabel: 'Listeye ürün ekle',
                      onAction: _openAdd,
                    ),
                  ),
                ],
              );
            }

            final todo = visible.where((e) => e.item.checkedAt == null).toList();
            final done = visible.where((e) => e.item.checkedAt != null).toList();
            final byCategory = groupBy(todo, (e) => e.ingredient.category);

            return ListView(
              padding: const EdgeInsets.only(bottom: 104),
              children: [
                const _Title(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ProgressCard(
                    done: done.length,
                    total: visible.length,
                    onClear: done.isEmpty
                        ? null
                        : () => ref.read(databaseProvider).clearCheckedShopping(),
                  ),
                ),
                for (final MapEntry(key: cat, value: items) in byCategory.entries) ...[
                  SectionTitle('${categoryEmoji[cat] ?? '🛒'}  $cat',
                      trailing: Text('${items.length}',
                          style: Theme.of(context).textTheme.bodySmall)),
                  for (final e in items)
                    Dismissible(
                      key: ValueKey(e.item.id),
                      direction: DismissDirection.endToStart,
                      background: SwipeBackground(
                        color: Freshness.expired.color,
                        icon: Icons.delete_outline_rounded,
                        label: 'Sil',
                        alignment: Alignment.centerRight,
                      ),
                      onDismissed: (_) => _delete(e),
                      child: _ShoppingTile(entry: e, onToggle: () => _toggle(e)),
                    ),
                ],
                if (done.isNotEmpty) ...[
                  SectionTitle('✅  Sepette',
                      trailing: Text('${done.length}',
                          style: Theme.of(context).textTheme.bodySmall)),
                  for (final e in done)
                    _ShoppingTile(entry: e, onToggle: () => _toggle(e)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Markete gitmeden önce',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text('Alışveriş', style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.done, required this.total, this.onClear});

  final int done;
  final int total;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
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
                    Text('$done / $total ürün alındı',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      'İşaretlediklerin tahmini SKT ile dolaba eklenir.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.shopping_basket_rounded, size: 40),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                label: const Text('Alınanları temizle'),
                onPressed: onClear,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShoppingTile extends StatelessWidget {
  const _ShoppingTile({required this.entry, required this.onToggle});

  final ShoppingEntry entry;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final checked = entry.item.checkedAt != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Opacity(
        opacity: checked ? 0.6 : 1,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: checked ? scheme.primary : Colors.transparent,
                      border: Border.all(
                        color: checked ? scheme.primary : scheme.outline,
                        width: 2,
                      ),
                    ),
                    child: checked
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  EmojiBadge(entry.ingredient.emoji, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.ingredient.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                decoration:
                                    checked ? TextDecoration.lineThrough : null,
                              ),
                        ),
                        if (checked) ...[
                          const SizedBox(height: 2),
                          Text('Dolaba eklendi',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  Pill('${formatQty(entry.item.quantity)} ${entry.item.unit}',
                      color: scheme.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
