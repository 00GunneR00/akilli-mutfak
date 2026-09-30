// Tariflerin bir porsiyonluk malzeme gramajları (çiğ, yenilebilir kısım).
//
// Standart Türk ev tariflerinin (çoğunlukla 4 kişilik) miktarları porsiyona
// bölünmüştür; sıvılar için 1 ml ≈ 1 g. Kalori ve makrolar bu gramajlar ile
// USDA değerlerinden (ingredient_nutrition.g.dart) hesaplanır — tahmin
// edilmez. Yeni tarifte her malzemenin gramı yazılmalıdır (test doğrular).
//
// Kurallar: .claude/skills/diyetisyen/SKILL.md "Kalori kaynağı".

const recipePortions = <String, Map<String, num>>{
  // ---------------------------------------------------------------- Çorbalar
  // 1 kase ≈ 250–300 ml.
  'Mercimek Çorbası': {'Kırmızı Mercimek': 40, 'Soğan': 25, 'Havuç': 20, 'Patates': 30, 'Tereyağı': 6, 'Un': 3, 'Limon': 5, 'Pul Biber': 0.5, 'Tuz': 1},
  'Ezogelin Çorbası': {'Kırmızı Mercimek': 35, 'Bulgur': 8, 'Pirinç': 5, 'Soğan': 25, 'Domates Salçası': 8, 'Biber Salçası': 5, 'Tereyağı': 6, 'Kuru Nane': 0.5, 'Pul Biber': 0.5, 'Tuz': 1},
  'Yayla Çorbası': {'Yoğurt': 120, 'Pirinç': 12, 'Yumurta': 12, 'Un': 4, 'Tereyağı': 5, 'Kuru Nane': 0.5, 'Tuz': 1},
  'Domates Çorbası': {'Domates': 150, 'Domates Salçası': 8, 'Un': 6, 'Tereyağı': 6, 'Süt': 50, 'Kaşar Peyniri': 10, 'Tuz': 1},
  'Tavuk Suyu Çorbası': {'Tavuk But': 50, 'Tel Şehriye': 12, 'Havuç': 15, 'Limon': 5, 'Yumurta': 10, 'Un': 3, 'Tuz': 1, 'Karabiber': 0.3},
  'Mantar Çorbası': {'Mantar': 100, 'Soğan': 20, 'Tereyağı': 6, 'Un': 6, 'Süt': 100, 'Krema': 15, 'Tuz': 1, 'Karabiber': 0.3},
  'Tarhana Çorbası': {'Tarhana': 20, 'Domates Salçası': 6, 'Tereyağı': 5, 'Sarımsak': 2, 'Kuru Nane': 0.5, 'Tuz': 1},
  'Yeşil Mercimek Çorbası': {'Yeşil Mercimek': 35, 'Soğan': 25, 'Havuç': 15, 'Bulgur': 8, 'Domates Salçası': 6, 'Zeytinyağı': 6, 'Kuru Nane': 0.5, 'Tuz': 1},
  'Şehriye Çorbası': {'Şehriye': 15, 'Domates': 40, 'Domates Salçası': 6, 'Tereyağı': 5, 'Limon': 5, 'Maydanoz': 2, 'Tuz': 1},
  'Brokoli Çorbası': {'Brokoli': 100, 'Patates': 40, 'Soğan': 20, 'Süt': 100, 'Tereyağı': 6, 'Un': 5, 'Tuz': 1},
  'Balkabağı Çorbası': {'Balkabağı': 150, 'Soğan': 20, 'Havuç': 20, 'Krema': 20, 'Tereyağı': 6, 'Taze Zencefil': 2, 'Tuz': 1},
  'Düğün Çorbası': {'Kuşbaşı Et': 40, 'Yoğurt': 60, 'Yumurta': 12, 'Un': 6, 'Limon': 5, 'Tereyağı': 6, 'Pul Biber': 0.5, 'Tuz': 1},
  'Sebze Çorbası': {'Patates': 50, 'Havuç': 30, 'Kabak': 40, 'Bezelye': 20, 'Soğan': 20, 'Domates Salçası': 5, 'Zeytinyağı': 5, 'Tuz': 1},

  // ------------------------------------------------------------ Et Yemekleri
  // Et/kıyma ≈ 100–130 g (TÜBER porsiyonu).
  'Karnıyarık': {'Patlıcan': 200, 'Kıyma': 60, 'Soğan': 30, 'Domates': 60, 'Sivri Biber': 20, 'Sarımsak': 3, 'Domates Salçası': 8, 'Maydanoz': 3, 'Ayçiçek Yağı': 20, 'Tuz': 1, 'Karabiber': 0.3},
  'İzmir Köfte': {'Kıyma': 100, 'Patates': 120, 'Domates': 60, 'Sivri Biber': 20, 'Soğan': 20, 'Galeta Unu': 10, 'Yumurta': 10, 'Domates Salçası': 8, 'Ayçiçek Yağı': 12, 'Kimyon': 0.5, 'Tuz': 1},
  'Izgara Köfte': {'Kıyma': 120, 'Soğan': 20, 'Galeta Unu': 10, 'Yumurta': 8, 'Maydanoz': 3, 'Kimyon': 0.5, 'Tuz': 1, 'Karabiber': 0.3},
  'Tas Kebabı': {'Kuşbaşı Et': 130, 'Soğan': 40, 'Domates': 60, 'Sivri Biber': 20, 'Domates Salçası': 8, 'Tereyağı': 8, 'Tuz': 1, 'Karabiber': 0.3},
  'Etli Patates Yemeği': {'Kuşbaşı Et': 80, 'Patates': 150, 'Soğan': 30, 'Domates Salçası': 8, 'Ayçiçek Yağı': 8, 'Tuz': 1},
  'Hünkar Beğendi': {'Kuşbaşı Et': 120, 'Patlıcan': 150, 'Süt': 100, 'Un': 10, 'Tereyağı': 15, 'Kaşar Peyniri': 15, 'Soğan': 30, 'Domates': 50, 'Domates Salçası': 5, 'Tuz': 1},
  'Patlıcan Musakka': {'Patlıcan': 200, 'Kıyma': 70, 'Soğan': 30, 'Domates': 60, 'Sivri Biber': 20, 'Domates Salçası': 8, 'Ayçiçek Yağı': 20, 'Tuz': 1},
  'Sulu Köfte': {'Kıyma': 80, 'Pirinç': 10, 'Soğan': 20, 'Patates': 60, 'Havuç': 30, 'Domates Salçası': 6, 'Un': 4, 'Limon': 5, 'Tereyağı': 5, 'Tuz': 1},
  'Et Sote': {'Kuşbaşı Et': 130, 'Soğan': 40, 'Sivri Biber': 30, 'Domates': 60, 'Tereyağı': 8, 'Kekik': 0.3, 'Tuz': 1},
  'Orman Kebabı': {'Kuşbaşı Et': 100, 'Patates': 80, 'Bezelye': 30, 'Havuç': 30, 'Soğan': 30, 'Domates Salçası': 8, 'Tereyağı': 8, 'Tuz': 1},
  'İskender Kebap': {'Dana Döner': 120, 'Pide': 70, 'Yoğurt': 100, 'Tereyağı': 15, 'Domates Salçası': 10, 'Domates': 50, 'Tuz': 1},
  'Hamburger': {'Hamburger Köftesi': 120, 'Hamburger Ekmeği': 70, 'Marul': 15, 'Domates': 30, 'Kornişon Turşu': 15, 'Cheddar': 20, 'Ketçap': 15, 'Mayonez': 12, 'Kırmızı Soğan': 15},
  'Fırında Kuzu İncik': {'Kuzu İncik': 220, 'Soğan': 50, 'Havuç': 50, 'Sarımsak': 5, 'Domates Salçası': 8, 'Biberiye': 0.5, 'Tuz': 1},
  'Ciğer Tava': {'Ciğer': 130, 'Un': 10, 'Kırmızı Soğan': 40, 'Maydanoz': 5, 'Sumak': 1, 'Ayçiçek Yağı': 12, 'Tuz': 1},
  'Kadınbudu Köfte': {'Kıyma': 100, 'Pirinç': 15, 'Soğan': 20, 'Yumurta': 20, 'Un': 8, 'Ayçiçek Yağı': 12, 'Kimyon': 0.5, 'Tuz': 1},
  'Etli Bamya': {'Bamya': 150, 'Kuşbaşı Et': 70, 'Soğan': 30, 'Domates': 50, 'Domates Salçası': 6, 'Limon': 5, 'Tereyağı': 6, 'Tuz': 1},

  // --------------------------------------------------------- Tavuk Yemekleri
  'Tavuk Sote': {'Tavuk Göğsü': 150, 'Soğan': 40, 'Kapya Biber': 30, 'Sivri Biber': 20, 'Domates': 50, 'Mantar': 40, 'Tereyağı': 8, 'Tuz': 1, 'Karabiber': 0.3},
  'Fırında Patatesli Tavuk': {'Tavuk But': 180, 'Patates': 150, 'Soğan': 30, 'Domates Salçası': 8, 'Sarımsak': 3, 'Zeytinyağı': 10, 'Kekik': 0.5, 'Tuz': 1},
  'Kremalı Mantarlı Tavuk': {'Tavuk Göğsü': 150, 'Mantar': 60, 'Krema': 40, 'Soğan': 25, 'Tereyağı': 8, 'Kaşar Peyniri': 15, 'Tuz': 1},
  'Tavuk Şiş': {'Tavuk Göğsü': 160, 'Yoğurt': 20, 'Domates Salçası': 5, 'Sarımsak': 3, 'Kapya Biber': 30, 'Soğan': 30, 'Zeytinyağı': 6, 'Kekik': 0.5, 'Tuz': 1},
  'Soslu Tavuk Kanat': {'Tavuk Kanat': 200, 'Domates Salçası': 10, 'Bal': 8, 'Soya Sosu': 8, 'Sarımsak': 3, 'Tatlı Toz Biber': 1, 'Tuz': 1},
  'Tavuk Dürüm': {'Tavuk Göğsü': 120, 'Lavaş': 70, 'Marul': 20, 'Domates': 40, 'Kırmızı Soğan': 15, 'Kapya Biber': 20, 'Mayonez': 12, 'Tuz': 1},
  'Köri Soslu Tavuk': {'Tavuk Göğsü': 150, 'Krema': 40, 'Köri': 2, 'Soğan': 30, 'Kapya Biber': 30, 'Tuz': 1},
  'Fırında Bütün Tavuk': {'Bütün Tavuk': 200, 'Tereyağı': 8, 'Sarımsak': 3, 'Limon': 5, 'Biberiye': 0.5, 'Patates': 120, 'Tuz': 1},
  'Çıtır Tavuk': {'Tavuk Bonfile': 150, 'Un': 15, 'Yumurta': 20, 'Galeta Unu': 25, 'Ayçiçek Yağı': 15, 'Tatlı Toz Biber': 1, 'Tuz': 1},
  'Tavuk Haşlama': {'Tavuk But': 130, 'Patates': 100, 'Havuç': 50, 'Soğan': 30, 'Limon': 5, 'Tuz': 1, 'Karabiber': 0.3},

  // ------------------------------------------------------------ Balık & Deniz
  // Balık: yenilebilir kısım ≈ 150–200 g.
  'Fırında Somon': {'Somon': 170, 'Limon': 10, 'Tereyağı': 8, 'Sarımsak': 2, 'Dereotu': 3, 'Tuz': 1},
  'Hamsi Tava': {'Hamsi': 200, 'Mısır Unu': 25, 'Ayçiçek Yağı': 15, 'Limon': 10, 'Kırmızı Soğan': 30, 'Tuz': 1},
  'Fırında Levrek': {'Levrek': 200, 'Domates': 60, 'Soğan': 40, 'Limon': 10, 'Zeytinyağı': 10, 'Defne Yaprağı': 0.2, 'Tuz': 1},
  'Çipura Buğulama': {'Çipura': 200, 'Domates': 60, 'Soğan': 30, 'Sivri Biber': 20, 'Limon': 10, 'Tereyağı': 8, 'Tuz': 1},
  'Palamut Buğulama': {'Palamut': 200, 'Domates': 60, 'Soğan': 30, 'Sivri Biber': 20, 'Limon': 10, 'Zeytinyağı': 10, 'Tuz': 1},
  'Karides Güveç': {'Karides': 150, 'Mantar': 50, 'Domates': 50, 'Sivri Biber': 20, 'Sarımsak': 3, 'Kaşar Peyniri': 25, 'Tereyağı': 10, 'Tuz': 1},
  'Kalamar Tava': {'Kalamar': 150, 'Un': 25, 'Maden Suyu': 30, 'Ayçiçek Yağı': 20, 'Limon': 10, 'Tuz': 1},
  'Tereyağlı Karides': {'Karides': 150, 'Tereyağı': 15, 'Sarımsak': 5, 'Pul Biber': 0.5, 'Maydanoz': 3, 'Tuz': 1},

  // --------------------------------------------------------- Sebze Yemekleri
  // Zeytinyağlılar: 4 kişilik tencereye ≈ ½–1 çay bardağı yağ.
  'Zeytinyağlı Taze Fasulye': {'Taze Fasulye': 200, 'Domates': 80, 'Soğan': 30, 'Zeytinyağı': 15, 'Toz Şeker': 2, 'Tuz': 1},
  'Kıymalı Ispanak': {'Ispanak': 250, 'Kıyma': 50, 'Soğan': 30, 'Pirinç': 10, 'Domates Salçası': 6, 'Yoğurt': 50, 'Zeytinyağı': 8, 'Tuz': 1},
  'İmam Bayıldı': {'Patlıcan': 250, 'Soğan': 60, 'Domates': 80, 'Sarımsak': 5, 'Sivri Biber': 20, 'Maydanoz': 5, 'Zeytinyağı': 20, 'Toz Şeker': 2, 'Tuz': 1},
  'Türlü': {'Patlıcan': 80, 'Kabak': 80, 'Patates': 60, 'Taze Fasulye': 50, 'Domates': 60, 'Sivri Biber': 20, 'Soğan': 30, 'Domates Salçası': 6, 'Zeytinyağı': 12, 'Tuz': 1},
  'Mücver': {'Kabak': 150, 'Yumurta': 30, 'Un': 20, 'Beyaz Peynir': 20, 'Taze Soğan': 10, 'Dereotu': 3, 'Ayçiçek Yağı': 15, 'Tuz': 1},
  'Zeytinyağlı Pırasa': {'Pırasa': 200, 'Havuç': 30, 'Pirinç': 10, 'Limon': 5, 'Zeytinyağı': 15, 'Toz Şeker': 2, 'Tuz': 1},
  'Zeytinyağlı Enginar': {'Enginar': 150, 'Havuç': 30, 'Bezelye': 30, 'Patates': 40, 'Limon': 10, 'Dereotu': 3, 'Zeytinyağı': 15, 'Tuz': 1},
  'Bezelye Yemeği': {'Bezelye': 150, 'Havuç': 30, 'Patates': 50, 'Soğan': 30, 'Domates Salçası': 6, 'Zeytinyağı': 10, 'Tuz': 1},
  'Karnabahar Graten': {'Karnabahar': 200, 'Süt': 100, 'Un': 10, 'Tereyağı': 10, 'Kaşar Peyniri': 25, 'Tuz': 1},
  'Fırında Baharatlı Patates': {'Patates': 250, 'Sarımsak': 3, 'Zeytinyağı': 15, 'Kekik': 0.5, 'Tatlı Toz Biber': 1, 'Tuz': 1},
  'Kıymalı Kabak': {'Kabak': 200, 'Kıyma': 50, 'Soğan': 30, 'Domates': 50, 'Pirinç': 10, 'Dereotu': 3, 'Zeytinyağı': 8, 'Tuz': 1},
  'Mantar Sote': {'Mantar': 200, 'Tereyağı': 10, 'Sarımsak': 3, 'Kapya Biber': 40, 'Kekik': 0.5, 'Tuz': 1},
  'Etli Lahana Sarması': {'Lahana': 150, 'Kıyma': 60, 'Pirinç': 30, 'Soğan': 20, 'Domates Salçası': 8, 'Kuru Nane': 0.5, 'Zeytinyağı': 8, 'Tuz': 1},
  'Biber Dolması': {'Dolmalık Biber': 150, 'Kıyma': 60, 'Pirinç': 30, 'Soğan': 20, 'Domates': 40, 'Domates Salçası': 6, 'Maydanoz': 3, 'Zeytinyağı': 8, 'Tuz': 1},
  'Zeytinyağlı Yaprak Sarma': {'Asma Yaprağı': 40, 'Pirinç': 35, 'Soğan': 30, 'Kuru Üzüm': 5, 'Limon': 10, 'Maydanoz': 3, 'Dereotu': 3, 'Zeytinyağı': 15, 'Kuru Nane': 0.5, 'Tarçın': 0.3, 'Tuz': 1},
  'Patates Oturtma': {'Patates': 180, 'Kıyma': 60, 'Soğan': 30, 'Domates': 50, 'Sivri Biber': 20, 'Domates Salçası': 6, 'Ayçiçek Yağı': 15, 'Tuz': 1},

  // ---------------------------------------------------------------- Bakliyat
  // Kuru baklagil kuru ağırlıkla ≈ 60–70 g.
  'Kuru Fasulye': {'Kuru Fasulye': 70, 'Soğan': 40, 'Domates Salçası': 10, 'Biber Salçası': 5, 'Tereyağı': 10, 'Pul Biber': 0.5, 'Tuz': 1},
  'Etli Nohut': {'Nohut': 60, 'Kuşbaşı Et': 60, 'Soğan': 40, 'Domates Salçası': 10, 'Tereyağı': 8, 'Tuz': 1},
  'Zeytinyağlı Barbunya': {'Barbunya': 60, 'Havuç': 40, 'Patates': 50, 'Soğan': 30, 'Domates': 50, 'Zeytinyağı': 15, 'Tuz': 1},
  'Yeşil Mercimek Yemeği': {'Yeşil Mercimek': 60, 'Soğan': 40, 'Bulgur': 15, 'Domates Salçası': 10, 'Kuru Nane': 0.5, 'Zeytinyağı': 8, 'Tuz': 1},
  'Pastırmalı Kuru Fasulye': {'Kuru Fasulye': 70, 'Pastırma': 30, 'Soğan': 40, 'Domates Salçası': 10, 'Tereyağı': 10, 'Tuz': 1},
  'Sucuklu Nohut': {'Nohut Konservesi': 180, 'Sucuk': 50, 'Soğan': 30, 'Domates Salçası': 10, 'Tuz': 1},

  // --------------------------------------------------------- Pilav & Makarna
  // Pilav: ≈ 60 g çiğ pirinç/bulgur; makarna ≈ 100 g kuru.
  'Pirinç Pilavı': {'Pirinç': 60, 'Tel Şehriye': 8, 'Tereyağı': 8, 'Tuz': 1},
  'Bulgur Pilavı': {'Bulgur': 60, 'Soğan': 20, 'Domates': 40, 'Sivri Biber': 15, 'Domates Salçası': 6, 'Tereyağı': 8, 'Tuz': 1},
  'Tavuklu Pilav': {'Pirinç': 80, 'Tavuk Göğsü': 80, 'Nohut': 15, 'Tereyağı': 10, 'Tuz': 1, 'Karabiber': 0.3},
  'İç Pilav': {'Pirinç': 60, 'Soğan': 20, 'Kuru Üzüm': 5, 'Antep Fıstığı': 5, 'Tereyağı': 10, 'Tarçın': 0.3, 'Yenibahar': 0.3, 'Tuz': 1},
  'Nohutlu Pilav': {'Pirinç': 60, 'Nohut': 15, 'Tereyağı': 8, 'Tuz': 1},
  'Şehriye Pilavı': {'Şehriye': 60, 'Tereyağı': 8, 'Domates Salçası': 5, 'Tuz': 1},
  'Kıymalı Makarna': {'Makarna': 100, 'Kıyma': 50, 'Soğan': 20, 'Domates': 50, 'Domates Salçası': 8, 'Zeytinyağı': 6, 'Tuz': 1},
  'Fırın Makarna': {'Makarna': 90, 'Süt': 120, 'Un': 10, 'Tereyağı': 12, 'Yumurta': 20, 'Kaşar Peyniri': 25, 'Tuz': 1},
  'Spagetti Bolonez': {'Spagetti': 100, 'Kıyma': 60, 'Soğan': 20, 'Havuç': 15, 'Domates': 60, 'Sarımsak': 3, 'Domates Salçası': 8, 'Zeytinyağı': 8, 'Parmesan': 8, 'Tuz': 1},
  'Kremalı Mantarlı Makarna': {'Penne': 100, 'Mantar': 80, 'Krema': 50, 'Sarımsak': 3, 'Tereyağı': 8, 'Parmesan': 10, 'Tuz': 1},
  'Lazanya': {'Lazanya': 70, 'Kıyma': 60, 'Soğan': 20, 'Domates': 50, 'Domates Salçası': 8, 'Süt': 100, 'Un': 8, 'Tereyağı': 10, 'Kaşar Peyniri': 25, 'Tuz': 1},
  'Yoğurtlu Mantı': {'Mantı': 150, 'Yoğurt': 100, 'Sarımsak': 3, 'Tereyağı': 12, 'Domates Salçası': 5, 'Pul Biber': 0.5, 'Kuru Nane': 0.3},
  'Cevizli Erişte': {'Erişte': 100, 'Tereyağı': 12, 'Ceviz': 15, 'Lor Peyniri': 30, 'Tuz': 1},
  'Pesto Soslu Makarna': {'Penne': 100, 'Pesto': 30, 'Parmesan': 10, 'Cherry Domates': 60, 'Tuz': 1},
  'Domates Soslu Spagetti': {'Spagetti': 100, 'Domates': 120, 'Sarımsak': 3, 'Fesleğen': 2, 'Zeytinyağı': 10, 'Tuz': 1},

  // --------------------------------------------------------------- Hamur İşi
  'Su Böreği': {'Yufka': 60, 'Yumurta': 20, 'Süt': 30, 'Beyaz Peynir': 40, 'Maydanoz': 3, 'Tereyağı': 15, 'Tuz': 0.5},
  'Sigara Böreği': {'Yufka': 40, 'Beyaz Peynir': 30, 'Maydanoz': 3, 'Ayçiçek Yağı': 12}, // 3 adet
  'Ispanaklı Börek': {'Yufka': 50, 'Ispanak': 80, 'Soğan': 20, 'Beyaz Peynir': 25, 'Yumurta': 15, 'Süt': 25, 'Ayçiçek Yağı': 10, 'Tuz': 0.5},
  'Kıymalı Börek': {'Yufka': 60, 'Kıyma': 50, 'Soğan': 25, 'Yumurta': 15, 'Süt': 25, 'Ayçiçek Yağı': 12, 'Tuz': 0.5},
  'Peynirli Poğaça': {'Un': 50, 'Yoğurt': 15, 'Yumurta': 10, 'Beyaz Peynir': 20, 'Maydanoz': 2, 'Ayçiçek Yağı': 12, 'Kabartma Tozu': 1, 'Tuz': 0.5}, // 2 adet
  'Pişi': {'Un': 50, 'Maya': 1, 'Süt': 30, 'Ayçiçek Yağı': 15, 'Toz Şeker': 2, 'Tuz': 0.5}, // 2 adet
  'Peynirli Gözleme': {'Yufka': 70, 'Beyaz Peynir': 40, 'Maydanoz': 3, 'Tereyağı': 10},
  'Kaşarlı Pide': {'Un': 100, 'Maya': 2, 'Süt': 30, 'Kaşar Peyniri': 60, 'Yumurta': 10, 'Tereyağı': 10, 'Tuz': 1}, // 1 pide
  'Lahmacun': {'Un': 80, 'Maya': 2, 'Kıyma': 60, 'Soğan': 20, 'Domates': 30, 'Sivri Biber': 10, 'Maydanoz': 5, 'Domates Salçası': 8, 'Limon': 5, 'Tuz': 1}, // 2 adet
  'Ev Yapımı Pizza': {'Un': 90, 'Maya': 2, 'Domates Salçası': 15, 'Mozzarella': 60, 'Sucuk': 20, 'Mantar': 20, 'Kapya Biber': 15, 'Zeytin': 10, 'Zeytinyağı': 8, 'Kekik': 0.5}, // ½ orta boy
  'Krep': {'Un': 30, 'Süt': 80, 'Yumurta': 25, 'Tereyağı': 5, 'Tuz': 0.5}, // 2 adet

  // ------------------------------------------------------------- Kahvaltılık
  'Menemen': {'Yumurta': 100, 'Domates': 150, 'Sivri Biber': 40, 'Tereyağı': 10, 'Pul Biber': 0.5, 'Tuz': 1}, // 2 yumurta
  'Sucuklu Yumurta': {'Sucuk': 50, 'Yumurta': 100, 'Tereyağı': 5},
  'Peynirli Omlet': {'Yumurta': 100, 'Süt': 20, 'Kaşar Peyniri': 30, 'Tereyağı': 8, 'Tuz': 1},
  'Çılbır': {'Yumurta': 100, 'Yoğurt': 100, 'Sarımsak': 3, 'Tereyağı': 10, 'Pul Biber': 0.5, 'Sirke': 5},
  'Pankek': {'Un': 50, 'Süt': 70, 'Yumurta': 25, 'Tereyağı': 8, 'Bal': 15, 'Toz Şeker': 5, 'Kabartma Tozu': 2}, // 3 adet
  'Kaşarlı Tost': {'Tost Ekmeği': 60, 'Kaşar Peyniri': 40, 'Tereyağı': 8},
  'Yulaf Lapası': {'Yulaf': 50, 'Süt': 200, 'Muz': 60, 'Bal': 10, 'Tarçın': 0.5},
  'Yumurtalı Ekmek': {'Ekmek': 60, 'Yumurta': 50, 'Süt': 20, 'Ayçiçek Yağı': 10, 'Tuz': 0.5},
  'Avokadolu Tost': {'Ekşi Mayalı Ekmek': 60, 'Avokado': 70, 'Yumurta': 50, 'Limon': 5, 'Pul Biber': 0.3, 'Tuz': 0.5},
  'Kahvaltı Tabağı': {'Beyaz Peynir': 30, 'Zeytin': 20, 'Domates': 80, 'Salatalık': 60, 'Ekmek': 50}, // 1 dilim peynir, 5–6 zeytin, 2 ince dilim ekmek
  'Haşlanmış Yumurta': {'Yumurta': 100, 'Tuz': 0.5}, // 2 yumurta
  'Susamlı Simit': {'Simit': 100},

  // ----------------------------------------------------------- Salata & Meze
  'Çoban Salatası': {'Domates': 100, 'Salatalık': 80, 'Sivri Biber': 20, 'Kırmızı Soğan': 20, 'Maydanoz': 5, 'Limon': 5, 'Zeytinyağı': 8, 'Tuz': 0.5},
  'Gavurdağı Salatası': {'Domates': 100, 'Ceviz': 15, 'Kırmızı Soğan': 20, 'Sivri Biber': 20, 'Maydanoz': 5, 'Nar Ekşisi': 8, 'Zeytinyağı': 8, 'Sumak': 0.5, 'Tuz': 0.5},
  'Kısır': {'Köftelik Bulgur': 40, 'Domates Salçası': 8, 'Biber Salçası': 5, 'Taze Soğan': 10, 'Maydanoz': 10, 'Taze Nane': 2, 'Nar Ekşisi': 8, 'Limon': 5, 'Marul': 20, 'Zeytinyağı': 10, 'Tuz': 0.5},
  'Patates Salatası': {'Patates': 150, 'Taze Soğan': 15, 'Maydanoz': 5, 'Dereotu': 3, 'Limon': 5, 'Zeytinyağı': 10, 'Pul Biber': 0.3, 'Tuz': 0.5},
  'Etsiz Çiğ Köfte': {'Köftelik Bulgur': 50, 'İsot': 3, 'Biber Salçası': 10, 'Domates Salçası': 10, 'Soğan': 15, 'Sarımsak': 2, 'Nar Ekşisi': 8, 'Maydanoz': 5, 'Marul': 30, 'Limon': 5},
  'Mercimek Köftesi': {'Kırmızı Mercimek': 30, 'Köftelik Bulgur': 30, 'Soğan': 20, 'Taze Soğan': 10, 'Maydanoz': 5, 'Domates Salçası': 6, 'Biber Salçası': 5, 'Limon': 5, 'Marul': 20, 'Kimyon': 0.5, 'Tuz': 0.5},
  'Ev Yapımı Humus': {'Nohut': 30, 'Tahin': 12, 'Limon': 10, 'Sarımsak': 2, 'Zeytinyağı': 5, 'Kimyon': 0.3, 'Tuz': 0.5},
  'Ev Yapımı Haydari': {'Süzme Yoğurt': 80, 'Beyaz Peynir': 20, 'Sarımsak': 2, 'Dereotu': 2, 'Taze Nane': 1, 'Zeytinyağı': 5},
  'Şakşuka': {'Patlıcan': 100, 'Kabak': 60, 'Patates': 50, 'Kapya Biber': 30, 'Domates': 60, 'Sarımsak': 3, 'Yoğurt': 50, 'Ayçiçek Yağı': 15, 'Tuz': 0.5},
  'Ev Yapımı Rus Salatası': {'Patates': 60, 'Havuç': 30, 'Bezelye': 20, 'Kornişon Turşu': 15, 'Mayonez': 20, 'Yoğurt': 30, 'Tuz': 0.5},
  'Ton Balıklı Salata': {'Ton Balığı': 60, 'Marul': 60, 'Mısır Konservesi': 30, 'Domates': 60, 'Salatalık': 50, 'Limon': 5, 'Zeytinyağı': 8},
  'Çerkez Tavuğu': {'Tavuk Göğsü': 80, 'Ceviz': 25, 'Ekmek': 20, 'Sarımsak': 2, 'Tatlı Toz Biber': 1, 'Tuz': 0.5},
  'Piyaz': {'Kuru Fasulye': 40, 'Kırmızı Soğan': 30, 'Maydanoz': 5, 'Domates': 40, 'Yumurta': 20, 'Sirke': 5, 'Zeytinyağı': 10, 'Sumak': 0.5, 'Tuz': 0.5},
  'Cacık': {'Yoğurt': 150, 'Salatalık': 60, 'Sarımsak': 2, 'Kuru Nane': 0.3, 'Zeytinyağı': 3, 'Tuz': 0.5},
  'Roka Salatası': {'Roka': 40, 'Domates': 50, 'Parmesan': 10, 'Limon': 5, 'Nar Ekşisi': 5, 'Zeytinyağı': 8},
  'Sezar Salata': {'Marul': 100, 'Tavuk Göğsü': 80, 'Parmesan': 12, 'Ekmek': 20, 'Mayonez': 15, 'Limon': 5, 'Sarımsak': 2},
  'Babagannuş': {'Patlıcan': 150, 'Tahin': 12, 'Sarımsak': 2, 'Limon': 8, 'Maydanoz': 3, 'Zeytinyağı': 8},
  'Ev Yapımı Acılı Ezme': {'Domates': 80, 'Sivri Biber': 20, 'Kırmızı Soğan': 15, 'Maydanoz': 5, 'Biber Salçası': 5, 'Nar Ekşisi': 5, 'Zeytinyağı': 6, 'Pul Biber': 0.5, 'İsot': 0.5},
  'Semizotu Salatası': {'Semizotu': 80, 'Yoğurt': 100, 'Sarımsak': 2, 'Zeytinyağı': 5, 'Tuz': 0.5},

  // ---------------------------------------------------------------- Tatlılar
  'Fırın Sütlaç': {'Süt': 200, 'Pirinç': 12, 'Nişasta': 5, 'Toz Şeker': 25, 'Vanilin': 0.3, 'Tarçın': 0.3},
  'İrmik Helvası': {'İrmik': 35, 'Tereyağı': 12, 'Süt': 70, 'Fındık': 5, 'Toz Şeker': 25},
  'Revani': {'İrmik': 30, 'Un': 15, 'Yumurta': 20, 'Yoğurt': 20, 'Limon': 3, 'Hindistan Cevizi': 3, 'Toz Şeker': 40, 'Kabartma Tozu': 1}, // şerbet dahil
  'Kakaolu Kek': {'Un': 25, 'Yumurta': 15, 'Süt': 15, 'Kakao': 3, 'Ayçiçek Yağı': 10, 'Toz Şeker': 22, 'Kabartma Tozu': 1, 'Vanilin': 0.2}, // 1 dilim
  'Supangle': {'Süt': 150, 'Kakao': 6, 'Un': 8, 'Nişasta': 5, 'Tereyağı': 5, 'Bisküvi': 10, 'Damla Çikolata': 8, 'Toz Şeker': 25},
  'Muhallebi': {'Süt': 180, 'Nişasta': 8, 'Pirinç Unu': 8, 'Toz Şeker': 22, 'Vanilin': 0.3, 'Tarçın': 0.3},
  'Keşkül': {'Süt': 180, 'Badem': 12, 'Pirinç Unu': 10, 'Hindistan Cevizi': 4, 'Toz Şeker': 22},
  'Fırında Elma Tatlısı': {'Elma': 180, 'Ceviz': 10, 'Tereyağı': 5, 'Toz Şeker': 15, 'Tarçın': 0.5},
  'Un Helvası': {'Un': 25, 'Tereyağı': 15, 'Süt': 50, 'Ceviz': 5, 'Toz Şeker': 25},
  'Brownie': {'Kuvertür Çikolata': 20, 'Tereyağı': 12, 'Yumurta': 12, 'Un': 10, 'Kakao': 3, 'Ceviz': 8, 'Toz Şeker': 18}, // 1 dilim
  'Un Kurabiyesi': {'Un': 30, 'Tereyağı': 18, 'Pudra Şekeri': 10, 'Nişasta': 5, 'Vanilin': 0.2}, // 3 adet
  'Aşure': {'Aşurelik Buğday': 20, 'Nohut': 8, 'Kuru Fasulye': 8, 'Kuru Kayısı': 10, 'Kuru İncir': 10, 'Kuru Üzüm': 8, 'Ceviz': 8, 'Nar': 15, 'Toz Şeker': 25},
  'Çilekli Magnolia': {'Süt': 150, 'Un': 10, 'Nişasta': 5, 'Yumurta': 12, 'Krema': 30, 'Bisküvi': 15, 'Çilek': 50, 'Toz Şeker': 22, 'Vanilin': 0.2},

  // ---------------------------------------------------------------- Ara Öğün
  'Muzlu Süt Shake': {'Süt': 250, 'Muz': 100, 'Tarçın': 0.5},
  'Yulaflı Muz Shake': {'Süt': 250, 'Muz': 100, 'Yulaf': 30, 'Fıstık Ezmesi': 15, 'Bal': 10},
  'Fıstık Ezmeli Protein Shake': {'Süt': 250, 'Protein Tozu': 30, 'Muz': 100, 'Fıstık Ezmesi': 15},
  'Kakaolu Muz Protein Shake': {'Süt': 250, 'Protein Tozu': 30, 'Kakao': 5, 'Muz': 100},
  'Hurmalı Kilo Aldıran Shake': {'Süt': 250, 'Hurma': 40, 'Yulaf': 30, 'Badem': 20, 'Muz': 100},
  'Çilekli Yoğurt Smoothie': {'Yoğurt': 150, 'Çilek': 120, 'Bal': 10},
  'Orman Meyveli Kefir Smoothie': {'Kefir': 250, 'Yaban Mersini': 60, 'Ahududu': 60},
  'Yeşil Smoothie': {'Ispanak': 30, 'Yeşil Elma': 120, 'Muz': 60, 'Salatalık': 60, 'Limon': 10},
  'Mangolu Yoğurt Smoothie': {'Mango': 120, 'Yoğurt': 120, 'Portakal': 60},
  'Yoğurtlu Meyve Kasesi': {'Yoğurt': 150, 'Çilek': 60, 'Muz': 50, 'Ceviz': 10},
  'Granolalı Yoğurt': {'Süzme Yoğurt': 150, 'Granola': 30, 'Bal': 8},
  'Chialı Puding': {'Süt': 150, 'Chia Tohumu': 20, 'Bal': 8, 'Çilek': 60},
  'Elma ve Badem': {'Elma': 150, 'Badem': 15},
  'Muz ve Fıstık Ezmesi': {'Muz': 100, 'Fıstık Ezmesi': 20},
  'Karpuz ve Beyaz Peynir': {'Karpuz': 250, 'Beyaz Peynir': 30},
  'Lorlu Armut': {'Armut': 150, 'Lor Peyniri': 60, 'Ceviz': 8, 'Tarçın': 0.3},
  'Mevsim Meyve Tabağı': {'Portakal': 100, 'Elma': 80, 'Kivi': 60},
  'Kuru Meyve ve Ceviz': {'Kuru Kayısı': 20, 'Kuru İncir': 20, 'Ceviz': 15},
  'Bir Avuç Kuruyemiş': {'Badem': 10, 'Fındık': 10, 'Ceviz': 10},
  'Leblebi ve Kuru Üzüm': {'Leblebi': 30, 'Kuru Üzüm': 15},
  'Humuslu Sebze Çubukları': {'Havuç': 60, 'Salatalık': 60, 'Kapya Biber': 50, 'Humus': 50},
  'Yoğurt Soslu Sebze Çubukları': {'Havuç': 60, 'Salatalık': 60, 'Kereviz': 50, 'Süzme Yoğurt': 80, 'Dereotu': 2},
  'Haşlanmış Yumurta ve Salatalık': {'Yumurta': 50, 'Salatalık': 100, 'Domates': 60},
  'Peynirli Tam Buğday Dilimi': {'Tam Buğday Ekmeği': 50, 'Beyaz Peynir': 30, 'Domates': 50, 'Salatalık': 50},
  'Simit ve Ayran': {'Simit': 100, 'Ayran': 200},
};
