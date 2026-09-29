// Gömülü yemek listesi.
//
// Yemek adları ve malzeme listeleri genel mutfak bilgisidir; yapılış adımları
// için her yemek nefisyemektarifleri.com'da aranır ([recipeUrl]). Kategoriler
// o sitenin tarif kategorilerine göre düzenlendi.
//
// Malzemeler `seed_catalog.dart`'taki ürün adlarıyla birebir aynı olmalıdır
// (test ile doğrulanır); dolaptaki ürünlerle eşleşme bu adlar üzerinden yapılır.

import '../core/text.dart';

typedef Recipe = ({
  String id,
  String name,
  String category,
  String emoji,
  int minutes,
  List<String> ingredients,
});

/// Kategori → emoji; sıra ekrandaki filtre çiplerinin sırasıdır.
const recipeCategories = <String, String>{
  'Çorbalar': '🍲',
  'Et Yemekleri': '🥩',
  'Tavuk Yemekleri': '🍗',
  'Balık & Deniz': '🐟',
  'Sebze Yemekleri': '🥦',
  'Bakliyat': '🫘',
  'Pilav & Makarna': '🍝',
  'Hamur İşi': '🥟',
  'Kahvaltılık': '🍳',
  'Salata & Meze': '🥗',
  'Tatlılar': '🍮',
};

/// Çoğu evde bulunan, dolapta takip edilmesi beklenmeyen temel malzemeler;
/// "eksik" sayılmaz.
const pantryStaples = {
  'Tuz', 'Karabiber', 'Pul Biber', 'Kimyon', 'Kekik', 'Kuru Nane', 'Sumak',
  'Tatlı Toz Biber', 'İsot', 'Tarçın', 'Yenibahar', 'Defne Yaprağı',
  'Ayçiçek Yağı', 'Zeytinyağı', 'Toz Şeker', 'Sirke', 'Vanilin',
  'Kabartma Tozu',
};

String recipeUrl(Recipe r) =>
    'https://www.nefisyemektarifleri.com/ara/?s=${Uri.encodeQueryComponent(r.name)}';

Recipe _r(String name, String category, String emoji, int minutes,
        List<String> ingredients) =>
    (
      id: 'rcp_${slugId(name).substring(4)}',
      name: name,
      category: category,
      emoji: emoji,
      minutes: minutes,
      ingredients: ingredients,
    );

const _corba = 'Çorbalar';
const _et = 'Et Yemekleri';
const _tavuk = 'Tavuk Yemekleri';
const _balik = 'Balık & Deniz';
const _sebze = 'Sebze Yemekleri';
const _bakliyat = 'Bakliyat';
const _pilav = 'Pilav & Makarna';
const _hamur = 'Hamur İşi';
const _kahvalti = 'Kahvaltılık';
const _salata = 'Salata & Meze';
const _tatli = 'Tatlılar';

