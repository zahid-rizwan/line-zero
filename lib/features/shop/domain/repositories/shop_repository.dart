import '../entities/shop_entity.dart';

abstract class ShopRepository {
  Future<List<ShopEntity>> getShops({String query = ''});
  Future<ShopEntity?> getShopByOwnerId(String ownerId);
  Future<ShopEntity?> getShopById(String shopId);
  Future<ShopEntity> createShop(ShopEntity shop);
  Future<void> toggleQueueStatus({required String shopId, required bool isOpen});
  Future<void> deleteShop(String shopId);
}
