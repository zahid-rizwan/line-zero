import '../../domain/entities/pricing_config_entity.dart';

abstract class SubscriptionEvent {}

class SubscriptionFetchRequested extends SubscriptionEvent {
  final String shopId;
  SubscriptionFetchRequested(this.shopId);
}

class SubscribeRequested extends SubscriptionEvent {
  final String shopId;
  final String plan; // 'monthly' | 'yearly'
  final String? purchaseToken;

  SubscribeRequested({
    required this.shopId,
    required this.plan,
    this.purchaseToken,
  });
}

class RestorePurchasesRequested extends SubscriptionEvent {
  final String shopId;
  RestorePurchasesRequested(this.shopId);
}

class PricingConfigFetchRequested extends SubscriptionEvent {}

class PricingConfigUpdateRequested extends SubscriptionEvent {
  final PricingConfigEntity config;
  PricingConfigUpdateRequested(this.config);
}
