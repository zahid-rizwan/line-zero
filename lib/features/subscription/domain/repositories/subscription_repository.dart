import '../entities/subscription_entity.dart';
import '../entities/pricing_config_entity.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionEntity> getSubscriptionStatus(String shopId);
  Future<SubscriptionEntity> subscribeShop({
    required String shopId,
    required String plan, // 'monthly' | 'yearly'
    String? purchaseToken,
  });
  Future<SubscriptionEntity> restorePurchases(String shopId);
  Future<PricingConfigEntity> getPricingConfig();
  Future<void> updatePricingConfig(PricingConfigEntity config);
}
