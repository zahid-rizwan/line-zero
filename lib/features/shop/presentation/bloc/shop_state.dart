import 'package:equatable/equatable.dart';
import '../../domain/entities/shop_entity.dart';

abstract class ShopState extends Equatable {
  const ShopState();
  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {}

class ShopLoading extends ShopState {}

class ShopsLoaded extends ShopState {
  final List<ShopEntity> shops;
  const ShopsLoaded(this.shops);

  @override
  List<Object?> get props => [shops];
}

class OwnerShopLoaded extends ShopState {
  final ShopEntity? shop;
  const OwnerShopLoaded(this.shop);

  @override
  List<Object?> get props => [shop];
}

class ShopOperationSuccess extends ShopState {
  final String message;
  const ShopOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ShopError extends ShopState {
  final String message;
  const ShopError(this.message);

  @override
  List<Object?> get props => [message];
}
