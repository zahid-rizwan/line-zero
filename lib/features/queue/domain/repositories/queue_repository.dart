import '../entities/ticket_entity.dart';

abstract class QueueRepository {
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
