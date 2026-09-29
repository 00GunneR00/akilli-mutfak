import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final ingredientsProvider = StreamProvider<List<Ingredient>>(
    (ref) => ref.watch(databaseProvider).watchIngredients());

final frequentProvider = StreamProvider<List<Ingredient>>(
    (ref) => ref.watch(databaseProvider).watchFrequent());

final pantryProvider = StreamProvider<List<PantryEntry>>(
    (ref) => ref.watch(databaseProvider).watchPantry());

final shoppingProvider = StreamProvider<List<ShoppingEntry>>(
    (ref) => ref.watch(databaseProvider).watchShopping());

/// Geçen ayın başından bu yana dolaptan çıkan ürünler (ay karşılaştırması için).
final removedProvider = StreamProvider<List<PantryEntry>>((ref) {
  final now = DateTime.now();
  return ref
      .watch(databaseProvider)
      .watchRemovedSince(DateTime(now.year, now.month - 1));
});
