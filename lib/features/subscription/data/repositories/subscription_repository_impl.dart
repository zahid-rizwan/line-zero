import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;

  SubscriptionRepositoryImpl(this.remoteDataSource);

  @override
  Future<SubscriptionEntity> getSubscriptionStatus(String shopId) {
    return remoteDataSource.getSubscriptionStatus(shopId);
  }

  @override
  Future<SubscriptionEntity> subscribeShop({
    required String shopId,
    required String plan,
    String? purchaseToken,
  }) {
    return remoteDataSource.subscribeShop(
      shopId: shopId,
      plan: plan,
      purchaseToken: purchaseToken,
    );
  }

  @override
  Future<SubscriptionEntity> restorePurchases(String shopId) {
    return remoteDataSource.restorePurchases(shopId);
  }
}
