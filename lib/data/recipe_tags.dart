// Tarif etiketleri: plan önerisi kategoriye değil bunlara bakar.
//
// Şema ve karar kuralları: .claude/skills/diyetisyen/references/etiketleme.md
// Her tarifin etiketi olmalı (test ile doğrulanır).

/// Tabağın öğündeki görevi.
enum DishRole {
  kahvaltiAna,
  kahvaltiYan,
  corba,
  anaProtein,
  anaTekTabak,
  baklagil,
  sebzeYemegi,
  yanTahil,
  yanSalata,
  yanYogurt,
  tatli,
  araOgun,
}

/// Tarifin konabileceği öğün türü.
enum Slot { kahvalti, ogle, aksam, ara }

enum Heft { hafif, orta, agir }

enum ProteinSource { kirmiziEt, islenmisEt, tavuk, balik, baklagil, yumurta, sut, yok }

enum Cooking { kizartma, firin, haslama, izgara, sote, zeytinyagli, cig, diger }

enum SnackKind { meyve, yogurt, smoothie, shake, kuruyemis, sebze, tahilli }

/// Kahvaltı düzeni (SKILL.md bölüm 4 kahvaltı): Türk kahvaltısı tabak +
/// sıcak/hamur işi; pratik ve batı tarzı tabaklar tek başına gelir.
enum BreakfastKind { tabak, sicak, hamur, pratik, bati }

class RecipeTags {
  const RecipeTags(
    this.role,
    this.meals,
    this.weight,
    this.protein,
    this.cooking,
    this.base, {
    this.creamy = false,
    this.fastfood = false,
    this.snack,
    this.proteinPowder = false,
    this.breakfast,
    this.world = false,
    this.worldOk = false,
  });

  final DishRole role;
  final Set<Slot> meals;
  final Heft weight;
  final ProteinSource protein;
  final Cooking cooking;

  /// Ana bileşenler; aynı öğünde iki tabakta tekrar edemez.
  final Set<String> base;
  final bool creamy;
  final bool fastfood;
  final SnackKind? snack;
  final bool proteinPowder;
  final BreakfastKind? breakfast;

  /// Dünya mutfağı; yanına yalnızca [worldOk] yanlar gelir (SKILL.md 4A).
  final bool world;
  final bool worldOk;
}

// Kısaltmalar: tablo okunaklı kalsın.
const _k = {Slot.kahvalti};
const _ko = {Slot.kahvalti, Slot.ogle};
const _o = {Slot.ogle};
const _a = {Slot.aksam};
const _oa = {Slot.ogle, Slot.aksam};
const _ara = {Slot.ara};

const _hf = Heft.hafif, _or = Heft.orta, _ag = Heft.agir;

const _et = ProteinSource.kirmiziEt,
    _ise = ProteinSource.islenmisEt,
    _tv = ProteinSource.tavuk,
    _bl = ProteinSource.balik,
    _bk = ProteinSource.baklagil,
    _ym = ProteinSource.yumurta,
    _st = ProteinSource.sut,
    _yk = ProteinSource.yok;

const _kz = Cooking.kizartma,
    _fr = Cooking.firin,
    _hs = Cooking.haslama,
    _iz = Cooking.izgara,
    _so = Cooking.sote,
    _zy = Cooking.zeytinyagli,
    _cg = Cooking.cig,
    _dg = Cooking.diger;

const _corba = DishRole.corba,
    _ap = DishRole.anaProtein,
    _tek = DishRole.anaTekTabak,
    _bak = DishRole.baklagil,
    _seb = DishRole.sebzeYemegi,
    _tah = DishRole.yanTahil,
    _sal = DishRole.yanSalata,
    _yog = DishRole.yanYogurt,
    _tat = DishRole.tatli,
    _kan = DishRole.kahvaltiAna,
    _kyn = DishRole.kahvaltiYan,
    _aro = DishRole.araOgun;

