/// Türkçe duyarlı arama: "sut" yazınca "Süt", "ISPANAK" yazınca "Ispanak" bulunur.
String normalizeTr(String input) {
  final lower = input
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase();
  const map = {'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u'};
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    buf.write(map[ch] ?? ch);
  }
  return buf.toString().trim();
}

/// İsimden kalıcı, cihazlar arası aynı kalan kimlik üretir: "Kaşar Peyniri" → "ing_kasar_peyniri".
String slugId(String name) =>
    'ing_${normalizeTr(name).replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '')}';

/// Arama sıralaması: baştan eşleşme > kelime başı eşleşme > içinde geçme. Eşleşmezse null.
int? matchScore(String name, String query) {
  final n = normalizeTr(name);
  final q = normalizeTr(query);
  if (q.isEmpty) return null;
  if (n.startsWith(q)) return 0;
  if (n.split(' ').any((w) => w.startsWith(q))) return 1;
  if (n.contains(q)) return 2;
  return null;
}
