class PricingConfigEntity {
  final int monthlyPrice;
  final int yearlyPrice;
  final int discountPercentage;
  final bool isSaleActive;
  final String saleBannerText;
  final int saleMonthlyPrice;
  final int saleYearlyPrice;

  PricingConfigEntity({
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.discountPercentage,
    required this.isSaleActive,
    required this.saleBannerText,
    required this.saleMonthlyPrice,
    required this.saleYearlyPrice,
  });

  int get effectiveMonthlyPrice => isSaleActive ? saleMonthlyPrice : monthlyPrice;
  int get effectiveYearlyPrice => isSaleActive ? saleYearlyPrice : yearlyPrice;

  String get monthlyDisplay => '₹$effectiveMonthlyPrice / month';
  String get yearlyDisplay => '₹$effectiveYearlyPrice / year';

  factory PricingConfigEntity.defaultConfig() {
    return PricingConfigEntity(
      monthlyPrice: 1,
      yearlyPrice: 12,
      discountPercentage: 20,
      isSaleActive: false,
      saleBannerText: '🔥 SPECIAL OFFER: Limited Time Discount!',
      saleMonthlyPrice: 1,
      saleYearlyPrice: 10,
    );
  }

  Map<String, dynamic> toMap() => {
        'monthlyPrice': monthlyPrice,
        'yearlyPrice': yearlyPrice,
        'discountPercentage': discountPercentage,
        'isSaleActive': isSaleActive,
        'saleBannerText': saleBannerText,
        'saleMonthlyPrice': saleMonthlyPrice,
        'saleYearlyPrice': saleYearlyPrice,
      };

  factory PricingConfigEntity.fromMap(Map<String, dynamic> map) => PricingConfigEntity(
        monthlyPrice: map['monthlyPrice'] ?? 1,
        yearlyPrice: map['yearlyPrice'] ?? 12,
        discountPercentage: map['discountPercentage'] ?? 20,
        isSaleActive: map['isSaleActive'] ?? false,
        saleBannerText: map['saleBannerText'] ?? '🔥 SPECIAL OFFER: Limited Time Discount!',
        saleMonthlyPrice: map['saleMonthlyPrice'] ?? 1,
        saleYearlyPrice: map['saleYearlyPrice'] ?? 10,
      );
}
