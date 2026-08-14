import 'package:equatable/equatable.dart';

class TicketEntity extends Equatable {
  final String id;
  final String shopId;
  final String customerId;
  final String customerName;
  final int tokenNumber;
  final String status; // 'waiting' | 'in_service' | 'completed' | 'skipped' | 'cancelled'
  final DateTime joinedAt;
  final DateTime? calledAt;

  const TicketEntity({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.customerName,
    required this.tokenNumber,
    required this.status,
    required this.joinedAt,
    this.calledAt,
  });

  bool get isWaiting => status == 'waiting';
  bool get isInService => status == 'in_service';
  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';
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
      ];
}
