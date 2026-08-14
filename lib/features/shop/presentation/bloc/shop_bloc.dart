import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/shop_usecases.dart';
import 'shop_event.dart';
import 'shop_state.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final GetShops getShops;
  final GetShopByOwnerId getShopByOwnerId;
  final CreateShop createShop;
  final ToggleQueueStatus toggleQueueStatus;
  final DeleteShop deleteShop;

  ShopBloc({
    required this.getShops,
    required this.getShopByOwnerId,
    required this.createShop,
    required this.toggleQueueStatus,
    required this.deleteShop,
  }) : super(ShopInitial()) {
    on<ShopFetchRequested>(_onShopFetchRequested);
    on<OwnerShopFetchRequested>(_onOwnerShopFetchRequested);
    on<ShopCreateRequested>(_onShopCreateRequested);
    on<ShopToggleQueueRequested>(_onShopToggleQueueRequested);
    on<ShopDeleteRequested>(_onShopDeleteRequested);
  }

  Future<void> _onShopFetchRequested(
    ShopFetchRequested event,
    Emitter<ShopState> emit,
  ) async {
    emit(ShopLoading());
    try {
      final shops = await getShops(query: event.query);
      emit(ShopsLoaded(shops));
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }

  Future<void> _onOwnerShopFetchRequested(
    OwnerShopFetchRequested event,
    Emitter<ShopState> emit,
  ) async {
    emit(ShopLoading());
    try {
      final shop = await getShopByOwnerId(event.ownerId);
      emit(OwnerShopLoaded(shop));
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }

  Future<void> _onShopCreateRequested(
    ShopCreateRequested event,
    Emitter<ShopState> emit,
  ) async {
    emit(ShopLoading());
    try {
      await createShop(event.shop);
      final updatedShops = await getShops();
      emit(ShopsLoaded(updatedShops));
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }

  Future<void> _onShopToggleQueueRequested(
    ShopToggleQueueRequested event,
    Emitter<ShopState> emit,
  ) async {
    try {
      await toggleQueueStatus(shopId: event.shopId, isOpen: event.isOpen);
      final currentState = state;
      if (currentState is OwnerShopLoaded && currentState.shop != null) {
        emit(OwnerShopLoaded(currentState.shop!.copyWith(isQueueOpen: event.isOpen)));
      } else {
        final updatedShops = await getShops();
        emit(ShopsLoaded(updatedShops));
      }
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }

  Future<void> _onShopDeleteRequested(
    ShopDeleteRequested event,
    Emitter<ShopState> emit,
  ) async {
    try {
      await deleteShop(event.shopId);
      final updatedShops = await getShops();
      emit(ShopsLoaded(updatedShops));
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }
}
