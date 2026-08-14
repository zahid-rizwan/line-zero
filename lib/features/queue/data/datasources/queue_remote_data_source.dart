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
  Future<void> updateTicketStatus({
    required String shopId,
    required String ticketId,
    required String newStatus,
  });
  Future<void> callNextTicket(String shopId);
}

class QueueRemoteDataSourceImpl implements QueueRemoteDataSource {
  final MockDatabaseService mockDb = MockDatabaseService.instance;

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
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return TicketEntity(
              id: doc.id,
              shopId: shopId,
              customerId: data['customerId'] ?? '',
              customerName: data['customerName'] ?? '',
              tokenNumber: data['tokenNumber'] ?? 0,
              status: data['status'] ?? 'waiting',
              joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              calledAt: (data['calledAt'] as Timestamp?)?.toDate(),
            );
          }).toList();
        }).handleError((e) {
          debugPrint('Firestore stream error: $e. Falling back to Mock DB.');
        });
      } catch (e) {
        debugPrint('Firebase stream setup error: $e. Falling back to Mock DB.');
      }
    }

    return mockDb.watchShopQueue(shopId).map((mockTickets) {
      return mockTickets.map((t) {
        return TicketEntity(
          id: t.id,
          shopId: t.shopId,
          customerId: t.customerId,
          customerName: t.customerName,
          tokenNumber: t.tokenNumber,
          status: t.status,
          joinedAt: t.joinedAt,
          calledAt: t.calledAt,
        );
      }).toList();
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
                final data = doc.data();
                final parentShopId = doc.reference.parent.parent?.id ?? '';
                return TicketEntity(
                  id: doc.id,
                  shopId: parentShopId,
                  customerId: data['customerId'] ?? '',
                  customerName: data['customerName'] ?? '',
                  tokenNumber: data['tokenNumber'] ?? 0,
                  status: data['status'] ?? 'waiting',
                  joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  calledAt: (data['calledAt'] as Timestamp?)?.toDate(),
                );
              })
              .where((t) => t.status == 'waiting' || t.status == 'in_service')
              .toList();
        }).handleError((e) {
          debugPrint('Firestore customer active tickets error: $e. Falling back to Mock DB.');
        });
      } catch (e) {
        debugPrint('Firebase stream setup error: $e. Falling back to Mock DB.');
      }
    }

    return mockDb.watchCustomerActiveTickets(customerId).map((mockTickets) {
      return mockTickets.map((t) {
        return TicketEntity(
          id: t.id,
          shopId: t.shopId,
          customerId: t.customerId,
          customerName: t.customerName,
          tokenNumber: t.tokenNumber,
          status: t.status,
          joinedAt: t.joinedAt,
          calledAt: t.calledAt,
        );
      }).toList();
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
              .where('status', whereIn: ['waiting', 'in_service'])
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
          );
        });
      } catch (e) {
        if (e.toString().contains('already have an active ticket')) {
          rethrow;
        }
      }
    }

    final mockTicket = await mockDb.joinQueue(shopId, customerId, customerName);
    return TicketEntity(
      id: mockTicket.id,
      shopId: mockTicket.shopId,
      customerId: mockTicket.customerId,
      customerName: mockTicket.customerName,
      tokenNumber: mockTicket.tokenNumber,
      status: mockTicket.status,
      joinedAt: mockTicket.joinedAt,
      calledAt: mockTicket.calledAt,
    );
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
          if (newStatus == 'in_service') 'calledAt': FieldValue.serverTimestamp(),
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

        // 1. Mark existing 'in_service' ticket as 'completed'
        for (var doc in docs) {
          final data = doc.data();
          if (data['status'] == 'in_service') {
            await doc.reference.update({'status': 'completed'});
          }
        }

        // 2. Find waiting tickets and sort by tokenNumber
        final waitingDocs = docs.where((doc) => doc.data()['status'] == 'waiting').toList();
        waitingDocs.sort((a, b) {
          final numA = (a.data()['tokenNumber'] ?? 0) as int;
          final numB = (b.data()['tokenNumber'] ?? 0) as int;
          return numA.compareTo(numB);
        });

        // 3. Promote first waiting ticket to 'in_service'
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
