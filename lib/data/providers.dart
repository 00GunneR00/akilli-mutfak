import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drift_flutter/drift_flutter.dart';

import '../core/env.dart';
import 'database.dart';
import 'demo_seed.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = demoMode
      ? AppDatabase(driftDatabase(name: 'akilli_mutfak_demo'))
      : AppDatabase();
  if (demoMode) seedDemo(db);
  ref.onDispose(db.close);
  return db;
});

final ingredientsProvider = StreamProvider<List<Ingredient>>(
    (ref) => ref.watch(databaseProvider).watchIngredients());

final frequentProvider = StreamProvider<List<Ingredient>>(
    (ref) => ref.watch(databaseProvider).watchFrequent());

final pantryProvider = StreamProvider<List<PantryEntry>>(
    (ref) => ref.watch(databaseProvider).watchPantry());

final purchaseHistoryProvider = StreamProvider<Map<String, List<DateTime>>>(
    (ref) => ref.watch(databaseProvider).watchPurchaseHistory());

final shoppingProvider = StreamProvider<List<ShoppingEntry>>(
    (ref) => ref.watch(databaseProvider).watchShopping());

/// Geçen ayın başından bu yana dolaptan çıkan ürünler (ay karşılaştırması için).
final removedProvider = StreamProvider<List<PantryEntry>>((ref) {
  final now = DateTime.now();
  return ref
      .watch(databaseProvider)
      .watchRemovedSince(DateTime(now.year, now.month - 1));
});
