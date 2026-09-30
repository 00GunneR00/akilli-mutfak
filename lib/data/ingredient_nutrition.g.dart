// ÜRETİLDİ — elle düzenlemeyin. Kaynak: tool/nutrition/build.dart
//
// 100 g başına enerji (kcal), protein, yağ ve karbonhidrat (g).
// Veri: USDA National Nutrient Database for Standard Reference,
// Legacy Release (2018) — kamu malı (CC0). Her satırda fdc_id ve
// USDA adı; eşleştirme notları tool/nutrition/ingredient_usda.tsv.

import 'nutrition.dart';

const ingredientNutrition = <String, Nutrients>{
  'Ahududu': Nutrients(52, 1.2, 0.65, 11.94), // 167755 Raspberries, raw
  'Antep Fıstığı': Nutrients(560, 20.16, 45.32, 27.17), // 170184 Nuts, pistachio nuts, raw
  'Armut': Nutrients(63, 0.39, 0.16, 15.01), // 167776 Pears, raw, bartlett (Includes foods for USDA's Food Distribution Program)
  'Asma Yaprağı': Nutrients(69, 4.27, 1.97, 11.71), // 169393 Grape leaves, canned
  'Avokado': Nutrients(160, 2, 14.66, 8.53), // 171705 Avocados, raw, all commercial varieties
  'Ayran': Nutrients(30.5, 1.74, 1.63, 2.33), // 171284 Yogurt, plain, whole milk ×0.5
  'Ayçiçek Yağı': Nutrients(884, 0, 100, 0), // 171025 Oil, sunflower, linoleic, (approx. 65%)
  'Aşurelik Buğday': Nutrients(342, 11.31, 1.71, 75.9), // 169719 Wheat, hard white
  'Badem': Nutrients(579, 21.15, 49.93, 21.55), // 170567 Nuts, almonds
  'Bal': Nutrients(304, 0.3, 0, 82.4), // 169640 Honey
  'Balkabağı': Nutrients(26, 1, 0.1, 6.5), // 168448 Pumpkin, raw
  'Bamya': Nutrients(33, 1.93, 0.19, 7.45), // 169260 Okra, raw
  'Barbunya': Nutrients(335, 23.03, 1.23, 60.05), // 175189 Beans, cranberry (roman), mature seeds, raw
  'Beyaz Peynir': Nutrients(265, 14.21, 21.49, 3.88), // 173420 Cheese, feta
  'Bezelye': Nutrients(81, 5.42, 0.4, 14.45), // 170419 Peas, green, raw
  'Biber Salçası': Nutrients(82, 4.32, 0.47, 18.91), // 170459 Tomato products, canned, paste, without salt added (Includes foods for USDA's Food Distribution Program)
  'Biberiye': Nutrients(331, 4.88, 15.22, 64.06), // 171333 Spices, rosemary, dried
  'Bisküvi': Nutrients(467, 6.1, 18.8, 68.9), // 174950 Cookies, butter, commercially prepared, enriched
  'Brokoli': Nutrients(34, 2.82, 0.37, 6.64), // 170379 Broccoli, raw
  'Bulgur': Nutrients(342, 12.29, 1.33, 75.87), // 170688 Bulgur, dry
  'Bütün Tavuk': Nutrients(215, 18.6, 15.06, 0), // 171447 Chicken, broilers or fryers, meat and skin, raw
  'Ceviz': Nutrients(654, 15.23, 65.21, 13.71), // 170187 Nuts, walnuts, english
  'Cheddar': Nutrients(410, 24.25, 33.82, 2.13), // 170899 Cheese, cheddar, sharp, sliced
  'Cherry Domates': Nutrients(18, 0.88, 0.2, 3.89), // 170457 Tomatoes, red, ripe, raw, year round average
  'Chia Tohumu': Nutrients(486, 16.54, 30.74, 42.12), // 170554 Seeds, chia seeds, dried
  'Ciğer': Nutrients(135, 20.36, 3.63, 3.89), // 169451 Beef, variety meats and by-products, liver, raw
  'Damla Çikolata': Nutrients(480, 4.2, 30, 63.9), // 167976 Candies, semisweet chocolate
  'Dana Döner': Nutrients(250, 25.93, 15.41, 0), // 174032 Beef, ground, 85% lean meat / 15% fat, patty, cooked, broiled
  'Defne Yaprağı': Nutrients(313, 7.61, 8.36, 74.97), // 170917 Spices, bay leaf
  'Dereotu': Nutrients(43, 3.46, 1.12, 7.02), // 172233 Dill weed, fresh
  'Dolmalık Biber': Nutrients(20, 0.86, 0.17, 4.64), // 170427 Peppers, sweet, green, raw
  'Domates': Nutrients(18, 0.88, 0.2, 3.89), // 170457 Tomatoes, red, ripe, raw, year round average
  'Domates Salçası': Nutrients(82, 4.32, 0.47, 18.91), // 170459 Tomato products, canned, paste, without salt added (Includes foods for USDA's Food Distribution Program)
  'Ekmek': Nutrients(266, 8.85, 3.33, 49.42), // 174924 Bread, white, commercially prepared (includes soft bread crumbs)
  'Ekşi Mayalı Ekmek': Nutrients(272, 10.75, 2.42, 51.88), // 172675 Bread, french or vienna (includes sourdough)
  'Elma': Nutrients(52, 0.26, 0.17, 13.81), // 171688 Apples, raw, with skin (Includes foods for USDA's Food Distribution Program)
  'Enginar': Nutrients(47, 3.27, 0.15, 10.51), // 169205 Artichokes, (globe or french), raw
  'Erişte': Nutrients(384, 14.16, 4.44, 71.27), // 169731 Noodles, egg, dry, enriched
  'Fesleğen': Nutrients(23, 3.15, 0.64, 2.65), // 172232 Basil, fresh
  'Fındık': Nutrients(628, 14.95, 60.75, 16.7), // 170581 Nuts, hazelnuts or filberts
  'Fıstık Ezmesi': Nutrients(598, 22.21, 51.36, 22.31), // 172470 Peanut butter, smooth style, without salt
  'Galeta Unu': Nutrients(395, 13.35, 5.3, 71.98), // 174928 Bread, crumbs, dry, grated, plain
  'Granola': Nutrients(489, 13.67, 24.31, 53.88), // 171646 Cereals ready-to-eat, granola, homemade
  'Hamburger Ekmeği': Nutrients(279, 9.77, 3.91, 50.12), // 172796 Rolls, hamburger or hotdog, plain
  'Hamburger Köftesi': Nutrients(254, 17.17, 20, 0), // 174036 Beef, ground, 80% lean meat / 20% fat, raw
  'Hamsi': Nutrients(131, 20.35, 4.84, 0), // 174182 Fish, anchovy, european, raw
  'Havuç': Nutrients(41, 0.93, 0.24, 9.58), // 170393 Carrots, raw
  'Hindistan Cevizi': Nutrients(660, 6.88, 64.53, 23.65), // 170170 Nuts, coconut meat, dried (desiccated), not sweetened
  'Humus': Nutrients(237, 7.78, 17.82, 15), // 174289 Hummus, commercial
  'Hurma': Nutrients(277, 1.81, 0.15, 74.97), // 168191 Dates, medjool
  'Ispanak': Nutrients(23, 2.86, 0.39, 3.63), // 168462 Spinach, raw
  'Kabak': Nutrients(17, 1.21, 0.32, 3.11), // 169291 Squash, summer, zucchini, includes skin, raw
  'Kabartma Tozu': Nutrients(53, 0, 0, 27.7), // 172803 Leavening agents, baking powder, double-acting, sodium aluminum sulfate
  'Kakao': Nutrients(228, 19.6, 13.7, 57.9), // 169593 Cocoa, dry powder, unsweetened
  'Kalamar': Nutrients(92, 15.58, 1.38, 3.08), // 174223 Mollusks, squid, mixed species, raw
  'Kapya Biber': Nutrients(26, 0.99, 0.3, 6.03), // 170108 Peppers, sweet, red, raw
  'Karabiber': Nutrients(251, 10.39, 3.26, 63.95), // 170931 Spices, pepper, black
  'Karides': Nutrients(85, 20.1, 0.51, 0), // 175179 Crustaceans, shrimp, raw
  'Karnabahar': Nutrients(25, 1.92, 0.28, 4.97), // 169986 Cauliflower, raw
  'Karpuz': Nutrients(30, 0.61, 0.15, 7.55), // 167765 Watermelon, raw
  'Kaşar Peyniri': Nutrients(351, 25.58, 26.62, 2.14), // 170850 Cheese, provolone
  'Kefir': Nutrients(43, 3.79, 1.02, 4.77), // 170904 Kefir, lowfat, plain, LIFEWAY
  'Kekik': Nutrients(276, 9.11, 7.43, 63.94), // 170938 Spices, thyme, dried
  'Kereviz': Nutrients(14, 0.69, 0.17, 2.97), // 169988 Celery, raw
  'Ketçap': Nutrients(101, 1.04, 0.1, 27.4), // 168556 Catsup
  'Kimyon': Nutrients(375, 17.81, 22.27, 44.24), // 170923 Spices, cumin seed
  'Kivi': Nutrients(61, 1.14, 0.52, 14.66), // 168153 Kiwifruit, green, raw
  'Kornişon Turşu': Nutrients(12, 0.5, 0.3, 2.41), // 168558 Pickles, cucumber, dill or kosher dill
  'Krema': Nutrients(340, 2.84, 36.08, 2.84), // 170859 Cream, fluid, heavy whipping
  'Kuru Fasulye': Nutrients(333, 23.36, 0.85, 60.27), // 175202 Beans, white, mature seeds, raw
  'Kuru Kayısı': Nutrients(241, 3.39, 0.51, 62.64), // 173941 Apricots, dried, sulfured, uncooked
  'Kuru Nane': Nutrients(285, 19.93, 6.03, 52.04), // 172239 Spearmint, dried
  'Kuru Üzüm': Nutrients(299, 3.3, 0.25, 79.32), // 168165 Raisins, dark, seedless (Includes foods for USDA's Food Distribution Program)
  'Kuru İncir': Nutrients(249, 3.3, 0.93, 63.87), // 174665 Figs, dried, uncooked
  'Kuvertür Çikolata': Nutrients(579, 6.12, 38.31, 52.42), // 170272 Chocolate, dark, 60-69% cacao solids
  'Kuzu İncik': Nutrients(201, 18.91, 13.38, 0), // 172481 Lamb, foreshank, separable lean and fat, trimmed to 1/4" fat, choice, raw
  'Kuşbaşı Et': Nutrients(173, 22.24, 8.67, 0), // 169534 Beef, round, top round, separable lean and fat, trimmed to 1/8" fat, prime, raw
  'Köftelik Bulgur': Nutrients(342, 12.29, 1.33, 75.87), // 170688 Bulgur, dry
  'Köri': Nutrients(325, 14.29, 14.01, 55.83), // 170924 Spices, curry powder
  'Kırmızı Mercimek': Nutrients(358, 23.91, 2.17, 63.1), // 174284 Lentils, pink or red, raw
  'Kırmızı Soğan': Nutrients(40, 1.1, 0.1, 9.34), // 170000 Onions, raw
  'Kıyma': Nutrients(215, 18.59, 15, 0), // 171796 Beef, ground, 85% lean meat / 15% fat, raw (Includes foods for USDA's Food Distribution Program)
  'Lahana': Nutrients(25, 1.28, 0.1, 5.8), // 169975 Cabbage, raw
  'Lavaş': Nutrients(275, 9.1, 1.2, 55.7), // 174915 Bread, pita, white, enriched
  'Lazanya': Nutrients(371, 13.04, 1.51, 74.67), // 169736 Pasta, dry, enriched
  'Leblebi': Nutrients(378, 20.47, 6.04, 62.95), // 173756 Chickpeas (garbanzo beans, bengal gram), mature seeds, raw
  'Levrek': Nutrients(97, 18.43, 2, 0), // 175142 Fish, sea bass, mixed species, raw
  'Limon': Nutrients(22, 0.35, 0.24, 6.9), // 167747 Lemon juice, raw
  'Lor Peyniri': Nutrients(81, 10.45, 2.27, 4.76), // 172182 Cheese, cottage, lowfat, 2% milkfat
  'Maden Suyu': Nutrients.zero, // enerjisiz
  'Makarna': Nutrients(371, 13.04, 1.51, 74.67), // 169736 Pasta, dry, enriched
  'Mango': Nutrients(60, 0.82, 0.38, 14.98), // 169910 Mangos, raw
  'Mantar': Nutrients(22, 3.09, 0.34, 3.26), // 169251 Mushrooms, white, raw
  'Mantı': Nutrients(288, 11.31, 2.3, 54.73), // 169727 Pasta, fresh-refrigerated, plain, as purchased
  'Marul': Nutrients(17, 1.23, 0.3, 3.29), // 169247 Lettuce, cos or romaine, raw
  'Maya': Nutrients(325, 40.44, 7.61, 41.22), // 175043 Leavening agents, yeast, baker's, active dry
  'Maydanoz': Nutrients(36, 2.97, 0.79, 6.33), // 170416 Parsley, fresh
  'Mayonez': Nutrients(680, 0.96, 74.85, 0.57), // 171009 Salad dressing, mayonnaise, regular
  'Mozzarella': Nutrients(299, 22.17, 22.14, 2.4), // 170845 Cheese, mozzarella, whole milk
  'Muz': Nutrients(89, 1.09, 0.33, 22.84), // 173944 Bananas, raw
  'Mısır Konservesi': Nutrients(67, 2.29, 1.22, 14.34), // 169214 Corn, sweet, yellow, canned, whole kernel, drained solids
  'Mısır Unu': Nutrients(362, 8.12, 3.59, 76.89), // 169697 Cornmeal, whole-grain, yellow
  'Nar': Nutrients(83, 1.67, 1.17, 18.7), // 169134 Pomegranates, raw
  'Nar Ekşisi': Nutrients(290, 0, 0.1, 74.73), // 168820 Molasses
  'Nişasta': Nutrients(381, 0.26, 0.05, 91.27), // 169698 Cornstarch
  'Nohut': Nutrients(378, 20.47, 6.04, 62.95), // 173756 Chickpeas (garbanzo beans, bengal gram), mature seeds, raw
  'Nohut Konservesi': Nutrients(139, 7.05, 2.77, 22.53), // 173800 Chickpeas (garbanzo beans, bengal gram), mature seeds, canned, drained solids
  'Palamut': Nutrients(144, 23.33, 4.9, 0), // 173706 Fish, tuna, fresh, bluefin, raw
  'Parmesan': Nutrients(392, 35.75, 25, 3.22), // 170848 Cheese, parmesan, hard
  'Pastırma': Nutrients(153, 31.1, 1.94, 2.76), // 170604 Beef, cured, dried
  'Patates': Nutrients(77, 2.05, 0.09, 17.49), // 170026 Potatoes, flesh and skin, raw
  'Patlıcan': Nutrients(25, 0.98, 0.18, 5.88), // 169228 Eggplant, raw
  'Penne': Nutrients(371, 13.04, 1.51, 74.67), // 169736 Pasta, dry, enriched
  'Pesto': Nutrients(418, 9.83, 37.6, 10.09), // 171579 Sauce, pesto, ready-to-serve, refrigerated
  'Pide': Nutrients(275, 9.1, 1.2, 55.7), // 174915 Bread, pita, white, enriched
  'Pirinç': Nutrients(365, 7.13, 0.66, 79.95), // 168877 Rice, white, long-grain, regular, raw, enriched
  'Pirinç Unu': Nutrients(366, 5.95, 1.42, 80.13), // 169714 Rice flour, white, unenriched
  'Portakal': Nutrients(47, 0.94, 0.12, 11.75), // 169097 Oranges, raw, all commercial varieties
  'Protein Tozu': Nutrients(352, 78.13, 1.56, 6.25), // 173180 Beverages, Protein powder whey based
  'Pudra Şekeri': Nutrients(389, 0, 0, 99.77), // 169656 Sugars, powdered
  'Pul Biber': Nutrients(318, 12.01, 17.27, 56.63), // 170932 Spices, pepper, red or cayenne
  'Pırasa': Nutrients(61, 1.5, 0.3, 14.15), // 169246 Leeks, (bulb and lower leaf-portion), raw
  'Roka': Nutrients(25, 2.58, 0.66, 3.65), // 169387 Arugula, raw
  'Salatalık': Nutrients(15, 0.65, 0.11, 3.63), // 168409 Cucumber, with peel, raw
  'Sarımsak': Nutrients(149, 6.36, 0.5, 33.06), // 169230 Garlic, raw
  'Semizotu': Nutrients(20, 2.03, 0.36, 3.39), // 169274 Purslane, raw
  'Simit': Nutrients(264, 10.56, 1.32, 52.38), // 174899 Bagels, plain, enriched, with calcium propionate (includes onion, poppy, sesame)
  'Sirke': Nutrients(18, 0, 0, 0.04), // 172237 Vinegar, distilled
  'Sivri Biber': Nutrients(20, 0.86, 0.17, 4.64), // 170427 Peppers, sweet, green, raw
  'Somon': Nutrients(208, 20.42, 13.42, 0), // 175167 Fish, salmon, Atlantic, farmed, raw
  'Soya Sosu': Nutrients(53, 8.14, 0.57, 4.93), // 174277 Soy sauce made from soy and wheat (shoyu)
  'Soğan': Nutrients(40, 1.1, 0.1, 9.34), // 170000 Onions, raw
  'Spagetti': Nutrients(371, 13.04, 1.51, 74.67), // 169736 Pasta, dry, enriched
  'Sucuk': Nutrients(378, 21.07, 31.65, 0.72), // 174582 Salami, dry or hard, pork, beef
  'Sumak': Nutrients(282, 14.14, 12.89, 53.99), // 171329 Spices, paprika
  'Süt': Nutrients(61, 3.15, 3.25, 4.8), // 171265 Milk, whole, 3.25% milkfat, with added vitamin D
  'Süzme Yoğurt': Nutrients(97, 9, 5, 3.98), // 171304 Yogurt, Greek, plain, whole milk
  'Tahin': Nutrients(592, 17.4, 53.01, 21.5), // 168604 Seeds, sesame butter, tahini, type of kernels unspecified
  'Tam Buğday Ekmeği': Nutrients(252, 12.45, 3.5, 42.71), // 172688 Bread, whole-wheat, commercially prepared
  'Tarhana': Nutrients(364, 10.33, 0.98, 76.31), // 168894 Wheat flour, white, all-purpose, enriched, bleached
  'Tarçın': Nutrients(247, 3.99, 1.24, 80.59), // 171320 Spices, cinnamon, ground
  'Tatlı Toz Biber': Nutrients(282, 14.14, 12.89, 53.99), // 171329 Spices, paprika
  'Tavuk Bonfile': Nutrients(120, 22.5, 2.62, 0), // 171077 Chicken, broiler or fryers, breast, skinless, boneless, meat only, raw
  'Tavuk But': Nutrients(221, 16.52, 16.61, 0.25), // 172385 Chicken, broilers or fryers, thigh, meat and skin, raw
  'Tavuk Göğsü': Nutrients(120, 22.5, 2.62, 0), // 171077 Chicken, broiler or fryers, breast, skinless, boneless, meat only, raw
  'Tavuk Kanat': Nutrients(191, 17.52, 12.85, 0), // 172390 Chicken, broilers or fryers, wing, meat and skin, raw
  'Taze Fasulye': Nutrients(31, 1.83, 0.22, 6.97), // 169961 Beans, snap, green, raw
  'Taze Nane': Nutrients(70, 3.75, 0.94, 14.89), // 173474 Peppermint, fresh
  'Taze Soğan': Nutrients(32, 1.83, 0.19, 7.34), // 170005 Onions, spring or scallions (includes tops and bulb), raw
  'Taze Zencefil': Nutrients(80, 1.82, 0.75, 17.77), // 169231 Ginger root, raw
  'Tel Şehriye': Nutrients(371, 13.04, 1.51, 74.67), // 169736 Pasta, dry, enriched
  'Tereyağı': Nutrients(717, 0.85, 81.11, 0.06), // 173430 Butter, without salt
  'Ton Balığı': Nutrients(198, 29.13, 8.21, 0), // 173708 Fish, tuna, light, canned in oil, drained solids
  'Tost Ekmeği': Nutrients(266, 8.85, 3.33, 49.42), // 174924 Bread, white, commercially prepared (includes soft bread crumbs)
  'Toz Şeker': Nutrients(387, 0, 0, 99.98), // 169655 Sugars, granulated
  'Tuz': Nutrients(0, 0, 0, 0), // 173468 Salt, table
  'Un': Nutrients(364, 10.33, 0.98, 76.31), // 168894 Wheat flour, white, all-purpose, enriched, bleached
  'Vanilin': Nutrients(56, 0.03, 0, 14.4), // 172236 Vanilla extract, imitation, no alcohol
  'Yaban Mersini': Nutrients(57, 0.74, 0.33, 14.49), // 171711 Blueberries, raw
  'Yenibahar': Nutrients(263, 6.09, 8.69, 72.12), // 171315 Spices, allspice, ground
  'Yeşil Elma': Nutrients(52, 0.26, 0.17, 13.81), // 171688 Apples, raw, with skin (Includes foods for USDA's Food Distribution Program)
  'Yeşil Mercimek': Nutrients(352, 24.63, 1.06, 63.35), // 172420 Lentils, raw
  'Yoğurt': Nutrients(61, 3.47, 3.25, 4.66), // 171284 Yogurt, plain, whole milk
  'Yufka': Nutrients(299, 7.1, 6, 52.6), // 172791 Phyllo dough
  'Yulaf': Nutrients(379, 13.15, 6.52, 67.7), // 173904 Cereals, oats, regular and quick, not fortified, dry
  'Yumurta': Nutrients(143, 12.56, 9.51, 0.72), // 171287 Egg, whole, raw, fresh
  'Zeytin': Nutrients(145, 1.03, 15.32, 3.84), // 169096 Olives, pickled, canned or bottled, green
  'Zeytinyağı': Nutrients(884, 0, 100, 0), // 171413 Oil, olive, salad or cooking
  'Çilek': Nutrients(32, 0.67, 0.3, 7.68), // 167762 Strawberries, raw
  'Çipura': Nutrients(97, 18.43, 2, 0), // 175142 Fish, sea bass, mixed species, raw
  'İrmik': Nutrients(360, 12.68, 1.05, 72.83), // 169715 Semolina, enriched
  'İsot': Nutrients(318, 12.01, 17.27, 56.63), // 170932 Spices, pepper, red or cayenne
  'Şehriye': Nutrients(371, 13.04, 1.51, 74.67), // 169736 Pasta, dry, enriched
};