RecipeTags _snack(SnackKind kind, ProteinSource p, Set<String> base,
        {bool powder = false}) =>
    RecipeTags(_aro, _ara, _hf, p, _cg, base, snack: kind, proteinPowder: powder);

final recipeTags = <String, RecipeTags>{
  // ---------------------------------------------------------------- Çorbalar
  'Mercimek Çorbası': const RecipeTags(_corba, _oa, _hf, _bk, _hs, {'mercimek'}),
  'Ezogelin Çorbası': const RecipeTags(_corba, _oa, _hf, _bk, _hs, {'mercimek', 'bulgur'}),
  'Yayla Çorbası': const RecipeTags(_corba, _oa, _hf, _st, _hs, {'yogurt', 'pirinc'}),
  'Domates Çorbası': const RecipeTags(_corba, _oa, _hf, _st, _hs, {'domates'}, creamy: true),
  'Tavuk Suyu Çorbası': const RecipeTags(_corba, _oa, _hf, _tv, _hs, {'tavuk', 'sehriye'}),
  'Mantar Çorbası': const RecipeTags(_corba, _oa, _hf, _st, _hs, {'mantar'}, creamy: true),
  'Tarhana Çorbası': const RecipeTags(_corba, _oa, _hf, _yk, _hs, {'tarhana'}),
  'Yeşil Mercimek Çorbası': const RecipeTags(_corba, _oa, _hf, _bk, _hs, {'mercimek', 'bulgur'}),
  'Şehriye Çorbası': const RecipeTags(_corba, _oa, _hf, _yk, _hs, {'sehriye'}),
  'Brokoli Çorbası': const RecipeTags(_corba, _oa, _hf, _st, _hs, {'brokoli', 'patates'}, creamy: true),
  'Balkabağı Çorbası': const RecipeTags(_corba, _oa, _hf, _st, _hs, {'balkabagi'}, creamy: true),
  'Düğün Çorbası': const RecipeTags(_corba, _oa, _or, _et, _hs, {'yogurt', 'et'}),
  'Sebze Çorbası': const RecipeTags(_corba, _oa, _hf, _yk, _hs, {'patates', 'kabak', 'bezelye'}),

  // ------------------------------------------------------------ Et Yemekleri
  'Karnıyarık': const RecipeTags(_ap, _oa, _or, _et, _kz, {'patlican', 'kiyma'}),
  'İzmir Köfte': const RecipeTags(_ap, _oa, _or, _et, _fr, {'kiyma', 'patates'}),
  'Izgara Köfte': const RecipeTags(_ap, _oa, _or, _et, _iz, {'kiyma'}),
  'Tas Kebabı': const RecipeTags(_ap, _oa, _or, _et, _dg, {'et'}),
  'Etli Patates Yemeği': const RecipeTags(_ap, _oa, _or, _et, _hs, {'et', 'patates'}),
  'Hünkar Beğendi': const RecipeTags(_ap, _a, _ag, _et, _dg, {'et', 'patlican'}, creamy: true),
  'Patlıcan Musakka': const RecipeTags(_ap, _oa, _or, _et, _kz, {'patlican', 'kiyma'}),
  'Sulu Köfte': const RecipeTags(_ap, _oa, _or, _et, _hs, {'kiyma', 'patates', 'pirinc'}),
  'Et Sote': const RecipeTags(_ap, _oa, _or, _et, _so, {'et'}),
  'Orman Kebabı': const RecipeTags(_ap, _oa, _or, _et, _hs, {'et', 'patates', 'bezelye'}),
  'İskender Kebap': const RecipeTags(_tek, _oa, _ag, _ise, _dg, {'et', 'ekmek', 'yogurt'}),
  'Hamburger': const RecipeTags(_tek, _oa, _ag, _ise, _iz, {'kiyma', 'ekmek'}, fastfood: true, world: true),
  'Fırında Kuzu İncik': const RecipeTags(_ap, _a, _ag, _et, _fr, {'et'}),
  'Ciğer Tava': const RecipeTags(_ap, _oa, _or, _et, _kz, {'ciger'}),
  'Kadınbudu Köfte': const RecipeTags(_ap, _oa, _ag, _et, _kz, {'kiyma', 'pirinc'}),
  'Etli Bamya': const RecipeTags(_ap, _oa, _or, _et, _hs, {'et', 'bamya'}),

  // --------------------------------------------------------- Tavuk Yemekleri
  'Tavuk Sote': const RecipeTags(_ap, _oa, _or, _tv, _so, {'tavuk', 'mantar'}),
  'Fırında Patatesli Tavuk': const RecipeTags(_ap, _oa, _or, _tv, _fr, {'tavuk', 'patates'}),
  'Kremalı Mantarlı Tavuk': const RecipeTags(_ap, _oa, _or, _tv, _so, {'tavuk', 'mantar'}, creamy: true, world: true),
  'Tavuk Şiş': const RecipeTags(_ap, _oa, _or, _tv, _iz, {'tavuk'}),
  'Soslu Tavuk Kanat': const RecipeTags(_ap, _oa, _or, _tv, _fr, {'tavuk'}, world: true),
  'Tavuk Dürüm': const RecipeTags(_tek, _o, _or, _tv, _so, {'tavuk', 'ekmek'}, fastfood: true),
  'Köri Soslu Tavuk': const RecipeTags(_ap, _oa, _or, _tv, _so, {'tavuk'}, creamy: true, world: true),
  'Fırında Bütün Tavuk': const RecipeTags(_ap, _a, _or, _tv, _fr, {'tavuk', 'patates'}),
  'Çıtır Tavuk': const RecipeTags(_ap, _oa, _ag, _tv, _kz, {'tavuk'}),
  'Tavuk Haşlama': const RecipeTags(_ap, _oa, _hf, _tv, _hs, {'tavuk', 'patates'}),

  // ------------------------------------------------------------ Balık & Deniz
  'Fırında Somon': const RecipeTags(_ap, _oa, _or, _bl, _fr, {'balik'}),
  'Hamsi Tava': const RecipeTags(_ap, _oa, _or, _bl, _kz, {'balik'}),
  'Fırında Levrek': const RecipeTags(_ap, _oa, _hf, _bl, _fr, {'balik'}),
  'Çipura Buğulama': const RecipeTags(_ap, _oa, _hf, _bl, _hs, {'balik'}),
  'Palamut Buğulama': const RecipeTags(_ap, _oa, _hf, _bl, _hs, {'balik'}),
  'Karides Güveç': const RecipeTags(_ap, _oa, _or, _bl, _fr, {'karides', 'mantar'}),
  'Kalamar Tava': const RecipeTags(_ap, _oa, _ag, _bl, _kz, {'kalamar'}),
  'Tereyağlı Karides': const RecipeTags(_ap, _oa, _or, _bl, _so, {'karides'}),

  // --------------------------------------------------------- Sebze Yemekleri
  'Zeytinyağlı Taze Fasulye': const RecipeTags(_seb, _oa, _hf, _yk, _zy, {'taze_fasulye'}),
  'Kıymalı Ispanak': const RecipeTags(_ap, _oa, _or, _et, _hs, {'ispanak', 'kiyma'}),
  'İmam Bayıldı': const RecipeTags(_seb, _oa, _or, _yk, _zy, {'patlican'}),
  'Türlü': const RecipeTags(_seb, _oa, _hf, _yk, _hs, {'patlican', 'patates', 'kabak'}),
  'Mücver': const RecipeTags(_seb, _oa, _or, _ym, _kz, {'kabak'}),
  'Zeytinyağlı Pırasa': const RecipeTags(_seb, _oa, _hf, _yk, _zy, {'pirasa'}),
  'Zeytinyağlı Enginar': const RecipeTags(_seb, _oa, _hf, _yk, _zy, {'enginar'}),
  'Bezelye Yemeği': const RecipeTags(_seb, _oa, _hf, _yk, _hs, {'bezelye', 'patates'}),
  'Karnabahar Graten': const RecipeTags(_seb, _a, _or, _st, _fr, {'karnabahar'}, creamy: true),
  'Fırında Baharatlı Patates': const RecipeTags(_seb, _oa, _or, _yk, _fr, {'patates'}),
  'Kıymalı Kabak': const RecipeTags(_ap, _oa, _or, _et, _hs, {'kabak', 'kiyma'}),
  'Mantar Sote': const RecipeTags(_seb, _oa, _hf, _yk, _so, {'mantar'}),
  'Etli Lahana Sarması': const RecipeTags(_ap, _oa, _or, _et, _hs, {'lahana', 'kiyma', 'pirinc'}),
  'Biber Dolması': const RecipeTags(_ap, _oa, _or, _et, _hs, {'kiyma', 'pirinc'}),
  'Zeytinyağlı Yaprak Sarma': const RecipeTags(_seb, _oa, _or, _yk, _zy, {'pirinc'}),
  'Patates Oturtma': const RecipeTags(_ap, _oa, _or, _et, _kz, {'patates', 'kiyma'}),

  // ---------------------------------------------------------------- Bakliyat
  'Kuru Fasulye': const RecipeTags(_bak, _oa, _or, _bk, _hs, {'fasulye'}),
  'Etli Nohut': const RecipeTags(_bak, _oa, _or, _et, _hs, {'nohut', 'et'}),
  'Zeytinyağlı Barbunya': const RecipeTags(_bak, _oa, _hf, _bk, _zy, {'barbunya'}),
  'Yeşil Mercimek Yemeği': const RecipeTags(_bak, _oa, _or, _bk, _hs, {'mercimek', 'bulgur'}),
  'Pastırmalı Kuru Fasulye': const RecipeTags(_bak, _oa, _ag, _ise, _hs, {'fasulye'}),
  'Sucuklu Nohut': const RecipeTags(_bak, _oa, _ag, _ise, _so, {'nohut'}),

  // --------------------------------------------------------- Pilav & Makarna
  'Pirinç Pilavı': const RecipeTags(_tah, _oa, _or, _yk, _hs, {'pirinc'}, worldOk: true),
  'Bulgur Pilavı': const RecipeTags(_tah, _oa, _or, _yk, _hs, {'bulgur'}),
  'Tavuklu Pilav': const RecipeTags(_tek, _oa, _or, _tv, _hs, {'pirinc', 'tavuk', 'nohut'}),
  'İç Pilav': const RecipeTags(_tah, _a, _or, _yk, _hs, {'pirinc'}),
  'Nohutlu Pilav': const RecipeTags(_tah, _oa, _or, _bk, _hs, {'pirinc', 'nohut'}),
  'Şehriye Pilavı': const RecipeTags(_tah, _oa, _or, _yk, _hs, {'sehriye'}),
  'Kıymalı Makarna': const RecipeTags(_tek, _oa, _or, _et, _hs, {'makarna', 'kiyma'}),
  'Fırın Makarna': const RecipeTags(_tek, _oa, _ag, _st, _fr, {'makarna'}, creamy: true),
  'Spagetti Bolonez': const RecipeTags(_tek, _oa, _or, _et, _hs, {'makarna', 'kiyma'}, world: true),
  'Kremalı Mantarlı Makarna': const RecipeTags(_tek, _oa, _ag, _st, _so, {'makarna', 'mantar'}, creamy: true, world: true),
  'Lazanya': const RecipeTags(_tek, _oa, _ag, _et, _fr, {'makarna', 'kiyma'}, creamy: true, world: true),
  'Yoğurtlu Mantı': const RecipeTags(_tek, _oa, _ag, _et, _hs, {'hamur', 'kiyma', 'yogurt'}),
  'Cevizli Erişte': const RecipeTags(_tek, _oa, _or, _st, _hs, {'makarna', 'peynir'}),
  'Pesto Soslu Makarna': const RecipeTags(_tek, _oa, _or, _st, _hs, {'makarna'}, world: true),
  'Domates Soslu Spagetti': const RecipeTags(_tek, _oa, _or, _yk, _hs, {'makarna'}, world: true),

  // --------------------------------------------------------------- Hamur İşi
  'Su Böreği': const RecipeTags(_kyn, _ko, _ag, _st, _fr, {'hamur', 'peynir'}, breakfast: BreakfastKind.hamur),
  'Sigara Böreği': const RecipeTags(_kyn, _k, _or, _st, _kz, {'hamur', 'peynir'}, breakfast: BreakfastKind.hamur),
  'Ispanaklı Börek': const RecipeTags(_kyn, _ko, _or, _st, _fr, {'hamur', 'ispanak'}, breakfast: BreakfastKind.hamur),
  'Kıymalı Börek': const RecipeTags(_tek, _oa, _ag, _et, _fr, {'hamur', 'kiyma'}),
  'Peynirli Poğaça': const RecipeTags(_kyn, _k, _or, _st, _fr, {'hamur', 'peynir'}, breakfast: BreakfastKind.hamur),
  'Pişi': const RecipeTags(_kyn, _k, _or, _yk, _kz, {'hamur'}, breakfast: BreakfastKind.hamur),
  'Peynirli Gözleme': const RecipeTags(_kyn, _ko, _or, _st, _so, {'hamur', 'peynir'}, breakfast: BreakfastKind.hamur),
  'Kaşarlı Pide': const RecipeTags(_tek, _oa, _ag, _st, _fr, {'hamur', 'peynir'}),
  'Lahmacun': const RecipeTags(_tek, _oa, _or, _et, _fr, {'hamur', 'kiyma'}),
  'Ev Yapımı Pizza': const RecipeTags(_tek, _oa, _ag, _ise, _fr, {'hamur', 'peynir'}, fastfood: true, world: true),
  'Krep': const RecipeTags(_kyn, _k, _or, _ym, _so, {'hamur'}, breakfast: BreakfastKind.hamur),

  // ------------------------------------------------------------- Kahvaltılık
  'Menemen': const RecipeTags(_kan, _k, _or, _ym, _so, {'yumurta', 'domates'}, breakfast: BreakfastKind.sicak),
  'Sucuklu Yumurta': const RecipeTags(_kan, _k, _ag, _ise, _so, {'yumurta'}, breakfast: BreakfastKind.sicak),
  'Peynirli Omlet': const RecipeTags(_kan, _k, _or, _ym, _so, {'yumurta', 'peynir'}, breakfast: BreakfastKind.sicak),
  'Çılbır': const RecipeTags(_kan, _k, _or, _ym, _hs, {'yumurta', 'yogurt'}, breakfast: BreakfastKind.sicak),
  'Pankek': const RecipeTags(_kan, _k, _or, _ym, _so, {'hamur'}, world: true, breakfast: BreakfastKind.bati),
  'Kaşarlı Tost': const RecipeTags(_kan, _k, _or, _st, _iz, {'ekmek', 'peynir'}, breakfast: BreakfastKind.pratik),
  'Yulaf Lapası': const RecipeTags(_kan, _k, _hf, _st, _hs, {'yulaf'}, world: true, breakfast: BreakfastKind.bati),
  'Yumurtalı Ekmek': const RecipeTags(_kan, _k, _or, _ym, _kz, {'ekmek', 'yumurta'}, breakfast: BreakfastKind.pratik),
  'Kahvaltı Tabağı': const RecipeTags(_kan, _k, _hf, _st, _cg,
      {'kahvalti_tabagi'}, breakfast: BreakfastKind.tabak),
  'Haşlanmış Yumurta': const RecipeTags(_kan, _k, _hf, _ym, _hs, {'yumurta'},
      breakfast: BreakfastKind.sicak),
  'Susamlı Simit': const RecipeTags(_kyn, _k, _or, _yk, _fr, {'hamur'},
      breakfast: BreakfastKind.hamur),
  'Avokadolu Tost': const RecipeTags(_kan, _k, _or, _ym, _cg, {'ekmek', 'yumurta'}, world: true, breakfast: BreakfastKind.bati),

  // ----------------------------------------------------------- Salata & Meze
  'Çoban Salatası': const RecipeTags(_sal, _oa, _hf, _yk, _cg, {'domates', 'salatalik'}, worldOk: true),
  'Gavurdağı Salatası': const RecipeTags(_sal, _oa, _hf, _yk, _cg, {'domates', 'ceviz'}),
  'Kısır': const RecipeTags(_sal, _oa, _ag, _yk, _cg, {'bulgur'}),
  'Patates Salatası': const RecipeTags(_sal, _oa, _ag, _yk, _cg, {'patates'}),
  'Etsiz Çiğ Köfte': const RecipeTags(_sal, _oa, _ag, _yk, _cg, {'bulgur'}),
  'Mercimek Köftesi': const RecipeTags(_sal, _oa, _ag, _bk, _cg, {'mercimek', 'bulgur'}),
  'Ev Yapımı Humus': const RecipeTags(_sal, _a, _ag, _bk, _cg, {'nohut'}),
  'Ev Yapımı Haydari': const RecipeTags(_yog, _oa, _or, _st, _cg, {'yogurt', 'peynir'}),
  'Şakşuka': const RecipeTags(_sal, _a, _ag, _yk, _kz, {'patlican', 'patates'}),
  'Ev Yapımı Rus Salatası': const RecipeTags(_sal, _a, _ag, _yk, _cg, {'patates'}),
  'Ton Balıklı Salata': const RecipeTags(_sal, _o, _or, _bl, _cg, {'balik'}),
  'Çerkez Tavuğu': const RecipeTags(_sal, _a, _ag, _tv, _hs, {'tavuk', 'ceviz'}),
  'Piyaz': const RecipeTags(_sal, _oa, _ag, _bk, _cg, {'fasulye'}),
  'Cacık': const RecipeTags(_yog, _oa, _hf, _st, _cg, {'yogurt', 'salatalik'}),
  'Roka Salatası': const RecipeTags(_sal, _oa, _hf, _st, _cg, {'roka'}, worldOk: true),
  'Sezar Salata': const RecipeTags(_sal, _o, _or, _tv, _cg, {'tavuk', 'ekmek'}, world: true),
  'Babagannuş': const RecipeTags(_sal, _a, _or, _yk, _cg, {'patlican'}),
  'Ev Yapımı Acılı Ezme': const RecipeTags(_sal, _oa, _or, _yk, _cg, {'domates'}),
  'Semizotu Salatası': const RecipeTags(_yog, _oa, _hf, _st, _cg, {'yogurt', 'semizotu'}),

  // ---------------------------------------------------------------- Tatlılar
  // agir = şerbetli / çikolatalı / yağlı helva (haftada en fazla 1).
  'Fırın Sütlaç': const RecipeTags(_tat, _oa, _or, _st, _fr, {'sut', 'pirinc'}),
  'İrmik Helvası': const RecipeTags(_tat, _oa, _or, _st, _so, {'irmik'}),
  'Revani': const RecipeTags(_tat, _oa, _ag, _ym, _fr, {'irmik'}),
  'Kakaolu Kek': const RecipeTags(_tat, _oa, _ag, _ym, _fr, {'hamur'}),
  'Supangle': const RecipeTags(_tat, _oa, _ag, _st, _hs, {'sut'}),
  'Muhallebi': const RecipeTags(_tat, _oa, _hf, _st, _hs, {'sut'}),
  'Keşkül': const RecipeTags(_tat, _oa, _or, _st, _hs, {'sut'}),
  'Fırında Elma Tatlısı': const RecipeTags(_tat, _oa, _hf, _yk, _fr, {'elma'}),
  'Un Helvası': const RecipeTags(_tat, _oa, _ag, _st, _so, {'un'}),
  'Brownie': const RecipeTags(_tat, _oa, _ag, _ym, _fr, {'hamur'}),
  'Un Kurabiyesi': const RecipeTags(_tat, _oa, _or, _yk, _fr, {'hamur'}),
  'Aşure': const RecipeTags(_tat, _oa, _or, _bk, _hs, {'bugday'}),
  'Çilekli Magnolia': const RecipeTags(_tat, _oa, _or, _st, _hs, {'sut'}, creamy: true),

  // ---------------------------------------------------------------- Ara Öğün
  'Muzlu Süt Shake': _snack(SnackKind.shake, _st, {'sut', 'muz'}),
  'Yulaflı Muz Shake': _snack(SnackKind.shake, _st, {'sut', 'muz', 'yulaf'}),
  'Fıstık Ezmeli Protein Shake':
      _snack(SnackKind.shake, _st, {'sut', 'muz'}, powder: true),
  'Kakaolu Muz Protein Shake':
      _snack(SnackKind.shake, _st, {'sut', 'muz'}, powder: true),
  'Hurmalı Kilo Aldıran Shake': _snack(SnackKind.shake, _st, {'sut', 'hurma'}),
  'Çilekli Yoğurt Smoothie': _snack(SnackKind.smoothie, _st, {'yogurt', 'cilek'}),
  'Orman Meyveli Kefir Smoothie': _snack(SnackKind.smoothie, _st, {'kefir'}),
  'Yeşil Smoothie': _snack(SnackKind.smoothie, _yk, {'ispanak', 'elma'}),
  'Mangolu Yoğurt Smoothie': _snack(SnackKind.smoothie, _st, {'yogurt', 'mango'}),
  'Yoğurtlu Meyve Kasesi': _snack(SnackKind.yogurt, _st, {'yogurt'}),
  'Granolalı Yoğurt': _snack(SnackKind.yogurt, _st, {'yogurt', 'granola'}),
  'Chialı Puding': _snack(SnackKind.yogurt, _st, {'sut', 'chia'}),
  'Elma ve Badem': _snack(SnackKind.meyve, _yk, {'elma', 'badem'}),
  'Muz ve Fıstık Ezmesi': _snack(SnackKind.meyve, _yk, {'muz'}),
  'Karpuz ve Beyaz Peynir': _snack(SnackKind.meyve, _st, {'karpuz', 'peynir'}),
  'Lorlu Armut': _snack(SnackKind.meyve, _st, {'armut', 'peynir'}),
  'Mevsim Meyve Tabağı': _snack(SnackKind.meyve, _yk, {'meyve'}),
  'Kuru Meyve ve Ceviz': _snack(SnackKind.kuruyemis, _yk, {'kuru_meyve', 'ceviz'}),
  'Bir Avuç Kuruyemiş': _snack(SnackKind.kuruyemis, _yk, {'kuruyemis'}),
  'Leblebi ve Kuru Üzüm': _snack(SnackKind.kuruyemis, _bk, {'leblebi'}),
  'Humuslu Sebze Çubukları': _snack(SnackKind.sebze, _bk, {'havuc', 'nohut'}),
  'Yoğurt Soslu Sebze Çubukları': _snack(SnackKind.sebze, _st, {'havuc', 'yogurt'}),
  'Haşlanmış Yumurta ve Salatalık': _snack(SnackKind.sebze, _ym, {'yumurta'}),
  'Peynirli Tam Buğday Dilimi': _snack(SnackKind.tahilli, _st, {'ekmek', 'peynir'}),
  'Simit ve Ayran': _snack(SnackKind.tahilli, _st, {'ekmek', 'yogurt'}),
};
