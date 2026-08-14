import '../datasources/queue_remote_data_source.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/queue_repository.dart';

class QueueRepositoryImpl implements QueueRepository {
  final QueueRemoteDataSource remoteDataSource;

  QueueRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<TicketEntity>> watchShopQueue(String shopId) {
    return remoteDataSource.watchShopQueue(shopId);
  }

  @override
  Stream<List<TicketEntity>> watchCustomerActiveTickets(String customerId) {
    return remoteDataSource.watchCustomerActiveTickets(customerId);
  }

  @override
  Future<TicketEntity> joinQueue({
    required String shopId,
    required String customerId,
    required String customerName,
  }) {
    return remoteDataSource.joinQueue(
      shopId: shopId,
      customerId: customerId,
      customerName: customerName,
    );
  }

  @override
  Future<void> updateTicketStatus({
    required String shopId,
    required String ticketId,
    required String newStatus,
  }) {
    return remoteDataSource.updateTicketStatus(
      shopId: shopId,
      ticketId: ticketId,
      newStatus: newStatus,
    );
  }

  @override
  Future<void> callNextTicket(String shopId) {
    return remoteDataSource.callNextTicket(shopId);
  }
}
