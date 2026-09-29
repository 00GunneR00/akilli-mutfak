import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';
import 'database.dart';
import 'providers.dart';

// Senkronizasyon modeli:
// - Yerel veritabanı tek doğruluk kaynağıdır; uygulama çevrimdışı tam çalışır.
// - Gönderim: SQLite tetikleyicilerinin doldurduğu sync_outbox boşaltılır.
// - Çekim: her tablo için sunucu saatine (server_updated_at) göre imleç.
// - Çakışma: updated_at'i daha yeni olan kazanır (sunucuda tetikleyici,
//   yerelde DoUpdate koşulu).

enum SyncPhase { disabled, connecting, syncing, synced, offline, error }

class SyncState {
  const SyncState({
    this.phase = SyncPhase.connecting,
    this.inviteCode,
    this.lastSyncedAt,
    this.message,
  });

  final SyncPhase phase;
  final String? inviteCode;
  final DateTime? lastSyncedAt;
  final String? message;
}

final syncProvider =
    NotifierProvider<SyncController, SyncState>(SyncController.new);

/// Gönderim sırası önemli: dolap/alışveriş satırları malzemelere başvurur.
const _tables = ['ingredients', 'pantry_items', 'shopping_items', 'meal_plans'];
const _pageSize = 500;

/// Aynı anda işlenen iki sunucu işleminden geç kaydedileni kaçırmamak için
/// imleç biraz geriden başlar; tekrar gelen satırlar zararsızca atlanır.
const _pullOverlap = Duration(seconds: 10);

class SyncController extends Notifier<SyncState> {
  late AppDatabase _db;
  SupabaseClient get _client => Supabase.instance.client;

  String? _householdId;
  RealtimeChannel? _channel;
  StreamSubscription<void>? _localChanges;
  Timer? _debounce;
  Timer? _periodic;
  AppLifecycleListener? _lifecycle;

  bool _running = false;
  bool _again = false;
  bool _pullRequested = false;

  @override
  SyncState build() {
    if (!supabaseReady) return const SyncState(phase: SyncPhase.disabled);
    _db = ref.watch(databaseProvider);
    ref.onDispose(_stop);
    Future.microtask(_start);
    return const SyncState();
  }

  Future<void> _start() async {
    // Uygulama çekim sırasında kapandıysa bayrak kalmış olabilir.
    await _db.removeValue(syncApplyingKey);
    _localChanges = _db
        .tableUpdates(TableUpdateQuery.onAllTables(
            [_db.ingredients, _db.pantryItems, _db.shoppingItems, _db.mealPlans]))
        .listen((_) => _schedule(pull: false));
    _periodic = Timer.periodic(const Duration(minutes: 5), (_) => sync());
    _lifecycle = AppLifecycleListener(onResume: sync);
    await sync();
  }

  void _stop() {
    _debounce?.cancel();
    _periodic?.cancel();
    _localChanges?.cancel();
    _lifecycle?.dispose();
    if (_channel != null) _client.removeChannel(_channel!);
  }

  void _set(SyncState s) {
    if (ref.mounted) state = s;
  }

