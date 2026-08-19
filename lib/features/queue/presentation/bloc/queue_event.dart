import 'package:equatable/equatable.dart';
import '../../domain/entities/ticket_entity.dart';

abstract class QueueEvent extends Equatable {
  const QueueEvent();
  @override
  List<Object?> get props => [];
}

class ResetQueueState extends QueueEvent {}

class WatchQueueRequested extends QueueEvent {
  final String shopId;
  const WatchQueueRequested(this.shopId);

  @override
  List<Object?> get props => [shopId];
}

class WatchCustomerActiveTicketsRequested extends QueueEvent {
  final String customerId;
  const WatchCustomerActiveTicketsRequested(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class CustomerActiveTicketsUpdated extends QueueEvent {
  final List<TicketEntity> activeTickets;
  const CustomerActiveTicketsUpdated(this.activeTickets);

  @override
  List<Object?> get props => [activeTickets];
}

class QueueUpdatedEvent extends QueueEvent {
  final List<TicketEntity> tickets;
  const QueueUpdatedEvent(this.tickets);

  @override
  List<Object?> get props => [tickets];
}

class JoinQueueRequested extends QueueEvent {
  final String shopId;
  final String customerId;
  final String customerName;

  const JoinQueueRequested({
    required this.shopId,
    required this.customerId,
    required this.customerName,
  });

  @override
  List<Object?> get props => [shopId, customerId, customerName];
}

class UpdateStatusRequested extends QueueEvent {
  final String shopId;
  final String ticketId;
  final String newStatus;

  const UpdateStatusRequested({
    required this.shopId,
    required this.ticketId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [shopId, ticketId, newStatus];
}

class CallNextRequested extends QueueEvent {
  final String shopId;
  const CallNextRequested(this.shopId);

  @override
  List<Object?> get props => [shopId];
}

class AddWalkInRequested extends QueueEvent {
  final String shopId;
  final String? customerName;

  const AddWalkInRequested({
    required this.shopId,
    this.customerName,
  });

  @override
  List<Object?> get props => [shopId, customerName];
}

class ConfirmCheckpointRequested extends QueueEvent {
  final String shopId;
  final String ticketId;

  const ConfirmCheckpointRequested({
    required this.shopId,
    required this.ticketId,
  });

  @override
  List<Object?> get props => [shopId, ticketId];
}

class MoveToPendingRequested extends QueueEvent {
  final String shopId;
  final String ticketId;

  const MoveToPendingRequested({
    required this.shopId,
    required this.ticketId,
  });

  @override
  List<Object?> get props => [shopId, ticketId];
}

class ReaddFromPendingRequested extends QueueEvent {
  final String shopId;
  final String ticketId;

  const ReaddFromPendingRequested({
    required this.shopId,
    required this.ticketId,
  });

  @override
  List<Object?> get props => [shopId, ticketId];
}
