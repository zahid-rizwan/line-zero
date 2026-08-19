import 'package:flutter_test/flutter_test.dart';
import 'package:queue_token_app/features/queue/domain/entities/ticket_entity.dart';
import 'package:queue_token_app/features/queue/domain/repositories/queue_repository.dart';
import 'package:queue_token_app/features/queue/domain/usecases/queue_usecases.dart';
import 'package:queue_token_app/features/queue/presentation/bloc/queue_bloc.dart';
import 'package:queue_token_app/features/queue/presentation/bloc/queue_event.dart';
import 'package:queue_token_app/features/queue/presentation/bloc/queue_state.dart';

class FakeQueueRepository implements QueueRepository {
  final Stream<List<TicketEntity>> stream;
  FakeQueueRepository(this.stream);

  @override
  Stream<List<TicketEntity>> watchShopQueue(String shopId) => stream;

  @override
  Stream<List<TicketEntity>> watchCustomerActiveTickets(String customerId) => const Stream.empty();

  @override
  Future<TicketEntity> joinQueue({
    required String shopId,
    required String customerId,
    required String customerName,
  }) async {
    return TicketEntity(
      id: 't-new',
      shopId: shopId,
      customerId: customerId,
      customerName: customerName,
      tokenNumber: 5,
      status: 'waiting',
      joinedAt: DateTime.now(),
    );
  }

  @override
  Future<TicketEntity> addWalkInTicket({
    required String shopId,
    String? customerName,
  }) async {
    return TicketEntity(
      id: 't-walkin',
      shopId: shopId,
      customerId: '',
      customerName: customerName ?? 'Walk-in #1',
      tokenNumber: 99,
      status: 'waiting',
      joinedAt: DateTime.now(),
      isWalkIn: true,
    );
  }

  @override
  Future<void> confirmCheckpoint({
    required String shopId,
    required String ticketId,
  }) async {}

  @override
  Future<void> moveToPending({
    required String shopId,
    required String ticketId,
  }) async {}

  @override
  Future<void> readdFromPending({
    required String shopId,
    required String ticketId,
  }) async {}

  @override
  Future<void> updateTicketStatus({
    required String shopId,
    required String ticketId,
    required String newStatus,
  }) async {}

  @override
  Future<void> callNextTicket(String shopId) async {}
}

void main() {
  group('QueueBloc Tests', () {
    test('Calculates customer position and sets isNearTurn true when position <= 2', () async {
      final tickets = [
        TicketEntity(
          id: 't1',
          shopId: 's1',
          customerId: 'c1',
          customerName: 'User 1',
          tokenNumber: 1,
          status: 'in_service',
          joinedAt: DateTime.now(),
        ),
        TicketEntity(
          id: 't2',
          shopId: 's1',
          customerId: 'c2',
          customerName: 'User 2',
          tokenNumber: 2,
          status: 'waiting',
          joinedAt: DateTime.now(),
        ),
        TicketEntity(
          id: 't3',
          shopId: 's1',
          customerId: 'c3',
          customerName: 'User 3',
          tokenNumber: 3,
          status: 'waiting',
          joinedAt: DateTime.now(),
        ),
      ];

      final fakeRepo = FakeQueueRepository(Stream.value(tickets));
      final watchShopQueue = WatchShopQueue(fakeRepo);
      final watchCustomerActiveTickets = WatchCustomerActiveTickets(fakeRepo);
      final joinQueue = JoinQueue(fakeRepo);
      final addWalkInTicket = AddWalkInTicket(fakeRepo);
      final confirmCheckpoint = ConfirmCheckpoint(fakeRepo);
      final moveToPending = MoveToPending(fakeRepo);
      final readdFromPending = ReaddFromPending(fakeRepo);
      final updateTicketStatus = UpdateTicketStatus(fakeRepo);
      final callNextTicket = CallNextTicket(fakeRepo);

      final bloc = QueueBloc(
        watchShopQueue: watchShopQueue,
        watchCustomerActiveTickets: watchCustomerActiveTickets,
        joinQueue: joinQueue,
        addWalkInTicket: addWalkInTicket,
        confirmCheckpoint: confirmCheckpoint,
        moveToPending: moveToPending,
        readdFromPending: readdFromPending,
        updateTicketStatus: updateTicketStatus,
        callNextTicket: callNextTicket,
      );

      bloc.setCurrentCustomerId('c3');

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<QueueLoading>(),
          isA<QueueLoaded>()
              .having((s) => s.currentCustomerPosition, 'position', 1)
              .having((s) => s.isNearTurn, 'isNearTurn', true),
        ]),
      );

      bloc.add(const WatchQueueRequested('s1'));
    });
  });
}
