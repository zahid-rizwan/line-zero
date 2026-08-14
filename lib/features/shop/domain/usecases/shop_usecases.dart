import '../entities/shop_entity.dart';
import '../repositories/shop_repository.dart';

class GetShops {
  final ShopRepository repository;
  GetShops(this.repository);

  Future<List<ShopEntity>> call({String query = ''}) {
    return repository.getShops(query: query);
  }
}

class GetShopByOwnerId {
  final ShopRepository repository;
  GetShopByOwnerId(this.repository);

  Future<ShopEntity?> call(String ownerId) {
    return repository.getShopByOwnerId(ownerId);
  }
}

class CreateShop {
  final ShopRepository repository;
  CreateShop(this.repository);

  Future<ShopEntity> call(ShopEntity shop) {
    return repository.createShop(shop);
  }
}

class ToggleQueueStatus {
  final ShopRepository repository;
  ToggleQueueStatus(this.repository);

  Future<void> call({required String shopId, required bool isOpen}) {
    return repository.toggleQueueStatus(shopId: shopId, isOpen: isOpen);
  }
}

class DeleteShop {
  final ShopRepository repository;
  DeleteShop(this.repository);

  Future<void> call(String shopId) {
    return repository.deleteShop(shopId);
  }
}
