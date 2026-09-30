---
name: diyetisyen
description: Akıllı Mutfak uygulamasının haftalık yemek planı önerisi için diyetisyen kuralları — öğün sayısı ve öğünlere enerji dağılımı, her öğünün tabak yapısı (hangi yemek hangisiyle yenir, hangisiyle yenmez), haftalık besin grubu dengesi ve tarif etiketleme şeması. Plan önerisini (lib/features/recipes/meal_planner.dart), plan seçeneklerini, tarif kataloğuna öğün/rol/protein etiketi eklemeyi ya da bir plan önerisinin sağlıklı ve mantıklı olup olmadığını değerlendirmeyi içeren her işte kullan; kullanıcı "öneri kötü", "bu yemekler birlikte olmaz", "öğün", "kalori", "diyet", "beslenme", "porsiyon" dediğinde de kullan.
---

# Diyetisyen — Akıllı Mutfak plan kuralları

Bu skill, uygulamanın yemek planı önerisini klinik diyetisyen bakışıyla kurar ve
denetler. Kurallar Türk mutfağının öğün alışkanlıklarına ve genel sağlıklı
beslenme ilkelerine (Türkiye Beslenme Rehberi – TÜBER, DSÖ önerileri) dayanır.
Hedef kitle **sağlıklı yetişkinlerdir**; uygulama tıbbi beslenme tedavisi
yapmaz (bkz. [Sınırlar](#sınırlar-ve-uyarı)).

Kuralları koda dökerken şu sırayı izle: önce **tarif etiketleri**
([references/etiketleme.md](references/etiketleme.md)), sonra **öğün şablonları**
ve **kesin kurallar** (bu dosya), en son **puanlama** (haftalık denge, çeşitlilik,
dolap). Kesin kuralı ihlal eden bir öğün hiçbir puanla kurtarılamaz — adaydan
elenir.

Örnek iyi/kötü tabaklar ve gerekçeleri: [references/ornekler.md](references/ornekler.md).

---

## 1. Kullanıcıdan alınacak bilgiler

Plan önerisi ekranı şu seçenekleri sormalı (varsayılanlar kalın):

| Seçenek | Değerler | Not |
|---|---|---|
| Günlük enerji | 1200–3500 kcal, **2000** | 1200'ün altı önerilmez. |
| Öğün sayısı | 2, **3**, 4, 5 | Ana öğün + ara öğün düzeni; aşağıdaki tabloya göre. |
| Hedef | Kilo vermek / **Korumak** / Kilo almak | Yalnızca enerji dağılımını ve porsiyon tercihini etkiler, hedef kaloriyi kullanıcı belirler. |
| Tercihler | Vejetaryen, Pratik (≤30 dk), Dolaptakileri kullan, Tatlı | Vejetaryen = et, tavuk, balık, işlenmiş et yok; yumurta ve süt ürünü var. |

Öğün sayısı, öğün **isimlerini** değil **düzenini** seçtirir; kullanıcıya
"Kahvaltı + Öğle + Akşam" gibi okunur bir etiket göster.

## 2. Öğünlere enerji dağılımı

Akşam yemeği Türk ev düzeninde günün en doyurucu öğünüdür; kahvaltı doyurucu
ama öğleden hafif olabilir, öğle yemeği orta ağırlıktadır. Yüzdeler günlük
hedefin payıdır, her öğün **±5 puan** esneyebilir.

| Öğün sayısı | Kahvaltı | Kuşluk (ara) | Öğle | İkindi (ara) | Akşam |
|---|---|---|---|---|---|
| 2 (geç kahvaltı + akşam) | %45 | – | – | – | %55 |
| 3 | %25 | – | %32 | – | %43 |
| 4 | %22 | – | %28 | %10 | %40 |
| 5 | %20 | %8 | %27 | %10 | %35 |

- **Hedef = kilo vermek:** akşamı 5 puan azalt, kahvaltı/öğleye dağıt (akşam
  hâlâ en az öğle kadar olabilir); kızartma ve ağır meze cezasını iki katına çıkar.
- **Hedef = kilo almak:** ara öğünleri tercih et (4–5 öğün), enerji yoğun ara
  öğün (shake, kuruyemişli yoğurt) seç; ana öğünlere tabak eklemek yerine porsiyonu büyüt.
- Günün toplamı hedefin **±%7**'si içinde olmalı; her öğün kendi payının
  **±%15**'i içinde olmalı. Toplamı tutturmak için bir öğünü şişirip diğerini
  boş bırakma.

## 3. Porsiyon ayarı (tabak eklemeden önce)

Enerji açığı/fazlası önce **porsiyon katsayısıyla** kapatılır, sonra tabak
eklenir/çıkarılır:

- Ana yemek porsiyonu: **0,75 · 1 · 1,25 · 1,5** (sadece bu adımlar; kullanıcıya
  "1,5 porsiyon" diye göster).
- Çorba, salata, yan tahıl: 0,75–1,25. Tatlı: 0,5 ya da 1 (bölüm 4 tatlı sınırı).
- Kahvaltı ana tabağı: 0,75–1,5.
- Katsayı 1,5'e çıktığı halde açık %10'dan büyükse **yan tabak** ekle; o da
  yetmiyorsa ve öğün sayısı izin veriyorsa **ara öğünü** büyüt. Bir öğüne asla
  şablondaki üst sınırdan fazla tabak koyma.

## 4. Öğün şablonları

Her öğün aşağıdaki şablonlardan birine uymak **zorundadır**. Rol adları
[etiketleme.md](references/etiketleme.md)'deki `role` değerleridir.

### Kahvaltı (Türk kahvaltısı düzeni — bölüm 4A)
Kahvaltı tabakları `breakfast` etiketiyle ayrılır: `tabak` (kahvaltı tabağı),
`sicak` (yumurtalı sıcak), `hamur` (poğaça, börek, pişi, simit…), `pratik`
(tek başına öğün olan tost vb.), `bati` (yulaf lapası, pankek, avokadolu tost).
Kahvaltı şu üç düzenden biridir; başka birleşim **yasak**:

1. **Türk kahvaltısı:** `tabak` (peynir, zeytin, domates, salatalık, ekmek)
   zorunlu + `sicak` **ya da** `hamur` (hafta içi 2 tabak). Hafta sonu
   `tabak` + `sicak` + `hamur` (3 tabak, "serpme") olabilir.
   - `sicak` ve `hamur` tabak olmadan gelmez (menemen ekmeksiz, poğaça
     peynirsiz sofraya konmaz).
2. **Pratik kahvaltı:** tek bir `pratik` tabak (Kaşarlı Tost, Yumurtalı Ekmek).
3. **Batı tarzı hafif kahvaltı:** tek bir `bati` tabak, **yanına hiçbir şey
   gelmez** (Yulaf Lapası + Peynirli Poğaça gibi tatlı/lapa + tuzlu hamur işi
   uyumsuzdur). Haftada en fazla 2.

- Hazırlığı 30 dakikayı aşan hamur işleri (su böreği, poğaça, pişi, gözleme,
  ıspanaklı börek) **yalnızca hafta sonu**; hafta içi simit, sigara böreği, krep.
- Aynı kahvaltıda en fazla bir yumurtalı tabak.
- Kızartma hamur (pişi, sigara böreği) haftada en fazla 2 kahvaltı.

### Öğle (1–3 tabak, orta ağırlık)
Şunlardan biri:
1. **Tek tabak:** `ana_tek_tabak` (makarna, mantı, dürüm, pide, lahmacun,
   hamburger, pizza, börek, tavuklu pilav) + en fazla 1 `yan_salata`
   (hafif: çoban, roka, mevsim, cacık, ezme).
2. **Ev yemeği:** isteğe bağlı `corba` + `ana_protein` **veya** `baklagil`
   **veya** `sebze_yemegi` + en fazla 1 yan (`yan_tahil` ya da `yan_salata`).
3. **Hafif:** `corba` + `yan_salata` doyurucu ise (ör. Mercimek Çorbası +
   Sezar Salata) — sadece öğle payı ≤ 500 kcal ise.

### Akşam (2–4 tabak, günün en doyurucusu)
- `corba` (varsayılan, 3+ öğünde tercih) +
- tam 1 protein merkezi: `ana_protein` **veya** `baklagil` **veya**
  `ana_tek_tabak` +
- en fazla 1 `yan_tahil` (yalnızca protein merkezi `ana_protein` veya
  `baklagil` ise) +
- en fazla 1 `yan_salata` **veya** `yan_yogurt` (cacık, haydari, yoğurt).
- `sebze_yemegi` (zeytinyağlılar, türlü, ıspanak…) akşamda **ikinci yemek**
  olarak `ana_protein`in yanına gelebilir; bu durumda `yan_tahil` gelmez.
- Etsiz bir `sebze_yemegi` tek başına akşamın protein merkezi olamaz; yanına
  `yan_yogurt` ya da yumurtalı/peynirli bir tabak eklenir, vejetaryen planda
  `baklagil` tercih edilir.

### Ara öğün (1 tabak)
Ara öğün iki ana öğün arasındaki açlığı kapatır, günlük meyve–sebze, süt ve
sağlıklı yağ hedeflerini tamamlar. Ana yemek, çorba veya tatlı ara öğüne
**konmaz**; yalnızca `ara_ogun` rolü kullanılır.

Türler (`snack` etiketi):

| Tür | Örnek | Kural |
|---|---|---|
| `meyve` | mevsim meyvesi, elma + badem | Tek başına meyve yerine bir protein/yağ eşiyle (badem, ceviz, peynir, yoğurt) tercih et — tokluk ve kan şekeri için. |
| `yogurt` | yoğurtlu meyve kasesi, granolalı yoğurt, chia puding | Şekersiz yoğurt/kefir; tatlandırıcı en fazla 1 tatlı kaşığı bal. |
| `smoothie` | meyve/sebze + yoğurt veya kefir | Meyve suyu değil bütün meyve; tek smoothie'de en fazla 2 porsiyon meyve. |
| `shake` | süt bazlı; muz, yulaf, fıstık ezmesi, protein tozu | Enerji yoğun; asıl yeri **kilo alma** hedefi ve ikindi. |
| `kuruyemis` | bir avuç (≈30 g) çiğ/tuzsuz kuruyemiş, kuru meyve + ceviz, leblebi | **Günde en fazla 1** kuruyemiş ağırlıklı ara öğün. |
| `sebze` | sebze çubukları + humus/yoğurt, haşlanmış yumurta + salatalık | Kilo verirken ilk tercih. |
| `tahilli` | tam buğday ekmeğe peynir-domates, simit + ayran | İkindiye uygun; kilo verirken haftada en fazla 2. |

Öğün yeri ve enerji:
- **Kuşluk** (5 öğünde): hafif — `meyve`, `yogurt`, `smoothie`, `sebze`;
  ≈ 100–250 kcal. `shake` ve `tahilli` kuşluğa konmaz.
- **İkindi** (4–5 öğünde): ≈ 150–350 kcal; her tür uygun.
- Ara öğün porsiyonu 0,75–1,5 arası ayarlanabilir.

Hedefe göre:
- **Kilo vermek:** ara öğün (porsiyon ayarından sonra) ≤ 200 kcal; `sebze`,
  `meyve` + protein, `yogurt` öncelikli. `shake` en fazla haftada 1 ve yalnızca
  hafif olan (≤ 250 kcal'lik tarifin 0,75 porsiyonu); hurmalı, fıstık ezmeli,
  yulaflı yoğun shake **yasak**.
- **Korumak:** tüm türler; shake haftada en fazla 3.
- **Kilo almak:** `shake`, `kuruyemis`, `tahilli` öncelikli; ara öğün 300–600 kcal
  olabilir (porsiyon 1,5'e kadar).
- **Protein tozu** içeren tarifler yalnızca "kilo almak" hedefinde önerilir
  (sağlıklı yetişkinin protein ihtiyacı yemekle karşılanır).

Günlük kurallar:
- Aynı gün iki ara öğün **aynı türden** olmaz (iki shake, iki kuruyemiş yok).
- 5 öğünlü planda günde en az 1 ara öğün `meyve`, `smoothie` veya `sebze`
  türünde olmalı (günde ≥ 5 porsiyon sebze-meyve hedefine katkı). 4 öğünlü
  planda (tek ara öğün) bu türler puanla öne çıkarılır; kilo alma hedefinde
  ikindi shake'i serbesttir.
- Aynı ara öğün tarifi haftada en fazla 2 kez.
- Ara öğünün `base` etiketi aynı günün ana öğünleriyle çakışabilir
  (yoğurt, peynir); kural 5 yalnızca aynı öğün içindir.

### Tatlı
- Yalnızca kullanıcı isterse; **haftada en fazla 3**, günde en fazla 1.
- Öğle veya akşam, **sadece o öğün `agir` değilse**. Sütlü tatlılar
  (sütlaç, muhallebi, keşkül) ve meyveli tatlılar önce; şerbetli/çikolatalı
  haftada en fazla 1.
- Tatlının enerjisi günlük hedefin **%10**'unu geçmez; gerekirse **yarım
  porsiyon** verilir, yarım porsiyon da sığmıyorsa o gün tatlı konmaz.

## 4A. Türk mutfağı adetleri

Plan yalnızca besin açısından doğru değil, bir Türk evinde **olağan** da
olmalı. Bu bölüm diğer kurallarla birlikte uygulanır.

**Öğle pratik, akşam ev yemeği.**
- Öğle yemeğinin tabakları **en fazla 45 dakikada** hazırlanır (sote, ızgara,
  makarna, mantı, dürüm, çorba…). Emek isteyen yemekler (dolma, sarma,
  karnıyarık, imam bayıldı, hünkar beğendi, kuru fasulye, fırın yemekleri,
  hamur açılan pide/lahmacun) **yalnızca akşam**: aile sofrası akşam kurulur.
- Pratik yemekler (makarna, köri soslu tavuk, tavuk sote, köfte) kahvaltı
  dışındaki her ana öğüne uyar.
- Akşam sofrası öncelikle **Türk ev yemeği** düzenindedir (çorba + yemek +
  pilav/salata). Akşamda tek tabak (makarna, mantı, lahmacun…) haftada en fazla 2.
- Tek tabak yemeğin yanına (öğle ya da akşam) yalnızca **hafif** salata ya da
  yoğurt gelir; acılı ezme, haydari, piyaz gibi mezeler kebap, köfte, ızgara
  ve balık sofrasınındır (Kıymalı Makarna + Acılı Ezme yok).

**Dünya mutfağı (`world`).** Köri, bolonez, pesto, kremalı makarna, lazanya,
hamburger, pizza, sezar salata gibi tarifler:
- Haftada en fazla 3 ana yemek; aynı gün hem öğle hem akşam olmaz.
- Yanına yalnızca **uyumlu** (`worldOk`) yan gelir: pirinç pilavı, roka,
  çoban/mevsim salatası. Cacık, haydari, piyaz, kısır, bulgur pilavı gibi Türk
  mezeleri ve yanları dünya mutfağı yemeğiyle **eşleşmez** (Köri Soslu Tavuk +
  Cacık yok). Çorba serbesttir (Türk sofrasında çorba her yemekten önce gelir).

**Hafta sonu.** Cumartesi ve pazar kahvaltısı geç ve geniş olur: kahvaltının
enerji payı **+5 puan**, öğlenin **−5 puan** (öğle yoksa akşamdan).

**Gün içi uyum.**
- Öğle ve akşam aynı tarzda olmaz: ikisi de dünya mutfağı, ikisi de
  zeytinyağlı/sebze yemeği ya da ikisi de tek tabak olmasın (puan cezası).
- Öğle akşamdan hafif olmalı: öğlede `agir` ana yemek ancak akşam hafif/orta
  ise.

## 5. Kesin kurallar (ihlal = aday elenir)

Aynı öğün içinde:

1. **Tek protein merkezi:** en fazla 1 `ana_protein`/`baklagil`/`ana_tek_tabak`.
   (İki et yemeği, köfte + tavuk, dürüm + köfte yok.)
2. **Karbonhidrat üst üste binmez:** `ana_tek_tabak` ile `yan_tahil` aynı öğünde
   olmaz (mantı + pilav, makarna + börek, lahmacun + pilav yok). Makarna
   veya hamur bazlı `ana_tek_tabak` yanında hamur işi/ekmek bazlı başka tabak olmaz.
3. **Ağır meze kuralı:** `yan_salata` içinde `agir` işaretli olanlar (Rus
   salatası, patates salatası, humus, Çerkez tavuğu, kısır, piyaz, çiğ köfte,
   mercimek köftesi, şakşuka) bir **meze**dir: günde en fazla 1, yalnızca
   akşam, ve **`agir` ya da `kizartma` ana yemekle birlikte olmaz**. Hafif
   ana yemeğin (ızgara, buğulama, haşlama, sebze) yanına gelebilir.
4. **Fast-food uyumu:** `ana_tek_tabak` içindeki sandviç/dürüm/hamburger/pizza
   (`fastfood: true`) yanına sadece hafif yeşil salata veya ayran/cacık;
   mayonezli salata, çorba zorunlu değil, pilav/patates yok.
5. **Aynı ana bileşen tekrar etmez:** iki tabağın `base` (ana bileşen) etiketi
   aynı olamaz — ör. Mercimek Çorbası + Mercimek Köftesi, Etli Patates +
   Patates Salatası, Kıymalı Makarna + Kıymalı Börek, Yoğurtlu Mantı + Cacık
   (yoğurt + yoğurt).
6. **Kremalı + kremalı yok:** kremalı/beşamelli çorba ile kremalı/beşamelli
   ana yemek (Mantar Çorbası + Kremalı Mantarlı Tavuk) birlikte olmaz.
7. **İki çorba, iki tatlı, iki salata aynı öğünde olmaz.** Et, tavuk ya da
   balık içeren salata (Sezar, Ton Balıklı, Çerkez Tavuğu) bir protein
   merkezinin yanına gelmez; yalnızca öğlenin "çorba + doyurucu salata"
   şablonunda kullanılır.
8. **Kızartma:** bir günde en fazla 1 `kizartma` tabak.
9. **Öğün uygunluğu:** tarifin `meals` listesinde olmayan öğüne konmaz
   (ör. Menemen akşam, Karnıyarık kahvaltı olmaz). Öğlede 45 dakikayı aşan
   tabak olmaz (bölüm 4A).
9a. **Dünya mutfağı eşleşmesi:** `world` ana yemeğin yanında çorba ve tatlı
   dışında yalnızca `worldOk` tabak olur (bölüm 4A).
9b. **Kahvaltı düzeni:** kahvaltı bölüm 4'teki üç düzenden birine uyar.

Hafta içinde:

10. Aynı `ana_protein`/`baklagil`/`ana_tek_tabak` tarifi **haftada en fazla 1 kez**;
    `kahvalti_ana` en fazla 2; çorba ve yanlar en fazla 2. **Kahvaltı Tabağı**
    (`breakfast: tabak`) Türk sofrasının sabitidir, her gün gelebilir ve
    tekrar sayılmaz.
11. Ardışık iki günün **akşam** protein kaynağı aynı olmaz (salı tavuk →
    çarşamba tavuk yok).
12. Vejetaryen / pratik filtreleri istisnasız uygulanır.

## 6. Haftalık denge (puanla ödüllendir / cezalandır)

Tam hafta (7 gün, 3+ öğün) için hedef aralıklar — ana öğünlerin protein
merkezine göre sayılır:

| Grup | Haftalık hedef |
|---|---|
| Balık (`protein: balik`) | **≥ 2** öğün |
| Kuru baklagil (`baklagil` rolü veya `protein: baklagil`) | **≥ 2** öğün |
| Kırmızı et (`kirmizi_et`) | **≤ 3** öğün |
| İşlenmiş et (`islenmis_et`: sucuk, pastırma, döner, hamburger köftesi) | **≤ 1** öğün |
| Tavuk | 2–3 öğün |
| Sebze yemeği veya salata | **her gün ≥ 1** (tercihen öğle ve akşam) |
| Kızartma | **≤ 2** (kahvaltı pişi/sigara böreği dahil) |
| `agir` işaretli ana yemek | **≤ 3** |
| Tatlı | **≤ 3** (kullanıcı isterse) |
| Dünya mutfağı ana yemek | **≤ 3** |
| Akşamda tek tabak | **≤ 2** |
| Batı tarzı kahvaltı | **≤ 2** (kesin) |

Vejetaryen planda balık/et satırları yok sayılır; baklagil hedefi **≥ 4**,
yumurta/süt ürünlü protein her ana öğünde aranır.

Kısa planlarda (7 günden az) hedefleri gün sayısıyla orantıla.

## 6A. Kalori kaynağı (tahmin yasak)

Tarif kalorisi **asla tahmin edilmez** ve kalori sitelerinden (kullanıcı
girdili, 154–593 kcal gibi çelişkili değerler) alınmaz. Hesap:

1. `lib/data/recipe_portions.dart`: tarifin **bir porsiyonunun** her
   malzemesi gram olarak (çiğ, yenilebilir kısım). Standart Türk ev tarifinin
   (çoğunlukla 4 kişilik) miktarları porsiyona bölünür. Porsiyon ölçüleri:
   et/kıyma 100–130 g, balık 150–200 g, kuru baklagil 60–70 g, pilav 60 g çiğ
   pirinç/bulgur, makarna 100 g kuru, çorba 1 kase (250–300 ml), zeytinyağlı
   için tencereye ½–1 çay bardağı yağ (porsiyona 10–20 g).
2. Malzemelerin 100 g değerleri **USDA SR Legacy** (kamu malı) verisinden
   `tool/nutrition/build.dart` ile üretilir (`ingredient_nutrition.g.dart`).
   Türkiye'ye özgü ürünlerin en yakın karşılığı `ingredient_usda.tsv`'de
   gerekçesiyle yazılır (beyaz peynir → feta, kaşar → provolone…).
3. Kaloriyi en çok **yağ** belirler (1 yemek kaşığı ≈ 10 g ≈ 88 kcal);
   yağ miktarını gerçekçi yaz, eksik yazma.
4. Yeni tarif: gramaj ve USDA eşleşmesi olmadan eklenmez (test doğrular).
   Kullanıcı bir değere itiraz ederse gramajları gözden geçir, sonucu elle
   düzeltme.

## 7. Makro çerçeve (veri eklendiğinde)

Tarif başına protein/karbonhidrat/yağ verisi eklenirse günlük hedefler:
karbonhidrat **%45–60**, protein **%12–20** (kilo verirken %18–25),
yağ **%20–35**, eklenmiş şeker **< %10**, lif **≥ 25 g**. Veri yokken bu
bölümü puanlamaya katma; etiketlerle (baklagil, sebze, kızartma) dolaylı sağla.

## 8. Puanlama önerisi (meal_planner.dart)

Kesin kuralları geçen adaylar için (küçük puan = iyi):

```
puan =  3.0 × |gün_kcal − hedef| / hedef
      + 2.0 × Σ_öğün max(0, |öğün_kcal − öğün_hedefi| / öğün_hedefi − 0.15)
      + 0.6 × haftalık_tekrar_sayısı
      + 0.8 × haftalık_denge_ihlali     (tablo 6'da aralık dışına çıkan her grup)
      + 0.3 × (porsiyon_katsayısı ≠ 1 olan tabak sayısı) × 0.25
      − 0.3 × dolap_uyum_oranı          (yalnızca "Dolaptakileri kullan" açıkken)
```

Gün gün açgözlü seçim yerine: önce **akşam protein merkezlerini** tüm hafta
için dağıt (balık ≥ 2, baklagil ≥ 2, ardışık tekrar yok), sonra **öğle
protein planını** yap (7 günde 1 tavuk, 1 kırmızı et, kalanı etsiz: balık,
sebze, baklagil, sütlü/sebzeli makarna — öğlenin pratik yemekleri çoğunlukla
kıymalı olduğundan plan yapılmazsa kırmızı et sınırı aşılır), öğleyi
akşamıyla çakışmayacak şekilde seç, en son kahvaltı ve porsiyonları ayarla.
Tabaklar öğünün enerji bütçesine sığdıkça eklenir (bölüm 3). Yenile (🔄) düğmesi yalnızca o günü aynı kurallarla yeniden kurar ve
haftalık denge tablosunu korur.

## 9. Doğrulama kontrol listesi

Bir öneriyi (kodla ya da elle) değerlendirirken sırayla:

1. Her öğün bir şablona uyuyor mu? Tabak sayısı sınırlar içinde mi?
2. Bölüm 5'teki kesin kuralların hiçbiri ihlal edilmiyor mu?
3. Akşam ≥ öğle ≥ kahvaltı enerji sıralaması (2–3 öğünde) sağlanıyor mu?
4. Gün toplamı ±%7, öğünler ±%15 içinde mi?
5. Haftalık denge tablosu tutuyor mu?
6. Bir insan bu sofrayı "normal bir Türk ev yemeği / öğle arası" olarak görür mü?
   Görmüyorsa hangi kural eksik — kuralı ekle, tek vakayı yamama.

Kod değişikliğinde her kesin kural için `test/recipes_test.dart`'a en az bir
test ekle (rastgele tohumlarla 50+ hafta üretip hiçbir öğünün kuralı
bozmadığını doğrula).

## Sınırlar ve uyarı

- Gebelik/emzirme, 18 yaş altı, diyabet, böbrek/karaciğer hastalığı, yeme
  bozukluğu öyküsü, gıda alerjisi gibi durumlarda plan önerisi **uygun değildir**.
- Uygulama arayüzünde plan önerisi ekranında şu (veya benzeri) not bulunmalı:
  > Öneriler sağlıklı yetişkinler için genel beslenme ilkelerine göre
  > hazırlanır ve tahmini kalori içerir. Özel bir sağlık durumun varsa
  > bir diyetisyene danış.
- Kalori değerleri porsiyon başı tahmindir; kesin değer iddia etme.
- 1200 kcal altı, hızlı kilo kaybı vaadi, "detoks", tek besine dayalı diyet
  önerme.
