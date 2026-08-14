import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:queue_token_app/core/services/firebase_service.dart';
import 'package:queue_token_app/core/services/mock_service.dart';
import '../../domain/entities/subscription_entity.dart';

abstract class SubscriptionRemoteDataSource {
  Future<SubscriptionEntity> getSubscriptionStatus(String shopId);
  Future<SubscriptionEntity> subscribeShop({
    required String shopId,
    required String plan,
    String? purchaseToken,
  });
  Future<SubscriptionEntity> restorePurchases(String shopId);
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final MockDatabaseService mockDb = MockDatabaseService.instance;

  @override
  Future<SubscriptionEntity> getSubscriptionStatus(String shopId) async {
    if (FirebaseService.isInitialized) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .collection('subscription')
            .doc('current')
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          return _mapSubscriptionData(shopId, data);
        } else {
          // Auto-provision 30-day free trial on Cloud Firestore if missing
          final now = DateTime.now();
          final trialEndsAt = now.add(const Duration(days: 30));
          final initialData = {
            'status': 'trial',
            'plan': null,
            'trialEndsAt': Timestamp.fromDate(trialEndsAt),
            'currentPeriodEnd': null,
            'playPurchaseToken': null,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          };

          await FirebaseFirestore.instance
              .collection('shops')
              .doc(shopId)
              .collection('subscription')
              .doc('current')
              .set(initialData, SetOptions(merge: true));

          return SubscriptionEntity(
            shopId: shopId,
            status: 'trial',
            plan: null,
            trialEndsAt: trialEndsAt,
            createdAt: now,
            updatedAt: now,
          );
        }
      } catch (e) {
        debugPrint('Firestore subscription fetch notice: $e');
      }
    }

    final data = mockDb.getSubscriptionData(shopId);
    return _mapRawSubscriptionData(shopId, data);
  }

  @override
  Future<SubscriptionEntity> subscribeShop({
    required String shopId,
    required String plan,
    String? purchaseToken,
  }) async {
    final now = DateTime.now();
    final days = plan == 'yearly' ? 365 : 30;
    final periodEnd = now.add(Duration(days: days));
    final token = purchaseToken ?? 'token-${now.millisecondsSinceEpoch}';

    if (FirebaseService.isInitialized) {
      try {
        final updateData = {
          'status': 'active',
          'plan': plan,
          'trialEndsAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
          'currentPeriodEnd': Timestamp.fromDate(periodEnd),
          'playPurchaseToken': token,
          'updatedAt': Timestamp.fromDate(now),
        };

        await FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .collection('subscription')
            .doc('current')
            .set(updateData, SetOptions(merge: true));

        return SubscriptionEntity(
          shopId: shopId,
          status: 'active',
          plan: plan,
          trialEndsAt: now.subtract(const Duration(days: 1)),
          currentPeriodEnd: periodEnd,
          playPurchaseToken: token,
          createdAt: now,
          updatedAt: now,
        );
      } catch (e) {
        debugPrint('Firestore subscribeShop notice: $e');
      }
    }

    final data = mockDb.subscribeShop(shopId, plan, token);
    return _mapRawSubscriptionData(shopId, data);
  }

  @override
  Future<SubscriptionEntity> restorePurchases(String shopId) async {
    return getSubscriptionStatus(shopId);
  }

  SubscriptionEntity _mapSubscriptionData(String shopId, Map<String, dynamic> data) {
    final trialEnds = (data['trialEndsAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30));
    final periodEnd = (data['currentPeriodEnd'] as Timestamp?)?.toDate();
    final created = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updated = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    var status = data['status'] ?? 'trial';
    if (status == 'trial' && DateTime.now().isAfter(trialEnds)) {
      status = 'expired';
    }

    return SubscriptionEntity(
      shopId: shopId,
      status: status,
      plan: data['plan'],
      trialEndsAt: trialEnds,
      currentPeriodEnd: periodEnd,
      playPurchaseToken: data['playPurchaseToken'],
      createdAt: created,
      updatedAt: updated,
    );
  }

  SubscriptionEntity _mapRawSubscriptionData(String shopId, Map<String, dynamic> data) {
    final trialEnds = DateTime.parse(data['trialEndsAt']);
    final periodEnd = data['currentPeriodEnd'] != null ? DateTime.parse(data['currentPeriodEnd']) : null;
    final created = DateTime.parse(data['createdAt']);
    final updated = DateTime.parse(data['updatedAt']);

    var status = data['status'] ?? 'trial';
    if (status == 'trial' && DateTime.now().isAfter(trialEnds)) {
      status = 'expired';
    }

    return SubscriptionEntity(
      shopId: shopId,
      status: status,
      plan: data['plan'],
      trialEndsAt: trialEnds,
      currentPeriodEnd: periodEnd,
      playPurchaseToken: data['playPurchaseToken'],
      createdAt: created,
      updatedAt: updated,
    );
  }
}
