import 'package:akilli_mutfak/core/text.dart';
import 'package:akilli_mutfak/data/demo_seed.dart';
import 'package:akilli_mutfak/data/seed_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo verisindeki ürünler katalogda var', () {
    final ids = {for (final s in seedIngredients) slugId(s.name)};
    expect(demoNames().where((n) => !ids.contains(slugId(n))), isEmpty);
  });
}
