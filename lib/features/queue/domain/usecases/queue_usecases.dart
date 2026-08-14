import '../entities/ticket_entity.dart';
import '../repositories/queue_repository.dart';

class WatchShopQueue {
  final QueueRepository repository;
  WatchShopQueue(this.repository);

  Stream<List<TicketEntity>> call(String shopId) {
    return repository.watchShopQueue(shopId);
  }
}

class WatchCustomerActiveTickets {
  final QueueRepository repository;
  WatchCustomerActiveTickets(this.repository);

  Stream<List<TicketEntity>> call(String customerId) {
    return repository.watchCustomerActiveTickets(customerId);
  }
}

class JoinQueue {
  final QueueRepository repository;
  JoinQueue(this.repository);

  Future<TicketEntity> call({
    required String shopId,
    required String customerId,
    required String customerName,
  }) {
    return repository.joinQueue(
      shopId: shopId,
      customerId: customerId,
      customerName: customerName,
    );
  }
}

class UpdateTicketStatus {
  final QueueRepository repository;
  UpdateTicketStatus(this.repository);

  Future<void> call({
    required String shopId,
    required String ticketId,
    required String newStatus,
  }) {
    return repository.updateTicketStatus(
      shopId: shopId,
      ticketId: ticketId,
      newStatus: newStatus,
    );
  }
}

class CallNextTicket {
  final QueueRepository repository;
  CallNextTicket(this.repository);

  Future<void> call(String shopId) {
    return repository.callNextTicket(shopId);
  }
}
