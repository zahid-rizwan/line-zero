import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:queue_token_app/core/services/firebase_service.dart';
import 'package:queue_token_app/core/services/mock_service.dart';
import 'package:queue_token_app/features/queue/domain/entities/ticket_entity.dart';

abstract class QueueRemoteDataSource {
  Stream<List<TicketEntity>> watchShopQueue(String shopId);
  Stream<List<TicketEntity>> watchCustomerActiveTickets(String customerId);
  Future<TicketEntity> joinQueue({
    required String shopId,
    required String customerId,
    required String customerName,
  });
  Future<TicketEntity> addWalkInTicket({
    required String shopId,
    String? customerName,
  });
  Future<void> confirmCheckpoint({
    required String shopId,
    required String ticketId,
  });
  Future<void> moveToPending({
    required String shopId,
    required String ticketId,
  });
  Future<void> readdFromPending({
    required String shopId,
    required String ticketId,
  });
  Future<void> updateTicketStatus({
    required String shopId,
    required String ticketId,
    required String newStatus,
  });
  Future<void> callNextTicket(String shopId);
}

class QueueRemoteDataSourceImpl implements QueueRemoteDataSource {
  final MockDatabaseService mockDb = MockDatabaseService.instance;

  TicketEntity _mapDocToEntity(String docId, String shopId, Map<String, dynamic> data) {
    return TicketEntity(
      id: docId,
      shopId: shopId,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      tokenNumber: data['tokenNumber'] ?? 0,
      status: data['status'] ?? 'waiting',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      calledAt: (data['calledAt'] as Timestamp?)?.toDate(),
      originalEstimatedReadyAt: (data['originalEstimatedReadyAt'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      heldUntil: (data['heldUntil'] as Timestamp?)?.toDate(),
      extensionUsed: data['extensionUsed'] ?? false,
      movedToPendingAt: (data['movedToPendingAt'] as Timestamp?)?.toDate(),
      pendingPriority: data['pendingPriority'],
      isWalkIn: data['isWalkIn'] ?? false,
    );
  }

  TicketEntity _mapMockToEntity(MockTicket t) {
    return TicketEntity(
      id: t.id,
      shopId: t.shopId,
      customerId: t.customerId,
      customerName: t.customerName,
      tokenNumber: t.tokenNumber,
      status: t.status,
      joinedAt: t.joinedAt,
      calledAt: t.calledAt,
      originalEstimatedReadyAt: t.originalEstimatedReadyAt,
      confirmedAt: t.confirmedAt,
      heldUntil: t.heldUntil,
      extensionUsed: t.extensionUsed,
      movedToPendingAt: t.movedToPendingAt,
      pendingPriority: t.pendingPriority,
      isWalkIn: t.isWalkIn,
    );
  }

  @override
  Stream<List<TicketEntity>> watchShopQueue(String shopId) {
    if (FirebaseService.isInitialized) {
      try {
        return FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .collection('queue')
            .orderBy('tokenNumber')
            .snapshots()
            .map((snapshot) {
          return snapshot.docs.map((doc) => _mapDocToEntity(doc.id, shopId, doc.data())).toList();
        }).handleError((e) {
          debugPrint('Firestore stream error: $e. Falling back to Mock DB.');
        });
      } catch (e) {
        debugPrint('Firebase stream setup error: $e. Falling back to Mock DB.');
      }
    }

    return mockDb.watchShopQueue(shopId).map((mockTickets) {
      return mockTickets.map((t) => _mapMockToEntity(t)).toList();
    });
  }

  @override
  Stream<List<TicketEntity>> watchCustomerActiveTickets(String customerId) {
    if (FirebaseService.isInitialized) {
      try {
        return FirebaseFirestore.instance
            .collectionGroup('queue')
            .where('customerId', isEqualTo: customerId)
            .snapshots()
            .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final parentShopId = doc.reference.parent.parent?.id ?? '';
                return _mapDocToEntity(doc.id, parentShopId, doc.data());
              })
              .where((t) => t.status == 'waiting' || t.status == 'confirmed' || t.status == 'called' || t.status == 'in_service' || t.status == 'pending')
              .toList();
        }).handleError((e) {
          debugPrint('Firestore customer active tickets error: $e. Falling back to Mock DB.');
        });
      } catch (e) {
        debugPrint('Firebase stream setup error: $e. Falling back to Mock DB.');
      }
    }

    return mockDb.watchCustomerActiveTickets(customerId).map((mockTickets) {
      return mockTickets.map((t) => _mapMockToEntity(t)).toList();
    });
  }

  @override
  Future<TicketEntity> joinQueue({
    required String shopId,
    required String customerId,
    required String customerName,
  }) async {
    if (FirebaseService.isInitialized) {
      try {
        final firestore = FirebaseFirestore.instance;
        final shopRef = firestore.collection('shops').doc(shopId);

        return await firestore.runTransaction<TicketEntity>((transaction) async {
          final shopDoc = await transaction.get(shopRef);
          if (!shopDoc.exists || !(shopDoc.data()?['isQueueOpen'] ?? false)) {
            throw Exception('Queue is currently closed.');
          }

          final existingQuery = await shopRef
              .collection('queue')
              .where('customerId', isEqualTo: customerId)
              .where('status', whereIn: ['waiting', 'confirmed', 'in_service'])
              .get();
          if (existingQuery.docs.isNotEmpty) {
            throw Exception('You already have an active ticket in this queue.');
          }

          final queueQuery = await shopRef.collection('queue').orderBy('tokenNumber', descending: true).limit(1).get();
          int lastTokenNumber = 0;
          if (queueQuery.docs.isNotEmpty) {
            lastTokenNumber = queueQuery.docs.first.data()['tokenNumber'] ?? 0;
          }
          final newTokenNumber = lastTokenNumber + 1;

          final ticketRef = shopRef.collection('queue').doc();
          final ticketData = {
            'customerId': customerId,
            'customerName': customerName,
            'tokenNumber': newTokenNumber,
            'status': 'waiting',
            'joinedAt': FieldValue.serverTimestamp(),
            'calledAt': null,
            'isWalkIn': false,
          };

          transaction.set(ticketRef, ticketData);

          return TicketEntity(
            id: ticketRef.id,
            shopId: shopId,
            customerId: customerId,
            customerName: customerName,
            tokenNumber: newTokenNumber,
            status: 'waiting',
            joinedAt: DateTime.now(),
            isWalkIn: false,
          );
        });
      } catch (e) {
        if (e.toString().contains('already have an active ticket')) {
          rethrow;
        }
      }
    }

    final mockTicket = await mockDb.joinQueue(shopId, customerId, customerName);
    return _mapMockToEntity(mockTicket);
  }

  @override
  Future<TicketEntity> addWalkInTicket({
    required String shopId,
    String? customerName,
  }) async {
    if (FirebaseService.isInitialized) {
      try {
        final firestore = FirebaseFirestore.instance;
        final shopRef = firestore.collection('shops').doc(shopId);

        final ticketEntity = await firestore.runTransaction<TicketEntity>((transaction) async {
          final shopDoc = await transaction.get(shopRef);
          if (!shopDoc.exists || !(shopDoc.data()?['isQueueOpen'] ?? false)) {
            throw Exception('Queue is currently closed.');
          }

          final queueQuery = await shopRef.collection('queue').orderBy('tokenNumber', descending: true).limit(1).get();
          int lastTokenNumber = 0;
          if (queueQuery.docs.isNotEmpty) {
            lastTokenNumber = queueQuery.docs.first.data()['tokenNumber'] ?? 0;
          }
          final newTokenNumber = lastTokenNumber + 1;

          final displayName = (customerName != null && customerName.trim().isNotEmpty)
              ? customerName.trim()
              : 'Walk-in #$newTokenNumber';

          final ticketRef = shopRef.collection('queue').doc();
          final ticketData = {
            'customerId': '',
            'customerName': displayName,
            'tokenNumber': newTokenNumber,
            'status': 'waiting',
            'joinedAt': FieldValue.serverTimestamp(),
            'calledAt': null,
            'isWalkIn': true,
          };

          transaction.set(ticketRef, ticketData);

          return TicketEntity(
            id: ticketRef.id,
            shopId: shopId,
            customerId: '',
            customerName: displayName,
            tokenNumber: newTokenNumber,
            status: 'waiting',
            joinedAt: DateTime.now(),
            isWalkIn: true,
          );
        });

        // Sync with mock db so local streams stay consistent
        await mockDb.addWalkInTicket(shopId, customerName);
        return ticketEntity;
      } catch (e) {
        debugPrint('Firebase addWalkInTicket error: $e. Falling back to Mock DB.');
      }
    }

    final mockTicket = await mockDb.addWalkInTicket(shopId, customerName);
    return _mapMockToEntity(mockTicket);
  }

  @override
  Future<void> confirmCheckpoint({
    required String shopId,
    required String ticketId,
  }) async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .collection('queue')
            .doc(ticketId)
            .update({
          'status': 'confirmed',
          'confirmedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
    await mockDb.confirmCheckpoint(shopId, ticketId);
  }

  @override
  Future<void> moveToPending({
    required String shopId,
    required String ticketId,
  }) async {
    if (FirebaseService.isInitialized) {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .collection('queue')
            .doc(ticketId);

        final docSnap = await docRef.get();
        if (docSnap.exists) {
          final data = docSnap.data()!;
          final calledAt = (data['calledAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final originalEst = (data['originalEstimatedReadyAt'] as Timestamp?)?.toDate();

          String priority = 'low';
          if (originalEst != null) {
            final diffMins = originalEst.difference(calledAt).inMinutes;
            if (diffMins >= 10) {
              priority = 'high';
            }
          }

          await docRef.update({
            'status': 'pending',
            'movedToPendingAt': FieldValue.serverTimestamp(),
            'pendingPriority': priority,
          });
        }
      } catch (_) {}
    }
    await mockDb.moveToPending(shopId, ticketId);
  }

  @override
  Future<void> readdFromPending({
    required String shopId,
    required String ticketId,
  }) async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .collection('queue')
            .doc(ticketId)
            .update({
          'status': 'waiting',
        });
      } catch (_) {}
    }
    await mockDb.readdFromPending(shopId, ticketId);
  }

  @override
  Future<void> updateTicketStatus({
    required String shopId,
    required String ticketId,
    required String newStatus,
  }) async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .collection('queue')
            .doc(ticketId)
            .update({
          'status': newStatus,
          if (newStatus == 'in_service' || newStatus == 'called') 'calledAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    await mockDb.updateTicketStatus(shopId, ticketId, newStatus);
  }

  @override
  Future<void> callNextTicket(String shopId) async {
    if (FirebaseService.isInitialized) {
      try {
        final queueRef = FirebaseFirestore.instance.collection('shops').doc(shopId).collection('queue');

        final snapshot = await queueRef.get();
        final docs = snapshot.docs;

        // Mark current 'in_service' ticket as 'completed'
        for (var doc in docs) {
          final data = doc.data();
          if (data['status'] == 'in_service') {
            await doc.reference.update({'status': 'completed'});
          }
        }

        // Find waiting/confirmed tickets and sort by tokenNumber
        final waitingDocs = docs.where((doc) => doc.data()['status'] == 'waiting' || doc.data()['status'] == 'confirmed').toList();
        waitingDocs.sort((a, b) {
          final numA = (a.data()['tokenNumber'] ?? 0) as int;
          final numB = (b.data()['tokenNumber'] ?? 0) as int;
          return numA.compareTo(numB);
        });

        if (waitingDocs.isNotEmpty) {
          await waitingDocs.first.reference.update({
            'status': 'in_service',
            'calledAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('Firebase callNextTicket notice: $e');
      }
    }

    await mockDb.callNextTicket(shopId);
  }
}
