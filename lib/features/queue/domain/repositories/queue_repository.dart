import '../entities/ticket_entity.dart';

abstract class QueueRepository {
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
