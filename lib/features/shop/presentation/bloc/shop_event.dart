import 'package:equatable/equatable.dart';
import '../../domain/entities/shop_entity.dart';

abstract class ShopEvent extends Equatable {
  const ShopEvent();
  @override
  List<Object?> get props => [];
}

class ShopFetchRequested extends ShopEvent {
  final String query;
  const ShopFetchRequested({this.query = ''});

  @override
  List<Object?> get props => [query];
}

class OwnerShopFetchRequested extends ShopEvent {
  final String ownerId;
  const OwnerShopFetchRequested(this.ownerId);

  @override
  List<Object?> get props => [ownerId];
}

class ShopCreateRequested extends ShopEvent {
  final ShopEntity shop;
  const ShopCreateRequested(this.shop);

  @override
  List<Object?> get props => [shop];
}

class ShopToggleQueueRequested extends ShopEvent {
  final String shopId;
  final bool isOpen;

  const ShopToggleQueueRequested({
    required this.shopId,
    required this.isOpen,
  });

  @override
  List<Object?> get props => [shopId, isOpen];
}

class ShopDeleteRequested extends ShopEvent {
  final String shopId;
  const ShopDeleteRequested(this.shopId);

  @override
  List<Object?> get props => [shopId];
}
