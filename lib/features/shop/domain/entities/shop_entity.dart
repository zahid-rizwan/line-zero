import 'package:equatable/equatable.dart';

class ShopEntity extends Equatable {
  final String id;
  final String name;
  final String category;
  final String ownerId;
  final String address;
  final bool isQueueOpen;
  final int avgServiceTimeMinutes;

  const ShopEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.ownerId,
    required this.address,
    required this.isQueueOpen,
    required this.avgServiceTimeMinutes,
  });

  ShopEntity copyWith({
    bool? isQueueOpen,
    String? name,
    String? category,
    String? address,
    int? avgServiceTimeMinutes,
  }) {
    return ShopEntity(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      ownerId: ownerId,
      address: address ?? this.address,
      isQueueOpen: isQueueOpen ?? this.isQueueOpen,
      avgServiceTimeMinutes: avgServiceTimeMinutes ?? this.avgServiceTimeMinutes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        ownerId,
        address,
        isQueueOpen,
        avgServiceTimeMinutes,
      ];
}
