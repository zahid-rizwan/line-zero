import 'package:equatable/equatable.dart';
import '../../domain/entities/ticket_entity.dart';

abstract class QueueState extends Equatable {
  const QueueState();
  @override
  List<Object?> get props => [];
}

class QueueInitial extends QueueState {}

class QueueLoading extends QueueState {}

class QueueLoaded extends QueueState {
  final List<TicketEntity> tickets;
  final TicketEntity? currentCustomerTicket;
  final int? currentCustomerPosition;
  final bool isNearTurn; // position <= 2 alert state
  final Map<String, TicketEntity> activeCustomerTicketsByShopId; // shopId -> active ticket

  const QueueLoaded({
    required this.tickets,
    this.currentCustomerTicket,
    this.currentCustomerPosition,
    this.isNearTurn = false,
    this.activeCustomerTicketsByShopId = const {},
  });

  QueueLoaded copyWith({
    List<TicketEntity>? tickets,
    TicketEntity? currentCustomerTicket,
    int? currentCustomerPosition,
    bool? isNearTurn,
    Map<String, TicketEntity>? activeCustomerTicketsByShopId,
  }) {
    return QueueLoaded(
      tickets: tickets ?? this.tickets,
      currentCustomerTicket: currentCustomerTicket ?? this.currentCustomerTicket,
      currentCustomerPosition: currentCustomerPosition ?? this.currentCustomerPosition,
      isNearTurn: isNearTurn ?? this.isNearTurn,
      activeCustomerTicketsByShopId: activeCustomerTicketsByShopId ?? this.activeCustomerTicketsByShopId,
    );
  }

  @override
  List<Object?> get props => [
        tickets,
        currentCustomerTicket,
        currentCustomerPosition,
        isNearTurn,
        activeCustomerTicketsByShopId,
      ];
}

class QueueError extends QueueState {
  final String message;
  const QueueError(this.message);

  @override
  List<Object?> get props => [message];
}
