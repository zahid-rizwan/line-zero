import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionStatus {
  final SubscriptionRepository repository;
  GetSubscriptionStatus(this.repository);

  Future<SubscriptionEntity> call(String shopId) {
    return repository.getSubscriptionStatus(shopId);
  }
}

class SubscribeShop {
  final SubscriptionRepository repository;
  SubscribeShop(this.repository);

  Future<SubscriptionEntity> call({
    required String shopId,
    required String plan,
    String? purchaseToken,
  }) {
    return repository.subscribeShop(
      shopId: shopId,
      plan: plan,
      purchaseToken: purchaseToken,
    );
  }
}

class RestorePurchases {
  final SubscriptionRepository repository;
  RestorePurchases(this.repository);

  Future<SubscriptionEntity> call(String shopId) {
    return repository.restorePurchases(shopId);
  }
}
