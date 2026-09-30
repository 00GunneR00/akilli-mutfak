import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/text.dart';
import '../../core/ui.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../data/seed_catalog.dart';

enum AddTarget { pantry, shopping }

/// Dolaba ya da alışveriş listesine ürün ekleme: sık alınanlar ve kategori
/// ızgarası, Türkçe duyarlı arama; seçilenler sepette toplanır.
class QuickAddScreen extends ConsumerStatefulWidget {
  const QuickAddScreen({super.key, required this.target});

  final AddTarget target;

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  final _search = TextEditingController();
  final List<CartLine> _cart = [];
  String _query = '';

  bool get _isPantry => widget.target == AddTarget.pantry;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  CartLine? _lineFor(Ingredient i) =>
      _cart.firstWhereOrNull((l) => l.ingredient.id == i.id);

  void _add(Ingredient i) {
    setState(() {
      final line = _lineFor(i);
      if (line != null) {
        line.quantity += i.defaultQty;
      } else {
        _cart.add(CartLine(i, i.defaultQty));
      }
    });
  }

  void _addFromSearch(Ingredient i) {
    _add(i);
    _search.clear();
    setState(() => _query = '');
    FocusScope.of(context).unfocus();
  }

  Future<void> _editLine(CartLine line) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LineEditor(
        line: line,
        onChanged: () => setState(() {}),
        onRemove: () => setState(() => _cart.remove(line)),
      ),
    );
  }

  Future<void> _createCustom(String name) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _CustomIngredientDialog(name: name),
    );
    if (result == null) return;
    final ing = await ref.read(databaseProvider).createCustomIngredient(
        name: name, category: result.$1, unit: result.$2);
    if (mounted) _addFromSearch(ing);
  }

  Future<void> _submit() async {
    final db = ref.read(databaseProvider);
    if (_isPantry) {
      await db.addToPantry(_cart);
    } else {
      await db.addToShopping(_cart);
    }
    if (!mounted) return;
    final n = _cart.length;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text(_isPantry
          ? '$n ürün dolaba eklendi'
          : '$n ürün alışveriş listesine eklendi'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(ingredientsProvider).value ?? const <Ingredient>[];
    final frequent = ref.watch(frequentProvider).value ?? const <Ingredient>[];
    final byCategory = groupBy(all, (Ingredient i) => i.category);
    final sections = [
      if (frequent.isNotEmpty) (emoji: '⭐', title: 'Sık aldıkların', items: frequent),
      for (final c in categoryShelfDays.keys)
        if (byCategory[c] case final items?)
          (emoji: categoryEmoji[c] ?? '🛒', title: c, items: items),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isPantry ? 'Dolaba ekle' : 'Listeye ekle'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SearchBar(
              controller: _search,
              hintText: 'Ürün ara… (ör. süt, domates)',
              leading: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.search_rounded),
              ),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (_query.trim().isEmpty)
            Expanded(
              child: _CatalogBrowser(
                sections: sections,
                tileBuilder: (i) => _IngredientTile(
                  ingredient: i,
                  line: _lineFor(i),
                  onTap: () => _add(i),
                  onLongPress: () {
                    _add(i);
                    _editLine(_lineFor(i)!);
                  },
                ),
              ),
            )
          else
            Expanded(
              child: _SearchResults(
                query: _query.trim(),
                all: all,
                onPick: _addFromSearch,
                onCreate: _createCustom,
              ),
            ),
          if (_cart.isNotEmpty)
            _CartPanel(
              cart: _cart,
              onEdit: _editLine,
              onSubmit: _submit,
              submitLabel: _isPantry ? 'Dolaba ekle' : 'Listeye ekle',
            ),
        ],
      ),
    );
  }
}

typedef _Section = ({String emoji, String title, List<Ingredient> items});

/// Tüm kategoriler tek kaydırılabilir listede; kaydırdıkça üstteki çip o anki
/// kategoriye geçer, çipe dokununca ilgili bölüme kayar (market uygulamaları
/// gibi). Bölüm konumları ızgara ölçülerinden hesaplanır, böylece henüz
/// çizilmemiş bölümlere de atlanabilir.
class _CatalogBrowser extends StatefulWidget {
  const _CatalogBrowser({required this.sections, required this.tileBuilder});

