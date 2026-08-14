import '../datasources/shop_remote_data_source.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/shop_repository.dart';

class ShopRepositoryImpl implements ShopRepository {
  final ShopRemoteDataSource remoteDataSource;

  ShopRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ShopEntity>> getShops({String query = ''}) {
    return remoteDataSource.getShops(query: query);
  }

  @override
  Future<ShopEntity?> getShopByOwnerId(String ownerId) {
    return remoteDataSource.getShopByOwnerId(ownerId);
  }

  @override
  Future<ShopEntity?> getShopById(String shopId) {
    return remoteDataSource.getShopById(shopId);
  }

  @override
  Future<ShopEntity> createShop(ShopEntity shop) {
    return remoteDataSource.createShop(shop);
  }

  @override
  Future<void> toggleQueueStatus({required String shopId, required bool isOpen}) {
    return remoteDataSource.toggleQueueStatus(shopId: shopId, isOpen: isOpen);
  }

  @override
  Future<void> deleteShop(String shopId) {
    return remoteDataSource.deleteShop(shopId);
  }
}
