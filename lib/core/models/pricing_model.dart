/// A single tier's numbers for the resolved region/currency.
class PricingTier {
  final int monthly;
  final int annualMonthlyEquivalent;
  final int annualTotal;
  final bool trialEligible;

  const PricingTier({
    required this.monthly,
    required this.annualMonthlyEquivalent,
    required this.annualTotal,
    required this.trialEligible,
  });

  factory PricingTier.fromJson(Map<String, dynamic> json) => PricingTier(
        monthly: json['monthly'] as int,
        annualMonthlyEquivalent: json['annual_monthly_equivalent'] as int,
        annualTotal: json['annual_total'] as int,
        trialEligible: json['trial_eligible'] as bool,
      );
}

/// Full response from GET /api/pricing — region-resolved currency and
/// tier pricing, ready to render without any further client-side math.
class PricingData {
  final String? country;
  final String resolvedBy;
  final String currency;
  final String symbol;
  final bool symbolAfter;
  final bool isFinalized;
  final int trialDays;
  final int annualDiscountPercent;
  final PricingTier starter;
  final PricingTier growth;
  final PricingTier pro;
  final int enterprisePerBranchFrom;
  final String? disclaimer;

  const PricingData({
    required this.country,
    required this.resolvedBy,
    required this.currency,
    required this.symbol,
    required this.symbolAfter,
    required this.isFinalized,
    required this.trialDays,
    required this.annualDiscountPercent,
    required this.starter,
    required this.growth,
    required this.pro,
    required this.enterprisePerBranchFrom,
    required this.disclaimer,
  });

  factory PricingData.fromJson(Map<String, dynamic> json) {
    final tiers = json['tiers'] as Map<String, dynamic>;
    return PricingData(
      country: json['country'] as String?,
      resolvedBy: json['resolved_by'] as String? ?? 'default',
      currency: json['currency'] as String,
      symbol: json['symbol'] as String,
      symbolAfter: json['symbol_position'] == 'after',
      isFinalized: json['is_finalized'] as bool,
      trialDays: json['trial_days'] as int,
      annualDiscountPercent: json['annual_discount_percent'] as int,
      starter: PricingTier.fromJson(tiers['starter'] as Map<String, dynamic>),
      growth: PricingTier.fromJson(tiers['growth'] as Map<String, dynamic>),
      pro: PricingTier.fromJson(tiers['pro'] as Map<String, dynamic>),
      enterprisePerBranchFrom:
          (json['enterprise'] as Map<String, dynamic>)['per_branch_from'] as int,
      disclaimer: json['disclaimer'] as String?,
    );
  }

  /// Formats a whole-number amount with the currency symbol in the
  /// correct position for this region (e.g. "749 ج.م" vs "$29") — do not
  /// rely on bidi/Directionality to place the symbol, it isn't reliable
  /// with mixed Arabic/Latin-digit text.
  String format(int amount) =>
      symbolAfter ? '$amount $symbol' : '$symbol$amount';
}