  final List<_Section> sections;
  final Widget Function(Ingredient) tileBuilder;

  @override
  State<_CatalogBrowser> createState() => _CatalogBrowserState();
}

class _CatalogBrowserState extends State<_CatalogBrowser> {
  static const _hPad = 16.0;
  static const _spacing = 10.0;
  static const _maxTileWidth = 120.0;
  static const _aspect = 0.92;
  static const _headerHeight = 52.0;
  static const _sectionGap = 12.0;

  final _scroll = ScrollController();
  final _chipKeys = <GlobalKey>[];
  List<double> _starts = const [];
  int _active = 0;

  /// Çipe dokununca başlayan kaydırma sürerken aktif çip sabit kalsın.
  bool _jumping = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  int get _count => widget.sections.length;

  void _onScroll() {
    if (_jumping || _starts.isEmpty) return;
    final offset = _scroll.offset + 1;
    var index = 0;
    for (var i = 0; i < _starts.length; i++) {
      if (_starts[i] <= offset) index = i;
    }
    // Liste sonuna varıldıysa son bölüm seçili görünsün.
    if (_scroll.position.extentAfter < 1) index = _starts.length - 1;
    _setActive(index);
  }

  void _setActive(int index) {
    if (index == _active) return;
    setState(() => _active = index);
    final ctx = _chipKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          alignment: 0.5, duration: const Duration(milliseconds: 250));
    }
  }

  Future<void> _jumpTo(int index) async {
    _jumping = true;
    _setActive(index);
    final target = _starts[index].clamp(0.0, _scroll.position.maxScrollExtent);
    await _scroll.animateTo(target,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    _jumping = false;
  }

  @override
  Widget build(BuildContext context) {
    while (_chipKeys.length < _count) {
      _chipKeys.add(GlobalKey());
    }
    if (_active >= _count) _active = 0;
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: _hPad),
          child: Row(
            children: [
              for (final (i, s) in widget.sections.indexed)
                Padding(
                  key: _chipKeys[i],
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${s.emoji}  ${s.title}'),
                    selected: i == _active,
                    onSelected: (_) => _jumpTo(i),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 16, color: text.bodySmall?.color),
              const SizedBox(width: 6),
              Text('Dokun: ekle · Basılı tut: miktar', style: text.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth - 2 * _hPad;
            final columns = ((width + _spacing) / (_maxTileWidth + _spacing))
                .ceil()
                .clamp(1, 12);
            final tileWidth = (width - _spacing * (columns - 1)) / columns;
            final tileHeight = tileWidth / _aspect;

            double sectionHeight(_Section s) {
              final rows = (s.items.length / columns).ceil();
              return _headerHeight +
                  rows * tileHeight +
                  (rows - 1).clamp(0, rows) * _spacing +
                  _sectionGap;
            }

            final starts = <double>[];
            var y = 0.0;
            for (final s in widget.sections) {
              starts.add(y);
              y += sectionHeight(s);
            }
            _starts = starts;
            // Son bölüm de en üste kaydırılabilsin.
            final tail = widget.sections.isEmpty
                ? 0.0
                : (constraints.maxHeight - sectionHeight(widget.sections.last))
                    .clamp(0.0, double.infinity);

            return CustomScrollView(
              controller: _scroll,
              slivers: [
                for (final s in widget.sections) ...[
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: _headerHeight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${s.emoji}  ${s.title}', style: text.titleMedium),
                            const Spacer(),
                            Text('${s.items.length} ürün', style: text.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        _hPad, 0, _hPad, _sectionGap),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: _spacing,
                        crossAxisSpacing: _spacing,
                        mainAxisExtent: tileHeight,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => widget.tileBuilder(s.items[i]),
                        childCount: s.items.length,
                      ),
                    ),
                  ),
                ],
                SliverToBoxAdapter(child: SizedBox(height: tail)),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({
    required this.ingredient,
    required this.line,
    required this.onTap,
    required this.onLongPress,
  });

  final Ingredient ingredient;
  final CartLine? line;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = line != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: selected ? scheme.secondaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ingredient.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      Text(
                        ingredient.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
                      ),
                    ],
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(formatQty(line!.quantity),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.all,
    required this.onPick,
    required this.onCreate,
  });

  final String query;
  final List<Ingredient> all;
  final ValueChanged<Ingredient> onPick;
  final ValueChanged<String> onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scored = <(int, Ingredient)>[
      for (final i in all)
        if (matchScore(i.name, query) case final s?) (s, i),
    ]..sort((a, b) => a.$1 != b.$1
        ? a.$1.compareTo(b.$1)
        : b.$2.popularity.compareTo(a.$2.popularity));
    final exact = scored.any((e) => normalizeTr(e.$2.name) == normalizeTr(query));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        for (final (_, i) in scored.take(30))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                leading: EmojiBadge(i.emoji, size: 44),
                title: Text(i.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(i.category),
                trailing: Icon(Icons.add_circle_rounded, color: scheme.primary),
                onTap: () => onPick(i),
              ),
            ),
          ),
        if (!exact)
          Card(
            color: scheme.secondaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
              leading: CircleAvatar(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add_rounded),
              ),
              title: Text('"$query" yeni ürün olarak ekle',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle:
                  const Text('Sözlüğe kaydedilir, bir dahakine hazır olur'),
              onTap: () => onCreate(query),
            ),
          ),
      ],
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.cart,
    required this.onEdit,
    required this.onSubmit,
    required this.submitLabel,
  });

  final List<CartLine> cart;
  final ValueChanged<CartLine> onEdit;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Text('Sepetin', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Pill('${cart.length} ürün', color: scheme.primary),
                  const Spacer(),
                  Text('Düzenlemek için dokun',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cart.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final l = cart[i];
                  return Material(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onEdit(l),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Text(l.ingredient.emoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.ingredient.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(
                                  '${formatQty(l.quantity)} ${l.ingredient.unit}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_rounded),
                  label: Text('$submitLabel (${cart.length})'),
                  onPressed: onSubmit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineEditor extends StatefulWidget {
  const _LineEditor({
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final CartLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  void _update(VoidCallback fn) {
    setState(fn);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.line;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                EmojiBadge(l.ingredient.emoji, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(l.ingredient.name,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 20),
            QuantityStepper(
              value: l.quantity,
              unit: l.ingredient.unit,
              onChanged: (q) => _update(() => l.quantity = q),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                  foregroundColor: Freshness.expired.color),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Sepetten çıkar'),
              onPressed: () {
                widget.onRemove();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomIngredientDialog extends StatefulWidget {
  const _CustomIngredientDialog({required this.name});
  final String name;

  @override
  State<_CustomIngredientDialog> createState() =>
      _CustomIngredientDialogState();
}

class _CustomIngredientDialogState extends State<_CustomIngredientDialog> {
  String _category = 'Diğer';
  String _unit = 'adet';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('"${widget.name}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Kategori'),
            borderRadius: BorderRadius.circular(14),
            items: [
              for (final c in categoryShelfDays.keys)
                DropdownMenuItem(
                    value: c, child: Text('${categoryEmoji[c]}  $c')),
            ],
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _unit,
            decoration: const InputDecoration(labelText: 'Birim'),
            borderRadius: BorderRadius.circular(14),
            items: [
              for (final u in units) DropdownMenuItem(value: u, child: Text(u)),
            ],
            onChanged: (v) => setState(() => _unit = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.pop(context, (_category, _unit)),
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

/// Miktar artır/azalt; kg ve L için yarımlık adımlar.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  final double value;
  final String unit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final step = qtyStep(unit);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.scale_outlined, color: scheme.primary, size: 22),
          const SizedBox(width: 12),
          const Text('Miktar', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton.filledTonal(
            icon: const Icon(Icons.remove_rounded),
            onPressed: value > step ? () => onChanged(value - step) : null,
          ),
          SizedBox(
            width: 80,
            child: Text(
              '${formatQty(value)} $unit',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton.filled(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => onChanged(value + step),
          ),
        ],
      ),
    );
  }
}