final recipes = <Recipe>[
  // ---------------------------------------------------------------- Çorbalar
  _r('Mercimek Çorbası', _corba, '🍲', 40, ['Kırmızı Mercimek', 'Soğan', 'Havuç', 'Patates', 'Tereyağı', 'Un', 'Limon', 'Pul Biber', 'Tuz']),
  _r('Ezogelin Çorbası', _corba, '🍲', 45, ['Kırmızı Mercimek', 'Bulgur', 'Pirinç', 'Soğan', 'Domates Salçası', 'Biber Salçası', 'Tereyağı', 'Kuru Nane', 'Pul Biber', 'Tuz']),
  _r('Yayla Çorbası', _corba, '🥣', 35, ['Yoğurt', 'Pirinç', 'Yumurta', 'Un', 'Tereyağı', 'Kuru Nane', 'Tuz']),
  _r('Domates Çorbası', _corba, '🍅', 30, ['Domates', 'Domates Salçası', 'Un', 'Tereyağı', 'Süt', 'Kaşar Peyniri', 'Tuz']),
  _r('Tavuk Suyu Çorbası', _corba, '🍲', 60, ['Tavuk But', 'Tel Şehriye', 'Havuç', 'Limon', 'Yumurta', 'Un', 'Tuz', 'Karabiber']),
  _r('Mantar Çorbası', _corba, '🍄', 30, ['Mantar', 'Soğan', 'Tereyağı', 'Un', 'Süt', 'Krema', 'Tuz', 'Karabiber']),
  _r('Tarhana Çorbası', _corba, '🥣', 20, ['Tarhana', 'Domates Salçası', 'Tereyağı', 'Sarımsak', 'Kuru Nane', 'Tuz']),
  _r('Yeşil Mercimek Çorbası', _corba, '🍲', 50, ['Yeşil Mercimek', 'Soğan', 'Havuç', 'Bulgur', 'Domates Salçası', 'Kuru Nane', 'Tuz']),
  _r('Şehriye Çorbası', _corba, '🍲', 25, ['Şehriye', 'Domates', 'Domates Salçası', 'Tereyağı', 'Limon', 'Maydanoz', 'Tuz']),
  _r('Brokoli Çorbası', _corba, '🥦', 30, ['Brokoli', 'Patates', 'Soğan', 'Süt', 'Tereyağı', 'Un', 'Tuz']),
  _r('Balkabağı Çorbası', _corba, '🎃', 40, ['Balkabağı', 'Soğan', 'Havuç', 'Krema', 'Tereyağı', 'Taze Zencefil', 'Tuz']),
  _r('Düğün Çorbası', _corba, '🍲', 90, ['Kuşbaşı Et', 'Yoğurt', 'Yumurta', 'Un', 'Limon', 'Tereyağı', 'Pul Biber', 'Tuz']),
  _r('Sebze Çorbası', _corba, '🥕', 35, ['Patates', 'Havuç', 'Kabak', 'Bezelye', 'Soğan', 'Domates Salçası', 'Tuz']),

  // ------------------------------------------------------------ Et Yemekleri
  _r('Karnıyarık', _et, '🍆', 70, ['Patlıcan', 'Kıyma', 'Soğan', 'Domates', 'Sivri Biber', 'Sarımsak', 'Domates Salçası', 'Maydanoz', 'Ayçiçek Yağı', 'Tuz', 'Karabiber']),
  _r('İzmir Köfte', _et, '🧆', 60, ['Kıyma', 'Patates', 'Domates', 'Sivri Biber', 'Soğan', 'Galeta Unu', 'Yumurta', 'Domates Salçası', 'Kimyon', 'Tuz']),
  _r('Izgara Köfte', _et, '🧆', 30, ['Kıyma', 'Soğan', 'Galeta Unu', 'Yumurta', 'Maydanoz', 'Kimyon', 'Tuz', 'Karabiber']),
  _r('Tas Kebabı', _et, '🥘', 90, ['Kuşbaşı Et', 'Soğan', 'Domates', 'Sivri Biber', 'Domates Salçası', 'Tereyağı', 'Tuz', 'Karabiber']),
  _r('Etli Patates Yemeği', _et, '🥔', 60, ['Kuşbaşı Et', 'Patates', 'Soğan', 'Domates Salçası', 'Tuz']),
  _r('Hünkar Beğendi', _et, '🥘', 90, ['Kuşbaşı Et', 'Patlıcan', 'Süt', 'Un', 'Tereyağı', 'Kaşar Peyniri', 'Soğan', 'Domates', 'Domates Salçası', 'Tuz']),
  _r('Patlıcan Musakka', _et, '🍆', 70, ['Patlıcan', 'Kıyma', 'Soğan', 'Domates', 'Sivri Biber', 'Domates Salçası', 'Ayçiçek Yağı', 'Tuz']),
  _r('Sulu Köfte', _et, '🍲', 50, ['Kıyma', 'Pirinç', 'Soğan', 'Patates', 'Havuç', 'Domates Salçası', 'Un', 'Limon', 'Tuz']),
  _r('Et Sote', _et, '🥩', 40, ['Kuşbaşı Et', 'Soğan', 'Sivri Biber', 'Domates', 'Tereyağı', 'Kekik', 'Tuz']),
  _r('Orman Kebabı', _et, '🥘', 90, ['Kuşbaşı Et', 'Patates', 'Bezelye', 'Havuç', 'Soğan', 'Domates Salçası', 'Tuz']),
  _r('İskender Kebap', _et, '🥙', 40, ['Dana Döner', 'Pide', 'Yoğurt', 'Tereyağı', 'Domates Salçası', 'Domates', 'Tuz']),
  _r('Hamburger', _et, '🍔', 30, ['Hamburger Köftesi', 'Hamburger Ekmeği', 'Marul', 'Domates', 'Kornişon Turşu', 'Cheddar', 'Ketçap', 'Mayonez', 'Kırmızı Soğan']),
  _r('Fırında Kuzu İncik', _et, '🍖', 180, ['Kuzu İncik', 'Soğan', 'Havuç', 'Sarımsak', 'Domates Salçası', 'Biberiye', 'Tuz']),
  _r('Ciğer Tava', _et, '🍳', 20, ['Ciğer', 'Un', 'Kırmızı Soğan', 'Maydanoz', 'Sumak', 'Ayçiçek Yağı', 'Tuz']),
  _r('Kadınbudu Köfte', _et, '🧆', 60, ['Kıyma', 'Pirinç', 'Soğan', 'Yumurta', 'Un', 'Ayçiçek Yağı', 'Kimyon', 'Tuz']),
  _r('Etli Bamya', _et, '🥘', 60, ['Bamya', 'Kuşbaşı Et', 'Soğan', 'Domates', 'Domates Salçası', 'Limon', 'Tuz']),

  // --------------------------------------------------------- Tavuk Yemekleri
  _r('Tavuk Sote', _tavuk, '🍗', 35, ['Tavuk Göğsü', 'Soğan', 'Kapya Biber', 'Sivri Biber', 'Domates', 'Mantar', 'Tereyağı', 'Tuz', 'Karabiber']),
  _r('Fırında Patatesli Tavuk', _tavuk, '🍗', 60, ['Tavuk But', 'Patates', 'Soğan', 'Domates Salçası', 'Sarımsak', 'Zeytinyağı', 'Kekik', 'Tuz']),
  _r('Kremalı Mantarlı Tavuk', _tavuk, '🍗', 35, ['Tavuk Göğsü', 'Mantar', 'Krema', 'Soğan', 'Tereyağı', 'Kaşar Peyniri', 'Tuz']),
  _r('Tavuk Şiş', _tavuk, '🍢', 40, ['Tavuk Göğsü', 'Yoğurt', 'Domates Salçası', 'Sarımsak', 'Kapya Biber', 'Soğan', 'Zeytinyağı', 'Kekik', 'Tuz']),
  _r('Soslu Tavuk Kanat', _tavuk, '🍗', 45, ['Tavuk Kanat', 'Domates Salçası', 'Bal', 'Soya Sosu', 'Sarımsak', 'Tatlı Toz Biber', 'Tuz']),
  _r('Tavuk Dürüm', _tavuk, '🌯', 25, ['Tavuk Göğsü', 'Lavaş', 'Marul', 'Domates', 'Kırmızı Soğan', 'Kapya Biber', 'Mayonez', 'Tuz']),
  _r('Köri Soslu Tavuk', _tavuk, '🍛', 30, ['Tavuk Göğsü', 'Krema', 'Köri', 'Soğan', 'Kapya Biber', 'Tuz']),
  _r('Fırında Bütün Tavuk', _tavuk, '🐔', 90, ['Bütün Tavuk', 'Tereyağı', 'Sarımsak', 'Limon', 'Biberiye', 'Patates', 'Tuz']),
  _r('Çıtır Tavuk', _tavuk, '🍗', 30, ['Tavuk Bonfile', 'Un', 'Yumurta', 'Galeta Unu', 'Ayçiçek Yağı', 'Tatlı Toz Biber', 'Tuz']),
  _r('Tavuk Haşlama', _tavuk, '🍲', 50, ['Tavuk But', 'Patates', 'Havuç', 'Soğan', 'Limon', 'Tuz', 'Karabiber']),

  // ------------------------------------------------------------ Balık & Deniz
  _r('Fırında Somon', _balik, '🐟', 25, ['Somon', 'Limon', 'Tereyağı', 'Sarımsak', 'Dereotu', 'Tuz']),
  _r('Hamsi Tava', _balik, '🐟', 20, ['Hamsi', 'Mısır Unu', 'Ayçiçek Yağı', 'Limon', 'Kırmızı Soğan', 'Tuz']),
  _r('Fırında Levrek', _balik, '🐟', 35, ['Levrek', 'Domates', 'Soğan', 'Limon', 'Zeytinyağı', 'Defne Yaprağı', 'Tuz']),
  _r('Çipura Buğulama', _balik, '🐟', 40, ['Çipura', 'Domates', 'Soğan', 'Sivri Biber', 'Limon', 'Tereyağı', 'Tuz']),
  _r('Palamut Buğulama', _balik, '🐟', 40, ['Palamut', 'Domates', 'Soğan', 'Sivri Biber', 'Limon', 'Zeytinyağı', 'Tuz']),
  _r('Karides Güveç', _balik, '🦐', 30, ['Karides', 'Mantar', 'Domates', 'Sivri Biber', 'Sarımsak', 'Kaşar Peyniri', 'Tereyağı', 'Tuz']),
  _r('Kalamar Tava', _balik, '🦑', 20, ['Kalamar', 'Un', 'Maden Suyu', 'Ayçiçek Yağı', 'Limon', 'Tuz']),
  _r('Tereyağlı Karides', _balik, '🦐', 15, ['Karides', 'Tereyağı', 'Sarımsak', 'Pul Biber', 'Maydanoz', 'Tuz']),

  // --------------------------------------------------------- Sebze Yemekleri
  _r('Zeytinyağlı Taze Fasulye', _sebze, '🫛', 60, ['Taze Fasulye', 'Domates', 'Soğan', 'Zeytinyağı', 'Toz Şeker', 'Tuz']),
  _r('Kıymalı Ispanak', _sebze, '🥬', 40, ['Ispanak', 'Kıyma', 'Soğan', 'Pirinç', 'Domates Salçası', 'Yoğurt', 'Tuz']),
  _r('İmam Bayıldı', _sebze, '🍆', 70, ['Patlıcan', 'Soğan', 'Domates', 'Sarımsak', 'Sivri Biber', 'Maydanoz', 'Zeytinyağı', 'Toz Şeker', 'Tuz']),
  _r('Türlü', _sebze, '🥘', 70, ['Patlıcan', 'Kabak', 'Patates', 'Taze Fasulye', 'Domates', 'Sivri Biber', 'Soğan', 'Domates Salçası', 'Tuz']),
  _r('Mücver', _sebze, '🥒', 35, ['Kabak', 'Yumurta', 'Un', 'Beyaz Peynir', 'Taze Soğan', 'Dereotu', 'Ayçiçek Yağı', 'Tuz']),
  _r('Zeytinyağlı Pırasa', _sebze, '🥬', 45, ['Pırasa', 'Havuç', 'Pirinç', 'Limon', 'Zeytinyağı', 'Toz Şeker', 'Tuz']),
  _r('Zeytinyağlı Enginar', _sebze, '🥬', 50, ['Enginar', 'Havuç', 'Bezelye', 'Patates', 'Limon', 'Dereotu', 'Zeytinyağı', 'Tuz']),
  _r('Bezelye Yemeği', _sebze, '🫛', 45, ['Bezelye', 'Havuç', 'Patates', 'Soğan', 'Domates Salçası', 'Tuz']),
  _r('Karnabahar Graten', _sebze, '🥦', 45, ['Karnabahar', 'Süt', 'Un', 'Tereyağı', 'Kaşar Peyniri', 'Tuz']),
  _r('Fırında Baharatlı Patates', _sebze, '🥔', 45, ['Patates', 'Sarımsak', 'Zeytinyağı', 'Kekik', 'Tatlı Toz Biber', 'Tuz']),
  _r('Kıymalı Kabak', _sebze, '🥒', 40, ['Kabak', 'Kıyma', 'Soğan', 'Domates', 'Pirinç', 'Dereotu', 'Tuz']),
  _r('Mantar Sote', _sebze, '🍄', 20, ['Mantar', 'Tereyağı', 'Sarımsak', 'Kapya Biber', 'Kekik', 'Tuz']),
  _r('Etli Lahana Sarması', _sebze, '🥬', 90, ['Lahana', 'Kıyma', 'Pirinç', 'Soğan', 'Domates Salçası', 'Kuru Nane', 'Tuz']),
  _r('Biber Dolması', _sebze, '🫑', 70, ['Dolmalık Biber', 'Kıyma', 'Pirinç', 'Soğan', 'Domates', 'Domates Salçası', 'Maydanoz', 'Tuz']),
  _r('Zeytinyağlı Yaprak Sarma', _sebze, '🍃', 120, ['Asma Yaprağı', 'Pirinç', 'Soğan', 'Kuru Üzüm', 'Limon', 'Maydanoz', 'Dereotu', 'Zeytinyağı', 'Kuru Nane', 'Tarçın', 'Tuz']),
  _r('Patates Oturtma', _sebze, '🥔', 50, ['Patates', 'Kıyma', 'Soğan', 'Domates', 'Sivri Biber', 'Domates Salçası', 'Tuz']),

  // ---------------------------------------------------------------- Bakliyat
  _r('Kuru Fasulye', _bakliyat, '🫘', 120, ['Kuru Fasulye', 'Soğan', 'Domates Salçası', 'Biber Salçası', 'Tereyağı', 'Pul Biber', 'Tuz']),
  _r('Etli Nohut', _bakliyat, '🫘', 100, ['Nohut', 'Kuşbaşı Et', 'Soğan', 'Domates Salçası', 'Tereyağı', 'Tuz']),
  _r('Zeytinyağlı Barbunya', _bakliyat, '🫘', 60, ['Barbunya', 'Havuç', 'Patates', 'Soğan', 'Domates', 'Zeytinyağı', 'Tuz']),
  _r('Yeşil Mercimek Yemeği', _bakliyat, '🫘', 50, ['Yeşil Mercimek', 'Soğan', 'Bulgur', 'Domates Salçası', 'Kuru Nane', 'Tuz']),
  _r('Pastırmalı Kuru Fasulye', _bakliyat, '🫘', 120, ['Kuru Fasulye', 'Pastırma', 'Soğan', 'Domates Salçası', 'Tereyağı', 'Tuz']),
  _r('Sucuklu Nohut', _bakliyat, '🫘', 30, ['Nohut Konservesi', 'Sucuk', 'Soğan', 'Domates Salçası', 'Tuz']),

  // --------------------------------------------------------- Pilav & Makarna
  _r('Pirinç Pilavı', _pilav, '🍚', 30, ['Pirinç', 'Tel Şehriye', 'Tereyağı', 'Tuz']),
  _r('Bulgur Pilavı', _pilav, '🍚', 30, ['Bulgur', 'Soğan', 'Domates', 'Sivri Biber', 'Domates Salçası', 'Tereyağı', 'Tuz']),
  _r('Tavuklu Pilav', _pilav, '🍚', 50, ['Pirinç', 'Tavuk Göğsü', 'Nohut', 'Tereyağı', 'Tuz', 'Karabiber']),
  _r('İç Pilav', _pilav, '🍚', 45, ['Pirinç', 'Soğan', 'Kuru Üzüm', 'Antep Fıstığı', 'Tereyağı', 'Tarçın', 'Yenibahar', 'Tuz']),
  _r('Nohutlu Pilav', _pilav, '🍚', 30, ['Pirinç', 'Nohut', 'Tereyağı', 'Tuz']),
  _r('Şehriye Pilavı', _pilav, '🍚', 25, ['Şehriye', 'Tereyağı', 'Domates Salçası', 'Tuz']),
  _r('Kıymalı Makarna', _pilav, '🍝', 30, ['Makarna', 'Kıyma', 'Soğan', 'Domates', 'Domates Salçası', 'Tuz']),
  _r('Fırın Makarna', _pilav, '🍝', 50, ['Makarna', 'Süt', 'Un', 'Tereyağı', 'Yumurta', 'Kaşar Peyniri', 'Tuz']),
  _r('Spagetti Bolonez', _pilav, '🍝', 45, ['Spagetti', 'Kıyma', 'Soğan', 'Havuç', 'Domates', 'Sarımsak', 'Domates Salçası', 'Zeytinyağı', 'Parmesan', 'Tuz']),
  _r('Kremalı Mantarlı Makarna', _pilav, '🍝', 25, ['Penne', 'Mantar', 'Krema', 'Sarımsak', 'Tereyağı', 'Parmesan', 'Tuz']),
  _r('Lazanya', _pilav, '🍝', 90, ['Lazanya', 'Kıyma', 'Soğan', 'Domates', 'Domates Salçası', 'Süt', 'Un', 'Tereyağı', 'Kaşar Peyniri', 'Tuz']),
  _r('Yoğurtlu Mantı', _pilav, '🥟', 25, ['Mantı', 'Yoğurt', 'Sarımsak', 'Tereyağı', 'Domates Salçası', 'Pul Biber', 'Kuru Nane']),
  _r('Cevizli Erişte', _pilav, '🍝', 20, ['Erişte', 'Tereyağı', 'Ceviz', 'Lor Peyniri', 'Tuz']),
  _r('Pesto Soslu Makarna', _pilav, '🍝', 20, ['Penne', 'Pesto', 'Parmesan', 'Cherry Domates', 'Tuz']),
  _r('Domates Soslu Spagetti', _pilav, '🍝', 20, ['Spagetti', 'Domates', 'Sarımsak', 'Fesleğen', 'Zeytinyağı', 'Tuz']),

  // --------------------------------------------------------------- Hamur İşi
  _r('Su Böreği', _hamur, '🥧', 120, ['Yufka', 'Yumurta', 'Süt', 'Beyaz Peynir', 'Maydanoz', 'Tereyağı', 'Tuz']),
  _r('Sigara Böreği', _hamur, '🥟', 30, ['Yufka', 'Beyaz Peynir', 'Maydanoz', 'Ayçiçek Yağı']),
  _r('Ispanaklı Börek', _hamur, '🥧', 50, ['Yufka', 'Ispanak', 'Soğan', 'Beyaz Peynir', 'Yumurta', 'Süt', 'Ayçiçek Yağı', 'Tuz']),
  _r('Kıymalı Börek', _hamur, '🥧', 60, ['Yufka', 'Kıyma', 'Soğan', 'Yumurta', 'Süt', 'Ayçiçek Yağı', 'Tuz']),
  _r('Peynirli Poğaça', _hamur, '🥐', 50, ['Un', 'Yoğurt', 'Yumurta', 'Beyaz Peynir', 'Maydanoz', 'Ayçiçek Yağı', 'Kabartma Tozu', 'Tuz']),
  _r('Pişi', _hamur, '🫓', 45, ['Un', 'Maya', 'Süt', 'Ayçiçek Yağı', 'Toz Şeker', 'Tuz']),
  _r('Peynirli Gözleme', _hamur, '🫓', 40, ['Yufka', 'Beyaz Peynir', 'Maydanoz', 'Tereyağı']),
  _r('Kaşarlı Pide', _hamur, '🫓', 60, ['Un', 'Maya', 'Süt', 'Kaşar Peyniri', 'Yumurta', 'Tereyağı', 'Tuz']),
  _r('Lahmacun', _hamur, '🫓', 60, ['Un', 'Maya', 'Kıyma', 'Soğan', 'Domates', 'Sivri Biber', 'Maydanoz', 'Domates Salçası', 'Limon', 'Tuz']),
  _r('Ev Yapımı Pizza', _hamur, '🍕', 50, ['Un', 'Maya', 'Domates Salçası', 'Mozzarella', 'Sucuk', 'Mantar', 'Kapya Biber', 'Zeytin', 'Zeytinyağı', 'Kekik']),
  _r('Krep', _hamur, '🥞', 20, ['Un', 'Süt', 'Yumurta', 'Tereyağı', 'Tuz']),

  // ------------------------------------------------------------- Kahvaltılık
  _r('Menemen', _kahvalti, '🍳', 20, ['Yumurta', 'Domates', 'Sivri Biber', 'Tereyağı', 'Pul Biber', 'Tuz']),
  _r('Sucuklu Yumurta', _kahvalti, '🍳', 10, ['Sucuk', 'Yumurta', 'Tereyağı']),
  _r('Peynirli Omlet', _kahvalti, '🍳', 10, ['Yumurta', 'Süt', 'Kaşar Peyniri', 'Tereyağı', 'Tuz']),
  _r('Çılbır', _kahvalti, '🍳', 15, ['Yumurta', 'Yoğurt', 'Sarımsak', 'Tereyağı', 'Pul Biber', 'Sirke']),
  _r('Pankek', _kahvalti, '🥞', 20, ['Un', 'Süt', 'Yumurta', 'Tereyağı', 'Bal', 'Toz Şeker', 'Kabartma Tozu']),
  _r('Kaşarlı Tost', _kahvalti, '🥪', 10, ['Tost Ekmeği', 'Kaşar Peyniri', 'Tereyağı']),
  _r('Yulaf Lapası', _kahvalti, '🥣', 10, ['Yulaf', 'Süt', 'Muz', 'Bal', 'Tarçın']),
  _r('Yumurtalı Ekmek', _kahvalti, '🍞', 15, ['Ekmek', 'Yumurta', 'Süt', 'Ayçiçek Yağı', 'Tuz']),
  _r('Avokadolu Tost', _kahvalti, '🥑', 10, ['Ekşi Mayalı Ekmek', 'Avokado', 'Yumurta', 'Limon', 'Pul Biber', 'Tuz']),

  // ----------------------------------------------------------- Salata & Meze
  _r('Çoban Salatası', _salata, '🥗', 10, ['Domates', 'Salatalık', 'Sivri Biber', 'Kırmızı Soğan', 'Maydanoz', 'Limon', 'Zeytinyağı', 'Tuz']),
  _r('Gavurdağı Salatası', _salata, '🥗', 15, ['Domates', 'Ceviz', 'Kırmızı Soğan', 'Sivri Biber', 'Maydanoz', 'Nar Ekşisi', 'Zeytinyağı', 'Sumak', 'Tuz']),
  _r('Kısır', _salata, '🥗', 30, ['Köftelik Bulgur', 'Domates Salçası', 'Biber Salçası', 'Taze Soğan', 'Maydanoz', 'Taze Nane', 'Nar Ekşisi', 'Limon', 'Marul', 'Zeytinyağı', 'Tuz']),
  _r('Patates Salatası', _salata, '🥔', 30, ['Patates', 'Taze Soğan', 'Maydanoz', 'Dereotu', 'Limon', 'Zeytinyağı', 'Pul Biber', 'Tuz']),
  _r('Etsiz Çiğ Köfte', _salata, '🌯', 45, ['Köftelik Bulgur', 'İsot', 'Biber Salçası', 'Domates Salçası', 'Soğan', 'Sarımsak', 'Nar Ekşisi', 'Maydanoz', 'Marul', 'Limon']),
  _r('Mercimek Köftesi', _salata, '🥙', 45, ['Kırmızı Mercimek', 'Köftelik Bulgur', 'Soğan', 'Taze Soğan', 'Maydanoz', 'Domates Salçası', 'Biber Salçası', 'Limon', 'Marul', 'Kimyon', 'Tuz']),
  _r('Ev Yapımı Humus', _salata, '🥣', 20, ['Nohut', 'Tahin', 'Limon', 'Sarımsak', 'Zeytinyağı', 'Kimyon', 'Tuz']),
  _r('Ev Yapımı Haydari', _salata, '🥣', 10, ['Süzme Yoğurt', 'Beyaz Peynir', 'Sarımsak', 'Dereotu', 'Taze Nane', 'Zeytinyağı']),
  _r('Şakşuka', _salata, '🍆', 40, ['Patlıcan', 'Kabak', 'Patates', 'Kapya Biber', 'Domates', 'Sarımsak', 'Yoğurt', 'Ayçiçek Yağı', 'Tuz']),
  _r('Ev Yapımı Rus Salatası', _salata, '🥗', 30, ['Patates', 'Havuç', 'Bezelye', 'Kornişon Turşu', 'Mayonez', 'Yoğurt', 'Tuz']),
  _r('Ton Balıklı Salata', _salata, '🥗', 10, ['Ton Balığı', 'Marul', 'Mısır Konservesi', 'Domates', 'Salatalık', 'Limon', 'Zeytinyağı']),
  _r('Çerkez Tavuğu', _salata, '🍗', 60, ['Tavuk Göğsü', 'Ceviz', 'Ekmek', 'Sarımsak', 'Tatlı Toz Biber', 'Tuz']),
  _r('Piyaz', _salata, '🫘', 20, ['Kuru Fasulye', 'Kırmızı Soğan', 'Maydanoz', 'Domates', 'Yumurta', 'Sirke', 'Zeytinyağı', 'Sumak', 'Tuz']),
  _r('Cacık', _salata, '🥒', 10, ['Yoğurt', 'Salatalık', 'Sarımsak', 'Kuru Nane', 'Zeytinyağı', 'Tuz']),
  _r('Roka Salatası', _salata, '🥗', 10, ['Roka', 'Domates', 'Parmesan', 'Limon', 'Nar Ekşisi', 'Zeytinyağı']),
  _r('Sezar Salata', _salata, '🥗', 20, ['Marul', 'Tavuk Göğsü', 'Parmesan', 'Ekmek', 'Mayonez', 'Limon', 'Sarımsak']),
  _r('Babagannuş', _salata, '🍆', 30, ['Patlıcan', 'Tahin', 'Sarımsak', 'Limon', 'Maydanoz', 'Zeytinyağı']),
  _r('Ev Yapımı Acılı Ezme', _salata, '🌶️', 15, ['Domates', 'Sivri Biber', 'Kırmızı Soğan', 'Maydanoz', 'Biber Salçası', 'Nar Ekşisi', 'Zeytinyağı', 'Pul Biber', 'İsot']),
  _r('Semizotu Salatası', _salata, '🌿', 10, ['Semizotu', 'Yoğurt', 'Sarımsak', 'Zeytinyağı', 'Tuz']),

  // ---------------------------------------------------------------- Tatlılar
  _r('Fırın Sütlaç', _tatli, '🍮', 45, ['Süt', 'Pirinç', 'Nişasta', 'Toz Şeker', 'Vanilin', 'Tarçın']),
  _r('İrmik Helvası', _tatli, '🍮', 30, ['İrmik', 'Tereyağı', 'Süt', 'Fındık', 'Toz Şeker']),
  _r('Revani', _tatli, '🍰', 60, ['İrmik', 'Un', 'Yumurta', 'Yoğurt', 'Limon', 'Hindistan Cevizi', 'Toz Şeker', 'Kabartma Tozu']),
  _r('Kakaolu Kek', _tatli, '🍰', 50, ['Un', 'Yumurta', 'Süt', 'Kakao', 'Ayçiçek Yağı', 'Toz Şeker', 'Kabartma Tozu', 'Vanilin']),
  _r('Supangle', _tatli, '🍫', 30, ['Süt', 'Kakao', 'Un', 'Nişasta', 'Tereyağı', 'Bisküvi', 'Damla Çikolata', 'Toz Şeker']),
  _r('Muhallebi', _tatli, '🍮', 30, ['Süt', 'Nişasta', 'Pirinç Unu', 'Toz Şeker', 'Vanilin', 'Tarçın']),
  _r('Keşkül', _tatli, '🍮', 30, ['Süt', 'Badem', 'Pirinç Unu', 'Hindistan Cevizi', 'Toz Şeker']),
  _r('Fırında Elma Tatlısı', _tatli, '🍎', 40, ['Elma', 'Ceviz', 'Tereyağı', 'Toz Şeker', 'Tarçın']),
  _r('Un Helvası', _tatli, '🍮', 30, ['Un', 'Tereyağı', 'Süt', 'Ceviz', 'Toz Şeker']),
  _r('Brownie', _tatli, '🍫', 45, ['Kuvertür Çikolata', 'Tereyağı', 'Yumurta', 'Un', 'Kakao', 'Ceviz', 'Toz Şeker']),
  _r('Un Kurabiyesi', _tatli, '🍪', 40, ['Un', 'Tereyağı', 'Pudra Şekeri', 'Nişasta', 'Vanilin']),
  _r('Aşure', _tatli, '🥣', 180, ['Aşurelik Buğday', 'Nohut', 'Kuru Fasulye', 'Kuru Kayısı', 'Kuru İncir', 'Kuru Üzüm', 'Ceviz', 'Nar', 'Toz Şeker']),
  _r('Çilekli Magnolia', _tatli, '🍓', 30, ['Süt', 'Un', 'Nişasta', 'Yumurta', 'Krema', 'Bisküvi', 'Çilek', 'Toz Şeker', 'Vanilin']),
];

final recipesById = {for (final r in recipes) r.id: r};
