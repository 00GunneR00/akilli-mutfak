import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Gün ekler; yaz saati geçişlerinden etkilenmez.
DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

int daysLeft(DateTime expiry, {DateTime? now}) {
  final e = DateTime.utc(expiry.year, expiry.month, expiry.day);
  final n = now ?? DateTime.now();
  return e.difference(DateTime.utc(n.year, n.month, n.day)).inDays;
}

enum Freshness {
  expired('Süresi geçti', Color(0xFFEF4444)),
  critical('Acil tüket', Color(0xFFF97316)),
  soon('Bu hafta', Color(0xFFF59E0B)),
  fresh('Taze', Color(0xFF0EA5E9));

  const Freshness(this.label, this.color);
  final String label;
  final Color color;

  static Freshness of(int daysLeft) => switch (daysLeft) {
        < 0 => expired,
        <= 1 => critical,
        <= 4 => soon,
        _ => fresh,
      };
}

String expiryLabel(int days) => switch (days) {
      < -1 => '${-days} gün önce doldu',
      -1 => 'Dün doldu',
      0 => 'Bugün son gün',
      1 => 'Yarın son gün',
      _ => '$days gün kaldı',
    };

final _short = DateFormat('d MMM', 'tr');
String shortDate(DateTime d) => _short.format(d);

String formatQty(double q) {
  if (q == q.roundToDouble()) return q.toInt().toString();
  return q
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll('.', ',');
}

double qtyStep(String unit) => (unit == 'kg' || unit == 'L') ? 0.5 : 1;
