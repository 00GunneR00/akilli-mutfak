# Akıllı Mutfak & Sıfır Atık Asistanı

Evdeki yiyecekleri takip eden, alışveriş listesini ve haftalık yemek planını dolaba göre kuran, ne kadar yiyeceğin çöpe gittiğini gösteren Flutter uygulaması. Çevrimdışı öncelikli çalışır; aile üyeleri aynı dolabı ve alışveriş listesini ortak kullanır.

Temel fikir veri girişini en aza indirmek: fiş okutma ya da tek tek yazma yok. Alışveriş listesinde işaretlenen ürün dolaba geçer, sık alınanlar tek dokunuşla eklenir.

## Özellikler

**Dolap**
- Ürünler, miktarları ve "var / azaldı" durumu
- "Bitmiş olabilir" önerisi: ürünün her zamanki alım aralığına göre tahmin edilir
- Dolaptan çıkarırken "bitti" ya da "çöpe gitti" olarak işaretleme; biten ürün alışveriş listesine eklenir

**Hızlı ekleme**
- Kategori ızgarası ve sık alınanlar
- Türkçe karakterlere duyarlı arama
- Seçilenler sepette toplanır, dolaba ya da alışveriş listesine birlikte eklenir

**Alışveriş listesi**
- Listede alınan ürünler dolaba aktarılır
- Aile üyeleriyle ortak ve anlık güncellenen liste

**Yemekler**
- Tarifleri dolaptakilerle eşleştirme: eksiği en az olanlar önce gelir
- 7 günlük yemek planı
- Plan önerisi: kalori, öğün sayısı, hedef ve tercihlere göre; öğün dağılımı, tabak yapısı ve haftalık besin dengesi kurallarıyla
- Porsiyon başına enerji ve makro değerleri (USDA verisinden hesaplanır)

**Özet**
- Aylık israf özeti: bu ay ve geçen ay karşılaştırması, en çok israf edilen ürünler

**Aile paylaşımı**
- Davet koduyla haneye katılma; katılanın verisi haneyle birleşir
- Hesap açmak gerekmez

## Teknolojiler

| Katman | Kullanılanlar |
|---|---|
| Uygulama | Flutter, Riverpod |
| Yerel veritabanı | Drift (SQLite) |
| Senkronizasyon | Supabase: PostgreSQL, anonim giriş, Realtime, RLS |

## Klasör yapısı

```
lib/
  core/                Tema, tarih ve metin yardımcıları, ortam ayarları
  data/                Veritabanı, senkronizasyon, ürün ve tarif kataloğu, besin değerleri
  features/
    pantry/            Dolap
    quick_add/         Hızlı ekleme
    shopping/          Alışveriş listesi
    recipes/           Tarifler, yemek planı ve plan önerisi
    stats/             İsraf özeti
    household/         Hane ve senkronizasyon durumu
test/                  Testler
tool/nutrition/        USDA verisinden besin değeri tablosu üreten betik
```

## Senkronizasyon

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

### Supabase ayarları

- Proje: `akilli-mutfak` (`nbwddogqixmnsysihktl`, eu-central-1)
- Adres ve publishable anahtar: `lib/core/env.dart` (`--dart-define` ile değiştirilebilir)
- **Gerekli ayar:** Authentication → Sign In / Providers → *Allow anonymous sign-ins* açık olmalı.

## Geliştirme

```sh
flutter pub get
dart run build_runner build   # Drift kodu
flutter test
flutter run
```

Farklı bir Supabase projesiyle çalıştırmak için:

```sh
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
```

Tanıtım modu, senkronizasyon olmadan ayrı bir yerel veritabanını örnek veriyle doldurur:

```sh
flutter run --dart-define=DEMO=true
```
