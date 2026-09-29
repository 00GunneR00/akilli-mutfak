import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/dates.dart';
import '../../core/ui.dart';
import '../../data/sync.dart';

/// Başlıktaki bulut simgesi: senkronizasyon durumunu gösterir, hane ekranını açar.
class SyncStatusButton extends ConsumerWidget {
  const SyncStatusButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(syncProvider.select((s) => s.phase));
    if (phase == SyncPhase.disabled) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final (icon, tooltip, color) = switch (phase) {
      SyncPhase.synced => (Icons.cloud_done_rounded, 'Senkronize', scheme.primary),
      SyncPhase.offline =>
        (Icons.cloud_off_rounded, 'Çevrimdışı', scheme.onSurfaceVariant),
      SyncPhase.error => (
          Icons.sync_problem_rounded,
          'Senkronizasyon hatası',
          Freshness.expired.color
        ),
      _ => (Icons.cloud_sync_rounded, 'Senkronize ediliyor', scheme.primary),
    };
    return IconButton(
      style: IconButton.styleFrom(
        backgroundColor: scheme.surface,
        side: BorderSide(color: scheme.outlineVariant),
        fixedSize: const Size(46, 46),
      ),
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const HouseholdScreen())),
    );
  }
}

class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({super.key});

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen> {
  final _code = TextEditingController();
  bool _joining = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _code.text.trim();
    if (code.length < 6) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Haneye katıl'),
        content: const Text(
            'Dolabın ve alışveriş listen bu haneyle birleşecek. Devam edilsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Katıl')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _joining = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(syncProvider.notifier).joinHousehold(code);
      _code.clear();
      messenger.showSnackBar(
          const SnackBar(content: Text('Haneye katıldın 🎉')));
    } on PostgrestException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Katılınamadı; internet bağlantını kontrol et.')));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(syncProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final code = sync.inviteCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Hane & senkronizasyon')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.family_restroom_rounded, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Davet kodun',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.18)),
                      icon: const Icon(Icons.copy_rounded, color: Colors.white),
                      tooltip: 'Kopyala',
                      onPressed: code == null
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Kod kopyalandı')));
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SelectableText(
                    code ?? '······',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        letterSpacing: 10,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aile üyelerin bu kodla hanene katılıp aynı dolabı ve '
                  'alışveriş listesini görebilir.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              leading: _statusIcon(sync.phase, scheme),
              title: Text(_statusText(sync),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(sync.message ??
                  'Değişiklikler cihazında saklanır, internet olunca eşitlenir.'),
              trailing: IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Şimdi senkronize et',
                onPressed: () => ref.read(syncProvider.notifier).sync(),
              ),
            ),
          ),
          const SectionTitle('Bir haneye katıl',
              padding: EdgeInsets.fromLTRB(4, 28, 4, 12)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      hintText: 'KOD',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _join(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _joining || code == null ? null : _join,
                    icon: _joining
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.group_add_rounded),
                    label: const Text('Haneye katıl'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(SyncPhase phase, ColorScheme scheme) {
    final (icon, color) = switch (phase) {
      SyncPhase.synced => (Icons.cloud_done_rounded, scheme.primary),
      SyncPhase.offline => (Icons.cloud_off_rounded, scheme.onSurfaceVariant),
      SyncPhase.error => (Icons.sync_problem_rounded, Freshness.expired.color),
      _ => (null, scheme.primary),
    };
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: icon != null
          ? Icon(icon, color: color)
          : const SizedBox.square(
              dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  String _statusText(SyncState s) => switch (s.phase) {
        SyncPhase.disabled => 'Senkronizasyon kapalı',
        SyncPhase.connecting => 'Bağlanıyor…',
        SyncPhase.syncing => 'Senkronize ediliyor…',
        SyncPhase.offline => 'Çevrimdışı',
        SyncPhase.error => 'Senkronizasyon hatası',
        SyncPhase.synced => s.lastSyncedAt == null
            ? 'Senkronize'
            : 'Senkronize · ${TimeOfDay.fromDateTime(s.lastSyncedAt!).format(context)}',
      };
}
