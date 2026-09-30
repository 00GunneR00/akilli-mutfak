# Tarif etiketleme şeması

Planlayıcı kategoriye (Çorbalar, Tatlılar…) değil, bu etiketlere bakar. Her
tarif `lib/data/recipe_catalog.dart`'ta bu alanlarla işaretlenmelidir. Yeni tarif
eklerken tüm alanlar zorunludur; test, etiketi eksik tarif bırakmaz.

## Alanlar

| Alan | Tip | Değerler |
|---|---|---|
| `role` | tek | `kahvalti_ana`, `kahvalti_yan`, `corba`, `ana_protein`, `ana_tek_tabak`, `baklagil`, `sebze_yemegi`, `yan_tahil`, `yan_salata`, `yan_yogurt`, `tatli`, `ara_ogun` |
| `meals` | küme | `kahvalti`, `ogle`, `aksam`, `ara` — tarifin konabileceği öğünler |
| `weight` | tek | `hafif`, `orta`, `agir` — sindirim/doyuruculuk algısı (kalori değil) |
| `protein` | tek | `kirmizi_et`, `islenmis_et`, `tavuk`, `balik`, `baklagil`, `yumurta`, `sut`, `yok` — tabağın başlıca protein kaynağı |
| `cooking` | tek | `kizartma`, `firin`, `haslama`, `izgara`, `sote`, `zeytinyagli`, `cig`, `diger` |
| `base` | küme | tabağın ana bileşen(ler)i: `mercimek`, `nohut`, `fasulye`, `patates`, `kiyma`, `tavuk`, `yogurt`, `makarna`, `hamur`, `pirinc`, `bulgur`, `patlican`, `peynir`, `yumurta`… (kural 5 için) |
| `creamy` | bool | krema/beşamel ağırlıklı mı (kural 6) |
| `fastfood` | bool | sandviç, dürüm, hamburger, pizza, tost tarzı (kural 4) |
| `snack` | tek | yalnızca `ara_ogun` için: `meyve`, `yogurt`, `smoothie`, `shake`, `kuruyemis`, `sebze`, `tahilli` (SKILL.md ara öğün tablosu) |
| `proteinPowder` | bool | protein tozu içeriyor mu (yalnızca kilo alma hedefinde önerilir) |
| `breakfast` | tek | yalnızca kahvaltılıklar: `tabak`, `sicak`, `hamur`, `pratik`, `bati` (SKILL.md kahvaltı düzeni) |
| `world` | bool | dünya mutfağı (köri, bolonez, pesto, lazanya, hamburger, pizza, sezar…) |
| `worldOk` | bool | dünya mutfağı yemeğinin yanına uyan yan (pirinç pilavı, roka, çoban salatası) |

Öğle/akşam ayrımı için ayrıca tarifin **hazırlık süresi** (`minutes`) kullanılır:
45 dakikayı aşan tabak öğleye konmaz (SKILL.md 4A).

## Rol karar ağacı

1. Kahvaltıda yenen yumurtalı/tost/lapa → `kahvalti_ana`. Kahvaltıya giden
   hamur işi (poğaça, pişi, gözleme, sigara/su böreği dilimi, krep) → `kahvalti_yan`.
2. Çorba → `corba`.
3. Tatlı → `tatli`. Meyve, yoğurt-meyve, smoothie/shake, kuruyemiş → `ara_ogun`.
4. Kendi başına öğün olan tahıl/hamur bazlı tabak (makarna, mantı, lazanya,
   erişte, pide, lahmacun, pizza, hamburger, dürüm, tavuklu pilav, kıymalı
   börek) → `ana_tek_tabak`.
5. Et/tavuk/balık merkezli yemek → `ana_protein` (etli sebze yemekleri de:
   Karnıyarık, Etli Bamya, Patates Oturtma, Kıymalı Kabak, Biber Dolması,
   Etli Lahana Sarması, Kıymalı Ispanak).
6. Kuru baklagil merkezli ana yemek → `baklagil` (Kuru Fasulye, Etli Nohut,
   Barbunya, Yeşil Mercimek Yemeği, Sucuklu Nohut, Pastırmalı Kuru Fasulye).
7. Etsiz sebze yemeği (zeytinyağlılar, türlü, mücver, graten, mantar sote,
   fırın patates, yaprak sarma) → `sebze_yemegi`.
8. Sade pilav/bulgur/şehriye → `yan_tahil`.
9. Cacık, haydari → `yan_yogurt`.
10. Salata ve mezeler → `yan_salata`; ağır olanlara `weight: agir`.

