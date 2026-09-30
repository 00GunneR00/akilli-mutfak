// Malzeme besin değerlerini USDA SR Legacy verisinden üretir.
//
// Kullanım:
//   1. https://fdc.nal.usda.gov/download-datasets adresinden
//      "SR Legacy" CSV paketini (FoodData_Central_sr_legacy_food_csv_2018-04.zip)
//      indirip açın.
//   2. dart run tool/nutrition/build.dart <açılan klasör>
//
// Girdi: tool/nutrition/ingredient_usda.tsv (malzeme → fdc_id eşleştirmesi).
// Çıktı: lib/data/ingredient_nutrition.g.dart (100 g başına değerler).

import 'dart:io';

const _energy = '1008', _protein = '1003', _fat = '1004', _carb = '1005';

List<String> _csv(String line) {
  final out = <String>[];
  final buf = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      if (quoted && i + 1 < line.length && line[i + 1] == '"') {
        buf.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (c == ',' && !quoted) {
      out.add(buf.toString());
      buf.clear();
    } else {
      buf.write(c);
    }
  }
  out.add(buf.toString());
  return out;
}

String _num(double v) {
  final s = v.toStringAsFixed(2);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Kullanım: dart run tool/nutrition/build.dart <SR Legacy CSV klasörü>');
    exit(64);
  }
  final dir = args.single;
  final root = File.fromUri(Platform.script).parent.parent.parent.path;

  final mapping = <(String, String, double, String)>[];
  for (final line in File('$root/tool/nutrition/ingredient_usda.tsv').readAsLinesSync()) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final p = line.split('\t');
    mapping.add((p[0], p[1], double.parse(p[2]), p.length > 3 ? p[3] : ''));
  }
  final wanted = {for (final m in mapping) m.$2};

  final descriptions = <String, String>{};
  for (final line in File('$dir/food.csv').readAsLinesSync().skip(1)) {
    final c = _csv(line);
    if (wanted.contains(c[0])) descriptions[c[0]] = c[2];
  }
  final values = <String, Map<String, double>>{};
  for (final line in File('$dir/food_nutrient.csv').readAsLinesSync().skip(1)) {
    final c = _csv(line);
    if (!wanted.contains(c[1])) continue;
    if (!{_energy, _protein, _fat, _carb}.contains(c[2])) continue;
    values.putIfAbsent(c[1], () => {})[c[2]] = double.parse(c[3]);
  }

  final out = StringBuffer()
    ..writeln('// ÜRETİLDİ — elle düzenlemeyin. Kaynak: tool/nutrition/build.dart')
    ..writeln('//')
    ..writeln('// 100 g başına enerji (kcal), protein, yağ ve karbonhidrat (g).')
    ..writeln('// Veri: USDA National Nutrient Database for Standard Reference,')
    ..writeln('// Legacy Release (2018) — kamu malı (CC0). Her satırda fdc_id ve')
    ..writeln('// USDA adı; eşleştirme notları tool/nutrition/ingredient_usda.tsv.')
    ..writeln()
    ..writeln("import 'nutrition.dart';")
    ..writeln()
    ..writeln('const ingredientNutrition = <String, Nutrients>{');
  for (final (name, id, factor, note) in mapping) {
    if (id == '0') {
      out.writeln("  '$name': Nutrients.zero, // $note");
      continue;
    }
    final v = values[id];
    final desc = descriptions[id];
    if (v == null || desc == null || !v.containsKey(_energy)) {
      stderr.writeln('USDA kaydı bulunamadı: $name → $id');
      exit(1);
    }
    double g(String k) => (v[k] ?? 0) * factor;
    out.writeln("  '$name': Nutrients(${_num(g(_energy))}, ${_num(g(_protein))}, "
        '${_num(g(_fat))}, ${_num(g(_carb))}), '
        '// $id $desc${factor == 1 ? '' : ' ×$factor'}');
  }
  out.writeln('};');
  File('$root/lib/data/ingredient_nutrition.g.dart').writeAsStringSync(out.toString());
  stdout.writeln('${mapping.length} malzeme yazıldı.');
}
