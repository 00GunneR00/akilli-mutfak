# Akıllı Mutfak & Sıfır Atık Asistanı

Flutter + Riverpod + Drift (SQLite). Uygulama çevrimdışı öncelikli çalışır;
Supabase aile üyeleri arasında dolap ve alışveriş listesini senkronize eder.

## Supabase

- Proje: `akilli-mutfak` (`nbwddogqixmnsysihktl`, eu-central-1)
- Adres ve publishable anahtar: `lib/core/env.dart` (`--dart-define` ile değiştirilebilir)
- **Gerekli ayar:** Authentication → Sign In / Providers → *Allow anonymous sign-ins* açık olmalı.

### Nasıl çalışır

- Her cihaz ilk açılışta anonim giriş yapar ve yerel hane kimliğiyle haneyi
  oluşturur (`ensure_household`). Aile üyeleri davet koduyla katılır
  (`join_household`); katılanın yerel verisi haneyle birleşir.
- Yerel değişiklikleri SQLite tetikleyicileri `sync_outbox` tablosuna yazar,
  `lib/data/sync.dart` bunları gönderir. Sunucudaki değişiklikler
  `server_updated_at` imleciyle çekilir; Realtime yeni değişiklikleri anında bildirir.
- Çakışmada `updated_at`'i daha yeni olan kazanır. Veriye yalnızca hane üyeleri
  erişebilir (RLS).
- Katalog malzemeleri senkronize edilmez; yalnızca kullanıcının eklediği özel
  malzemeler gönderilir.

## Geliştirme

```sh
flutter pub get
dart run build_runner build   # Drift kodu
flutter test
flutter run
```
