import 'package:akilli_mutfak/data/database.dart';
import 'package:akilli_mutfak/data/providers.dart';
import 'package:akilli_mutfak/data/seed_catalog.dart';
import 'package:akilli_mutfak/features/quick_add/quick_add_screen.dart';
import 'package:akilli_mutfak/main.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('uygulama açılır, senkronizasyon kapalıyken bulut simgesi yok',
      (tester) async {
    await initializeDateFormatting('tr');
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(),
        closeStreamsSynchronously: true));
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const AkilliMutfakApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Dolabım'), findsOneWidget);
    expect(find.byTooltip('Senkronize'), findsNothing);
  });

  testWidgets('hızlı eklemede kaydırdıkça kategori çipi değişir', (tester) async {
    await initializeDateFormatting('tr');
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(),
        closeStreamsSynchronously: true));
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: QuickAddScreen(target: AddTarget.pantry)),
    ));
    await tester.pumpAndSettle();

    bool selected(String title) => tester
        .widget<ChoiceChip>(find.ancestor(
            of: find.textContaining(title), matching: find.byType(ChoiceChip)))
        .selected;
    final first = categoryShelfDays.keys.first;

    expect(selected('Sık aldıkların'), isTrue);

    // Sık alınanlar bitene kadar kaydır: sıradaki kategori seçilmeli.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(selected('Sık aldıkların'), isFalse);
    expect(selected(first), isTrue);

    // Çipe dokununca o bölüme gidilir.
    final chip = find.ancestor(
        of: find.textContaining('İçecek'), matching: find.byType(ChoiceChip));
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(selected('İçecek'), isTrue);
    expect(find.text('Su'), findsWidgets);
  });
}
