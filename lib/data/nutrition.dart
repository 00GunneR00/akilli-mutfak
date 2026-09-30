/// Enerji (kcal) ve makrolar (g). Malzemeler için 100 g başına, tarifler için
/// bir porsiyon başına kullanılır.
class Nutrients {
  const Nutrients(this.kcal, this.protein, this.fat, this.carb);

  static const zero = Nutrients(0, 0, 0, 0);

  final double kcal;
  final double protein;
  final double fat;
  final double carb;

  Nutrients operator +(Nutrients o) => Nutrients(
      kcal + o.kcal, protein + o.protein, fat + o.fat, carb + o.carb);

  Nutrients operator *(double f) =>
      Nutrients(kcal * f, protein * f, fat * f, carb * f);
}
