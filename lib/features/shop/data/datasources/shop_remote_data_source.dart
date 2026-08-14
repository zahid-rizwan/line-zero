import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:queue_token_app/core/services/firebase_service.dart';
import 'package:queue_token_app/core/services/mock_service.dart';
import 'package:queue_token_app/features/shop/domain/entities/shop_entity.dart';

abstract class ShopRemoteDataSource {
  Future<List<ShopEntity>> getShops({String query = ''});
  Future<ShopEntity?> getShopByOwnerId(String ownerId);
  Future<ShopEntity?> getShopById(String shopId);
  Future<ShopEntity> createShop(ShopEntity shop);
  Future<void> toggleQueueStatus({required String shopId, required bool isOpen});
  Future<void> deleteShop(String shopId);
}

class ShopRemoteDataSourceImpl implements ShopRemoteDataSource {
  final MockDatabaseService mockDb = MockDatabaseService.instance;

  @override
  Future<List<ShopEntity>> getShops({String query = ''}) async {
    if (FirebaseService.isInitialized) {
      try {
        final querySnapshot = await FirebaseFirestore.instance.collection('shops').get();
        final shops = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return ShopEntity(
            id: doc.id,
            name: data['name'] ?? '',
            category: data['category'] ?? '',
            ownerId: data['ownerId'] ?? '',
            address: data['address'] ?? '',
            isQueueOpen: data['isQueueOpen'] ?? true,
            avgServiceTimeMinutes: data['avgServiceTimeMinutes'] ?? 10,
          );
        }).toList();

        if (query.isEmpty) return shops;
        return shops
            .where((s) => s.name.toLowerCase().contains(query.toLowerCase()) || s.category.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } catch (e) {
        debugPrint('Firebase Firestore error: $e. Falling back to Mock DB.');
      }
    }

    final mockShops = await mockDb.getShops(query: query);
    return mockShops
        .map((s) => ShopEntity(
              id: s.id,
              name: s.name,
              category: s.category,
              ownerId: s.ownerId,
              address: s.address,
              isQueueOpen: s.isQueueOpen,
              avgServiceTimeMinutes: s.avgServiceTimeMinutes,
            ))
        .toList();
  }

  @override
  Future<ShopEntity?> getShopByOwnerId(String ownerId) async {
    if (FirebaseService.isInitialized) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('shops')
            .where('ownerId', isEqualTo: ownerId)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final data = doc.data();
          return ShopEntity(
            id: doc.id,
            name: data['name'] ?? '',
            category: data['category'] ?? '',
            ownerId: data['ownerId'] ?? '',
            address: data['address'] ?? '',
            isQueueOpen: data['isQueueOpen'] ?? true,
            avgServiceTimeMinutes: data['avgServiceTimeMinutes'] ?? 10,
          );
        }
      } catch (_) {}
    }

    final mockShop = await mockDb.getShopByOwnerId(ownerId);
    if (mockShop != null) {
      return ShopEntity(
        id: mockShop.id,
        name: mockShop.name,
        category: mockShop.category,
        ownerId: mockShop.ownerId,
        address: mockShop.address,
        isQueueOpen: mockShop.isQueueOpen,
        avgServiceTimeMinutes: mockShop.avgServiceTimeMinutes,
      );
    }
    return null;
  }

  @override
  Future<ShopEntity?> getShopById(String shopId) async {
    if (FirebaseService.isInitialized) {
      try {
        final doc = await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
        if (doc.exists) {
          final data = doc.data()!;
          return ShopEntity(
            id: doc.id,
            name: data['name'] ?? '',
            category: data['category'] ?? '',
            ownerId: data['ownerId'] ?? '',
            address: data['address'] ?? '',
            isQueueOpen: data['isQueueOpen'] ?? true,
            avgServiceTimeMinutes: data['avgServiceTimeMinutes'] ?? 10,
          );
        }
      } catch (_) {}
    }

    final mockShop = await mockDb.getShopById(shopId);
    if (mockShop != null) {
      return ShopEntity(
        id: mockShop.id,
        name: mockShop.name,
        category: mockShop.category,
        ownerId: mockShop.ownerId,
        address: mockShop.address,
        isQueueOpen: mockShop.isQueueOpen,
        avgServiceTimeMinutes: mockShop.avgServiceTimeMinutes,
      );
    }
    return null;
  }

  @override
  Future<ShopEntity> createShop(ShopEntity shop) async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance.collection('shops').add({
          'name': shop.name,
          'category': shop.category,
          'ownerId': shop.ownerId,
          'address': shop.address,
          'isQueueOpen': shop.isQueueOpen,
          'avgServiceTimeMinutes': shop.avgServiceTimeMinutes,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return shop.copyWith(name: shop.name);
      } catch (_) {}
    }

    final created = await mockDb.createShop(MockShop(
      id: shop.id,
      name: shop.name,
      category: shop.category,
      ownerId: shop.ownerId,
      address: shop.address,
      isQueueOpen: shop.isQueueOpen,
      avgServiceTimeMinutes: shop.avgServiceTimeMinutes,
    ));

    return ShopEntity(
      id: created.id,
      name: created.name,
      category: created.category,
      ownerId: created.ownerId,
      address: created.address,
      isQueueOpen: created.isQueueOpen,
      avgServiceTimeMinutes: created.avgServiceTimeMinutes,
    );
  }

  @override
  Future<void> toggleQueueStatus({required String shopId, required bool isOpen}) async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance.collection('shops').doc(shopId).update({
          'isQueueOpen': isOpen,
        });
      } catch (_) {}
    }
    await mockDb.toggleQueueStatus(shopId, isOpen);
  }

  @override
  Future<void> deleteShop(String shopId) async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance.collection('shops').doc(shopId).delete();
      } catch (_) {}
    }
    await mockDb.deleteShop(shopId);
  }
}