## Belirsiz tarifler — karar tablosu

| Tarif | role | meals | weight | protein | cooking | not |
|---|---|---|---|---|---|---|
| Yoğurtlu Mantı | ana_tek_tabak | ogle, aksam | agir | kirmizi_et | haslama | base: hamur, kiyma, yogurt → cacık/haydari ile olmaz |
| Tavuk Dürüm | ana_tek_tabak | ogle | orta | tavuk | sote | fastfood; akşama konmaz |
| Hamburger | ana_tek_tabak | ogle, aksam | agir | islenmis_et | izgara | fastfood |
| İskender Kebap | ana_tek_tabak | ogle, aksam | agir | islenmis_et | diger | pide içerir → yan_tahil yok |
| Tavuklu Pilav | ana_tek_tabak | ogle, aksam | orta | tavuk | haslama | |
| Kıymalı Börek | ana_tek_tabak | ogle | agir | kirmizi_et | firin | |
| Su Böreği | kahvalti_yan | kahvalti, ogle | agir | sut | firin | öğlede tek tabak + salata |
| Ispanaklı Börek | kahvalti_yan | kahvalti, ogle | orta | sut | firin | |
| Mücver | sebze_yemegi | ogle, aksam | orta | yumurta | kizartma | |
| Çerkez Tavuğu | yan_salata | aksam | agir | tavuk | haslama | meze; ana_protein tavukla olmaz |
| Sezar Salata | yan_salata | ogle | orta | tavuk | cig | öğlede şablon 3 ile tek başına öğün olabilir |
| Ton Balıklı Salata | yan_salata | ogle | orta | balik | cig | öğlede hafif öğün; haftalık balık sayısına sayılmaz |
| Mercimek Köftesi | yan_salata | ogle, aksam | agir | baklagil | cig | meze; base: mercimek, bulgur |
| Etsiz Çiğ Köfte | yan_salata | ogle, aksam | agir | yok | cig | base: bulgur |
| Kısır | yan_salata | ogle, aksam | agir | yok | cig | base: bulgur → Bulgur Pilavı ile olmaz |
| Piyaz | yan_salata | ogle, aksam | agir | baklagil | cig | Izgara Köfte (`orta`, ızgara) ile klasik eşleşme ✔ |
| Ev Yapımı Humus | yan_salata | aksam | agir | baklagil | cig | base: nohut |
| Ev Yapımı Rus Salatası | yan_salata | aksam | agir | yok | cig | mayonezli; fastfood/kızartma ile yasak |
| Patates Salatası | yan_salata | ogle, aksam | agir | yok | cig | base: patates |
| Şakşuka | yan_salata | aksam | agir | yok | kizartma | |
| Fırında Baharatlı Patates | sebze_yemegi | ogle, aksam | orta | yok | firin | protein merkezi değil |
| Tavuk Suyu Çorbası | corba | ogle, aksam | hafif | tavuk | haslama | tavuk ana yemekle base çakışır |
| Düğün Çorbası | corba | ogle, aksam | orta | kirmizi_et | haslama | base: yogurt, et |
| Karnabahar Graten | sebze_yemegi | aksam | orta | sut | firin | creamy |
| Hünkar Beğendi | ana_protein | aksam | agir | kirmizi_et | diger | creamy |
| Kremalı Mantarlı Tavuk / Köri Soslu Tavuk | ana_protein | ogle, aksam | orta | tavuk | sote | creamy |
| Mantar / Brokoli / Balkabağı / Domates Çorbası | corba | ogle, aksam | hafif | sut | haslama | creamy (süt/krema) |
| Yulaf Lapası | kahvalti_ana | kahvalti, ara | hafif | sut | haslama | |
| Pankek / Krep | kahvalti_yan veya kahvalti_ana | kahvalti | orta | yumurta | sote | Pankek = kahvalti_ana (tatlı kahvaltı), Krep = kahvalti_yan |
| Sucuklu Yumurta | kahvalti_ana | kahvalti | agir | islenmis_et | sote | haftalık işlenmiş et sayısına dahil |

## Tipik `weight` referansı

- `hafif`: buğulama/ızgara balık, haşlama, zeytinyağlı sebze, çorbaların çoğu,
  yeşil salatalar, cacık.
- `orta`: sote, fırın tavuk, etli sebze yemekleri, köfte, kuru baklagil,
  börek dilimi.
- `agir`: kızartmalar, kremalı/beşamelli yemekler, mantı, lazanya, iskender,
  hamburger, pizza, pastırmalı/sucuklu yemekler, mayonezli/yağlı mezeler.
