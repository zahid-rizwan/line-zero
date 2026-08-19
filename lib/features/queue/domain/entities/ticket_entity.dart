import 'package:equatable/equatable.dart';

class TicketEntity extends Equatable {
  final String id;
  final String shopId;
  final String customerId;
  final String customerName;
  final int tokenNumber;
  final String status; // 'waiting' | 'confirmed' | 'called' | 'held' | 'in_service' | 'pending' | 'completed' | 'no_show' | 'cancelled'
  final DateTime joinedAt;
  final DateTime? calledAt;
  final DateTime? originalEstimatedReadyAt;
  final DateTime? confirmedAt;
  final DateTime? heldUntil;
  final bool extensionUsed;
  final DateTime? movedToPendingAt;
  final String? pendingPriority; // 'high' | 'low' | null
  final bool isWalkIn;

  const TicketEntity({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.customerName,
    required this.tokenNumber,
    required this.status,
    required this.joinedAt,
    this.calledAt,
    this.originalEstimatedReadyAt,
    this.confirmedAt,
    this.heldUntil,
    this.extensionUsed = false,
    this.movedToPendingAt,
    this.pendingPriority,
    this.isWalkIn = false,
  });

  bool get isWaiting => status == 'waiting';
  bool get isConfirmed => status == 'confirmed';
  bool get isCalled => status == 'called';
  bool get isHeld => status == 'held';
  bool get isInService => status == 'in_service';
  bool get isPending => status == 'pending';
  bool get isPendingHigh => status == 'pending' && pendingPriority == 'high';
  bool get isPendingLow => status == 'pending' && pendingPriority == 'low';
  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped' || status == 'no_show';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [
        id,
        shopId,
        customerId,
        customerName,
        tokenNumber,
        status,
        joinedAt,
        calledAt,
        originalEstimatedReadyAt,
        confirmedAt,
        heldUntil,
        extensionUsed,
        movedToPendingAt,
        pendingPriority,
        isWalkIn,
      ];
}
