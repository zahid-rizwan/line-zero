import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/usecases/queue_usecases.dart';
import 'queue_event.dart';
import 'queue_state.dart';

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final WatchShopQueue watchShopQueue;
  final WatchCustomerActiveTickets watchCustomerActiveTickets;
  final JoinQueue joinQueue;
  final AddWalkInTicket addWalkInTicket;
  final ConfirmCheckpoint confirmCheckpoint;
  final MoveToPending moveToPending;
  final ReaddFromPending readdFromPending;
  final UpdateTicketStatus updateTicketStatus;
  final CallNextTicket callNextTicket;

  StreamSubscription<List<TicketEntity>>? _queueSubscription;
  StreamSubscription<List<TicketEntity>>? _customerActiveTicketsSubscription;
  String? _currentCustomerId;
  Map<String, TicketEntity> _activeCustomerTicketsByShopId = {};

  QueueBloc({
    required this.watchShopQueue,
    required this.watchCustomerActiveTickets,
    required this.joinQueue,
    required this.addWalkInTicket,
    required this.confirmCheckpoint,
    required this.moveToPending,
    required this.readdFromPending,
    required this.updateTicketStatus,
    required this.callNextTicket,
  }) : super(QueueInitial()) {
    on<ResetQueueState>(_onResetQueueState);
    on<WatchQueueRequested>(_onWatchQueueRequested);
    on<WatchCustomerActiveTicketsRequested>(_onWatchCustomerActiveTicketsRequested);
    on<CustomerActiveTicketsUpdated>(_onCustomerActiveTicketsUpdated);
    on<QueueUpdatedEvent>(_onQueueUpdatedEvent);
    on<JoinQueueRequested>(_onJoinQueueRequested);
    on<AddWalkInRequested>(_onAddWalkInRequested);
    on<ConfirmCheckpointRequested>(_onConfirmCheckpointRequested);
    on<MoveToPendingRequested>(_onMoveToPendingRequested);
    on<ReaddFromPendingRequested>(_onReaddFromPendingRequested);
    on<UpdateStatusRequested>(_onUpdateStatusRequested);
    on<CallNextRequested>(_onCallNextRequested);
  }

  void setCurrentCustomerId(String customerId) {
    _currentCustomerId = customerId;
  }

  void _onResetQueueState(
    ResetQueueState event,
    Emitter<QueueState> emit,
  ) {
    _currentCustomerId = null;
    _activeCustomerTicketsByShopId = {};
    _queueSubscription?.cancel();
    _customerActiveTicketsSubscription?.cancel();
    emit(QueueInitial());
  }

  Future<void> _onWatchQueueRequested(
    WatchQueueRequested event,
    Emitter<QueueState> emit,
  ) async {
    emit(QueueLoading());
    await _queueSubscription?.cancel();
    _queueSubscription = watchShopQueue(event.shopId).listen((tickets) {
      add(QueueUpdatedEvent(tickets));
    }, onError: (error) {
      emit(QueueError(error.toString()));
    });
  }

  Future<void> _onWatchCustomerActiveTicketsRequested(
    WatchCustomerActiveTicketsRequested event,
    Emitter<QueueState> emit,
  ) async {
    _currentCustomerId = event.customerId;
    await _customerActiveTicketsSubscription?.cancel();
    _customerActiveTicketsSubscription = watchCustomerActiveTickets(event.customerId).listen((tickets) {
      add(CustomerActiveTicketsUpdated(tickets));
    }, onError: (error) {
      // Non-fatal background stream error
    });
  }

  void _onCustomerActiveTicketsUpdated(
    CustomerActiveTicketsUpdated event,
    Emitter<QueueState> emit,
  ) {
    final Map<String, TicketEntity> map = {};
    for (var ticket in event.activeTickets) {
      if (!ticket.isCompleted && !ticket.isCancelled && !ticket.isSkipped) {
        map[ticket.shopId] = ticket;
      }
    }
    _activeCustomerTicketsByShopId = map;

    if (state is QueueLoaded) {
      final current = state as QueueLoaded;
      emit(current.copyWith(activeCustomerTicketsByShopId: Map.from(_activeCustomerTicketsByShopId)));
    } else {
      emit(QueueLoaded(
        tickets: const [],
        activeCustomerTicketsByShopId: Map.from(_activeCustomerTicketsByShopId),
      ));
    }
  }

  void _onQueueUpdatedEvent(
    QueueUpdatedEvent event,
    Emitter<QueueState> emit,
  ) {
    TicketEntity? customerTicket;
    int? position;
    bool isNearTurn = false;

    if (_currentCustomerId != null) {
      try {
        customerTicket = event.tickets.firstWhere(
          (t) => t.customerId == _currentCustomerId && !t.isCompleted && !t.isCancelled && !t.isSkipped,
        );
      } catch (_) {
        customerTicket = null;
      }

      if (customerTicket != null) {
        if (customerTicket.isInService) {
          position = 0;
          isNearTurn = true;
        } else if (customerTicket.isWaiting) {
          final waitingTickets = event.tickets.where((t) => t.isWaiting).toList();
          final index = waitingTickets.indexWhere((t) => t.id == customerTicket!.id);
          if (index != -1) {
            position = index; // 0 means next up, 1 means 1 person ahead
            isNearTurn = position <= 2;
          }
        }
      }
    }

    if (event.tickets.isNotEmpty) {
      final shopId = event.tickets.first.shopId;
      if (customerTicket != null) {
        _activeCustomerTicketsByShopId[shopId] = customerTicket;
      } else {
        _activeCustomerTicketsByShopId.remove(shopId);
      }
    }

    emit(QueueLoaded(
      tickets: event.tickets,
      currentCustomerTicket: customerTicket,
      currentCustomerPosition: position,
      isNearTurn: isNearTurn,
      activeCustomerTicketsByShopId: Map.from(_activeCustomerTicketsByShopId),
    ));
  }

  Future<void> _onJoinQueueRequested(
    JoinQueueRequested event,
    Emitter<QueueState> emit,
  ) async {
    _currentCustomerId = event.customerId;
    emit(QueueLoading());
    try {
      final ticket = await joinQueue(
        shopId: event.shopId,
        customerId: event.customerId,
        customerName: event.customerName,
      );
      _activeCustomerTicketsByShopId[event.shopId] = ticket;
    } catch (e) {
      emit(QueueError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddWalkInRequested(
    AddWalkInRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      await addWalkInTicket(
        shopId: event.shopId,
        customerName: event.customerName,
      );
    } catch (e) {
      emit(QueueError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onConfirmCheckpointRequested(
    ConfirmCheckpointRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      await confirmCheckpoint(
        shopId: event.shopId,
        ticketId: event.ticketId,
      );
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }

  Future<void> _onMoveToPendingRequested(
    MoveToPendingRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      await moveToPending(
        shopId: event.shopId,
        ticketId: event.ticketId,
      );
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }

  Future<void> _onReaddFromPendingRequested(
    ReaddFromPendingRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      await readdFromPending(
        shopId: event.shopId,
        ticketId: event.ticketId,
      );
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }

  Future<void> _onUpdateStatusRequested(
    UpdateStatusRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      await updateTicketStatus(
        shopId: event.shopId,
        ticketId: event.ticketId,
        newStatus: event.newStatus,
      );
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }

  Future<void> _onCallNextRequested(
    CallNextRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      await callNextTicket(event.shopId);
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _queueSubscription?.cancel();
    _customerActiveTicketsSubscription?.cancel();
    return super.close();
  }
}