  void _schedule({required bool pull}) {
    _pullRequested |= pull;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      final p = _pullRequested;
      _pullRequested = false;
      sync(pull: p);
    });
  }

  /// Bekleyen yerel değişiklikleri gönderir, [pull] ise sunucudakileri çeker.
  Future<void> sync({bool pull = true}) async {
    if (state.phase == SyncPhase.disabled) return;
    if (_running) {
      _again = true;
      _pullRequested |= pull;
      return;
    }
    _running = true;
    if (pull) {
      _set(SyncState(
          phase: _householdId == null ? SyncPhase.connecting : SyncPhase.syncing,
          inviteCode: state.inviteCode,
          lastSyncedAt: state.lastSyncedAt));
    }
    try {
      do {
        _again = false;
        if (_householdId == null) {
          await _connect();
          pull = true;
        }
        await _push();
        if (pull || _pullRequested) {
          _pullRequested = false;
          await _pull();
        }
        pull = false;
      } while (_again);
      _set(SyncState(
          phase: SyncPhase.synced,
          inviteCode: state.inviteCode,
          lastSyncedAt: DateTime.now()));
    } catch (e, st) {
      debugPrint('Senkronizasyon hatası: $e\n$st');
      _set(_errorState(e));
    } finally {
      _running = false;
    }
  }

  SyncState _errorState(Object e) {
    final (phase, message) = switch (e) {
      AuthException(:final message) => (SyncPhase.error, 'Giriş yapılamadı: $message'),
      PostgrestException(:final message) => (SyncPhase.error, message),
      _ => (SyncPhase.offline, 'Çevrimdışı — değişiklikler cihazda saklanıyor.'),
    };
    return SyncState(
        phase: phase,
        inviteCode: state.inviteCode,
        lastSyncedAt: state.lastSyncedAt,
        message: message);
  }

  Future<void> _connect() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
    final hh = await _db.householdId();
    final rows = await _client.rpc('ensure_household', params: {'p_id': hh})
        as List<dynamic>;
    final code = (rows.first as Map<String, dynamic>)['invite_code'] as String;
    _set(SyncState(
        phase: state.phase, inviteCode: code, lastSyncedAt: state.lastSyncedAt));
    _householdId = hh;
    _subscribe(hh);
  }

  /// Aile üyelerinin değişiklikleri anında çekilsin.
  void _subscribe(String hh) {
    if (_channel != null) _client.removeChannel(_channel!);
    var channel = _client.channel('household:$hh');
    for (final table in _tables) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'household_id',
            value: hh),
        callback: (_) => _schedule(pull: true),
      );
    }
    _channel = channel.subscribe();
  }

  /// Davet koduyla başka bir haneye katılır; yerel veri o haneye taşınır.
  Future<void> joinHousehold(String code) async {
    final hh = await _client
        .rpc('join_household', params: {'p_code': code.trim()}) as String;
    if (hh == _householdId) return;
    await _db.switchHousehold(hh);
    _householdId = null;
    await sync();
  }

  // ------------------------------------------------------------------ Gönderim

  Future<void> _push() async {
    while (true) {
      final batch = await (_db.select(_db.syncOutbox)
            ..orderBy([(t) => OrderingTerm.asc(t.seq)])
            ..limit(_pageSize))
          .get();
      if (batch.isEmpty) return;
      for (final table in _tables) {
        final ids = [
          for (final e in batch)
            if (e.tbl == table) e.rowId
        ];
        if (ids.isEmpty) continue;
        final rows = await _loadLocal(table, ids);
        if (rows.isEmpty) continue;
        await _client.from(table).upsert(rows,
            onConflict: table == 'ingredients' ? 'household_id,id' : 'id');
      }
      // Gönderim sürerken yeniden değişen satırın seq'i artmıştır; o kalır.
      await _db.batch((b) {
        for (final e in batch) {
          b.deleteWhere(
              _db.syncOutbox,
              (t) =>
                  t.tbl.equals(e.tbl) &
                  t.rowId.equals(e.rowId) &
                  t.seq.equals(e.seq));
        }
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadLocal(
      String table, List<String> ids) async {
    switch (table) {
      case 'ingredients':
        final rows = await (_db.select(_db.ingredients)
              ..where((t) => t.id.isIn(ids)))
            .get();
        return [
          for (final r in rows)
            {
              'household_id': _householdId,
              'id': r.id,
              'name': r.name,
              'category': r.category,
              'emoji': r.emoji,
              'unit': r.unit,
              'default_qty': r.defaultQty,
              'shelf_days': r.shelfDays,
              'popularity': r.popularity,
              'is_custom': r.isCustom,
              'updated_at': _ts(r.updatedAt),
            }
        ];
      case 'pantry_items':
        final rows = await (_db.select(_db.pantryItems)
              ..where((t) => t.id.isIn(ids)))
            .get();
        return [
          for (final r in rows)
            {
              'id': r.id,
              'household_id': r.householdId,
              'ingredient_id': r.ingredientId,
              'quantity': r.quantity,
              'unit': r.unit,
              'expiry_date': _ts(r.expiryDate),
              'added_at': _ts(r.addedAt),
              'outcome': r.outcome,
              'removed_at': _tsOrNull(r.removedAt),
              'updated_at': _ts(r.updatedAt),
              'deleted_at': _tsOrNull(r.deletedAt),
            }
        ];
      case 'shopping_items':
        final rows = await (_db.select(_db.shoppingItems)
              ..where((t) => t.id.isIn(ids)))
            .get();
        return [
          for (final r in rows)
            {
              'id': r.id,
              'household_id': r.householdId,
              'ingredient_id': r.ingredientId,
              'quantity': r.quantity,
              'unit': r.unit,
              'checked_at': _tsOrNull(r.checkedAt),
              'pantry_item_id': r.pantryItemId,
              'source': r.source,
              'created_at': _ts(r.createdAt),
              'updated_at': _ts(r.updatedAt),
              'deleted_at': _tsOrNull(r.deletedAt),
            }
        ];
      case 'meal_plans':
        final rows = await (_db.select(_db.mealPlans)
              ..where((t) => t.id.isIn(ids)))
            .get();
        return [
          for (final r in rows)
            {
              'id': r.id,
              'household_id': r.householdId,
              'day': _day(r.day),
              'recipe_id': r.recipeId,
              'created_at': _ts(r.createdAt),
              'updated_at': _ts(r.updatedAt),
              'deleted_at': _tsOrNull(r.deletedAt),
            }
        ];
    }
    throw ArgumentError(table);
  }

  // --------------------------------------------------------------------- Çekim

  Future<void> _pull() async {
    for (final table in _tables) {
      await _pullTable(table);
    }
  }

  Future<void> _pullTable(String table) async {
    final key = 'sync.pulled.$table';
    final stored = await _db.getValue(key);
    var since = stored == null ? null : DateTime.parse(stored);
    var first = true;
    while (true) {
      var query =
          _client.from(table).select().eq('household_id', _householdId!);
      if (since != null) {
        query = first
            ? query.gte('server_updated_at', _ts(since.subtract(_pullOverlap)))
            : query.gt('server_updated_at', _ts(since));
      }
      final rows = await query
          .order('server_updated_at', ascending: true)
          .limit(_pageSize);
      if (rows.isEmpty) return;
      await applyRemoteRows(_db, table, rows);
      since = DateTime.parse(rows.last['server_updated_at'] as String);
      await _db.setValue(key, _ts(since));
      if (rows.length < _pageSize) return;
      first = false;
    }
  }
}

/// Sunucudan gelen satırları yerel veritabanına yazar; yereldeki daha yeniyse
/// dokunmaz. Tetikleyiciler bu sırada susturulur.
@visibleForTesting
Future<void> applyRemoteRows(
    AppDatabase db, String table, List<Map<String, dynamic>> rows) {
  return db.transaction(() async {
    await db.setValue(syncApplyingKey, '1');
    for (final r in rows) {
      final updatedAt = _dt(r['updated_at']);
      switch (table) {
        case 'ingredients':
          final row = IngredientsCompanion.insert(
            id: r['id'] as String,
            name: r['name'] as String,
            category: r['category'] as String,
            emoji: r['emoji'] as String,
            unit: r['unit'] as String,
            defaultQty: (r['default_qty'] as num).toDouble(),
            shelfDays: r['shelf_days'] as int,
            popularity: Value(r['popularity'] as int),
            isCustom: Value(r['is_custom'] as bool),
            updatedAt: updatedAt,
          );
          await db.into(db.ingredients).insert(row,
              onConflict: DoUpdate((_) => row,
                  where: (old) => old.updatedAt.isSmallerThanValue(updatedAt)));
        case 'pantry_items':
          await _ensureIngredient(db, r);
          final row = PantryItemsCompanion.insert(
            id: r['id'] as String,
            householdId: r['household_id'] as String,
            ingredientId: r['ingredient_id'] as String,
            quantity: (r['quantity'] as num).toDouble(),
            unit: r['unit'] as String,
            expiryDate: _dt(r['expiry_date']),
            addedAt: _dt(r['added_at']),
            outcome: Value(r['outcome'] as String?),
            removedAt: Value(_dtOrNull(r['removed_at'])),
            updatedAt: updatedAt,
            deletedAt: Value(_dtOrNull(r['deleted_at'])),
          );
          await db.into(db.pantryItems).insert(row,
              onConflict: DoUpdate((_) => row,
                  where: (old) => old.updatedAt.isSmallerThanValue(updatedAt)));
        case 'shopping_items':
          await _ensureIngredient(db, r);
          final row = ShoppingItemsCompanion.insert(
            id: r['id'] as String,
            householdId: r['household_id'] as String,
            ingredientId: r['ingredient_id'] as String,
            quantity: (r['quantity'] as num).toDouble(),
            unit: r['unit'] as String,
            checkedAt: Value(_dtOrNull(r['checked_at'])),
            pantryItemId: Value(r['pantry_item_id'] as String?),
            source: Value(r['source'] as String),
            createdAt: _dt(r['created_at']),
            updatedAt: updatedAt,
            deletedAt: Value(_dtOrNull(r['deleted_at'])),
          );
          await db.into(db.shoppingItems).insert(row,
              onConflict: DoUpdate((_) => row,
                  where: (old) => old.updatedAt.isSmallerThanValue(updatedAt)));
        case 'meal_plans':
          final day = (r['day'] as String).split('-').map(int.parse).toList();
          final row = MealPlansCompanion.insert(
            id: r['id'] as String,
            householdId: r['household_id'] as String,
            day: DateTime(day[0], day[1], day[2]),
            recipeId: r['recipe_id'] as String,
            createdAt: _dt(r['created_at']),
            updatedAt: updatedAt,
            deletedAt: Value(_dtOrNull(r['deleted_at'])),
          );
          await db.into(db.mealPlans).insert(row,
              onConflict: DoUpdate((_) => row,
                  where: (old) => old.updatedAt.isSmallerThanValue(updatedAt)));
      }
    }
    await db.removeValue(syncApplyingKey);
  });
}

/// Başka bir cihazın daha yeni kataloğundaki bir malzeme burada yoksa yer
/// tutucu eklenir; gerçek kayıt gelince (updatedAt daha yeni) üzerine yazılır.
Future<void> _ensureIngredient(AppDatabase db, Map<String, dynamic> r) {
  final id = r['ingredient_id'] as String;
  final name = id.replaceFirst('ing_', '').replaceAll('_', ' ');
  return db.into(db.ingredients).insert(
        IngredientsCompanion.insert(
          id: id,
          name: name.isEmpty ? id : name[0].toUpperCase() + name.substring(1),
          category: 'Diğer',
          emoji: '🛒',
          unit: r['unit'] as String,
          defaultQty: 1,
          shelfDays: 30,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        mode: InsertMode.insertOrIgnore,
      );
}

String _ts(DateTime d) => d.toUtc().toIso8601String();
String? _tsOrNull(DateTime? d) => d == null ? null : _ts(d);
DateTime _dt(Object? v) => DateTime.parse(v as String).toLocal();
DateTime? _dtOrNull(Object? v) => v == null ? null : _dt(v);
String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
