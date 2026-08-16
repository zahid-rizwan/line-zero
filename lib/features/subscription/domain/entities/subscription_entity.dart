class SubscriptionEntity {
  final String shopId;
  final String status; // 'trial' | 'active' | 'expired' | 'cancelled'
  final String? plan; // 'monthly' | 'yearly' | null
  final DateTime trialEndsAt;
  final DateTime? currentPeriodEnd;
  final String? playPurchaseToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionEntity({
    required this.shopId,
    required this.status,
    this.plan,
    required this.trialEndsAt,
    this.currentPeriodEnd,
    this.playPurchaseToken,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTrial => status == 'trial';
  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired' || (isTrial && DateTime.now().isAfter(trialEndsAt));

  int get daysLeftInTrial {
    if (status != 'trial') return 0;
    final now = DateTime.now();
    final difference = trialEndsAt.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  SubscriptionEntity copyWith({
    String? status,
    String? plan,
    DateTime? trialEndsAt,
    DateTime? currentPeriodEnd,
    String? playPurchaseToken,
    DateTime? updatedAt,
  }) {
    return SubscriptionEntity(
      shopId: shopId,
      status: status ?? this.status,
      plan: plan ?? this.plan,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      playPurchaseToken: playPurchaseToken ?? this.playPurchaseToken,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
