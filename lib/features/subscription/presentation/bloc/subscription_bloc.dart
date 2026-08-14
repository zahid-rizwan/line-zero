import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/subscription_usecases.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetSubscriptionStatus getSubscriptionStatus;
  final SubscribeShop subscribeShop;
  final RestorePurchases restorePurchases;

  SubscriptionBloc({
    required this.getSubscriptionStatus,
    required this.subscribeShop,
    required this.restorePurchases,
  }) : super(SubscriptionInitial()) {
    on<SubscriptionFetchRequested>(_onSubscriptionFetchRequested);
    on<SubscribeRequested>(_onSubscribeRequested);
    on<RestorePurchasesRequested>(_onRestorePurchasesRequested);
  }

  Future<void> _onSubscriptionFetchRequested(
    SubscriptionFetchRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final subscription = await getSubscriptionStatus(event.shopId);
      emit(SubscriptionLoaded(subscription));
    } catch (e) {
      emit(SubscriptionFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSubscribeRequested(
    SubscribeRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final subscription = await subscribeShop(
        shopId: event.shopId,
        plan: event.plan,
        purchaseToken: event.purchaseToken,
      );
      emit(SubscriptionLoaded(subscription));
    } catch (e) {
      emit(SubscriptionFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRestorePurchasesRequested(
    RestorePurchasesRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final subscription = await restorePurchases(event.shopId);
      emit(SubscriptionLoaded(subscription));
    } catch (e) {
      emit(SubscriptionFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
