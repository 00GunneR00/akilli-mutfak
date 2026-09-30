import 'package:collection/collection.dart';

import '../../core/dates.dart';
import '../../data/database.dart';

/// "Bitmiş olabilir" önerisi: kullanıcı "azaldı" dedi ya da ürün her zamanki
/// alım aralığını doldurdu.
class RestockHint {
  RestockHint(this.entry, this.reason, {required this.low, required this.score});

  final PantryEntry entry;
  final String reason;
  final bool low;

  /// Sıralama için: aralığın ne kadar aşıldığı (azaldı işaretliler en üstte).
  final double score;
}

/// Son alımlar arasındaki tipik (medyan) gün sayısı; en az 3 farklı günde
/// alınmamışsa tahmin yapılmaz.
int? purchaseInterval(List<DateTime> purchases) {
  final days = purchases.map(dateOnly).toSet().toList()..sort();
  if (days.length < 3) return null;
  final gaps = [
    for (var i = 1; i < days.length; i++) days[i].difference(days[i - 1]).inDays,
  ]..sort();
  return gaps[gaps.length ~/ 2].clamp(1, 365);
}

int _daysSince(DateTime d, DateTime now) =>
    dateOnly(now).difference(dateOnly(d)).inDays;

/// [pending]: alışveriş listesinde zaten alınmayı bekleyen ürün kimlikleri.
List<RestockHint> restockHints(
  List<PantryEntry> pantry,
  Map<String, List<DateTime>> history,
  Set<String> pending, {
  DateTime? now,
}) {
  now ??= DateTime.now();
  final hints = <RestockHint>[];
  final byIngredient = groupBy(pantry, (PantryEntry e) => e.ingredient.id);
  for (final MapEntry(key: id, value: entries) in byIngredient.entries) {
    if (pending.contains(id)) continue;
    final low = entries.firstWhereOrNull((e) => e.item.status == StockStatus.low);
    if (low != null) {
      hints.add(RestockHint(low, 'Azaldı', low: true, score: double.infinity));
      continue;
    }
    // Aynı üründen birden fazla varsa en yenisi belirleyicidir.
    final latest = entries.reduce((a, b) =>
        (a.item.statusAt ?? a.item.addedAt).isAfter(b.item.statusAt ?? b.item.addedAt)
            ? a
            : b);
    final since = _daysSince(latest.item.statusAt ?? latest.item.addedAt, now);
    final learned = purchaseInterval(history[id] ?? const []);
    final interval = learned ?? latest.ingredient.shelfDays;
    if (interval <= 0 || since < interval) continue;
    hints.add(RestockHint(
      latest,
      learned != null
          ? 'Genelde $learned günde bir alıyorsun'
          : '$since gün önce alındı',
      low: false,
      score: since / interval,
    ));
  }
  return hints.sortedBy<num>((h) => -h.score);
}
