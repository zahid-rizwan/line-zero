import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/subscription_usecases.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetSubscriptionStatus getSubscriptionStatus;
  final SubscribeShop subscribeShop;
  final RestorePurchases restorePurchases;
  final GetPricingConfig getPricingConfig;
  final UpdatePricingConfig updatePricingConfig;

  SubscriptionBloc({
    required this.getSubscriptionStatus,
    required this.subscribeShop,
    required this.restorePurchases,
    required this.getPricingConfig,
    required this.updatePricingConfig,
  }) : super(SubscriptionInitial()) {
    on<SubscriptionFetchRequested>(_onSubscriptionFetchRequested);
    on<SubscribeRequested>(_onSubscribeRequested);
    on<RestorePurchasesRequested>(_onRestorePurchasesRequested);
    on<PricingConfigFetchRequested>(_onPricingConfigFetchRequested);
    on<PricingConfigUpdateRequested>(_onPricingConfigUpdateRequested);
  }

  Future<void> _onSubscriptionFetchRequested(
    SubscriptionFetchRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final subscription = await getSubscriptionStatus(event.shopId);
      final pricingConfig = await getPricingConfig();
      emit(SubscriptionLoaded(
        subscription: subscription,
        pricingConfig: pricingConfig,
      ));
    } catch (e) {
      emit(SubscriptionFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSubscribeRequested(
    SubscribeRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final currentPricing = state is SubscriptionLoaded
        ? (state as SubscriptionLoaded).pricingConfig
        : await getPricingConfig();

    emit(SubscriptionLoading());
    try {
      final subscription = await subscribeShop(
        shopId: event.shopId,
        plan: event.plan,
        purchaseToken: event.purchaseToken,
      );
      emit(SubscriptionLoaded(
        subscription: subscription,
        pricingConfig: currentPricing,
      ));
    } catch (e) {
      emit(SubscriptionFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRestorePurchasesRequested(
    RestorePurchasesRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final currentPricing = state is SubscriptionLoaded
        ? (state as SubscriptionLoaded).pricingConfig
        : await getPricingConfig();

    emit(SubscriptionLoading());
    try {
      final subscription = await restorePurchases(event.shopId);
      emit(SubscriptionLoaded(
        subscription: subscription,
        pricingConfig: currentPricing,
      ));
    } catch (e) {
      emit(SubscriptionFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onPricingConfigFetchRequested(
    PricingConfigFetchRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final config = await getPricingConfig();
      emit(PricingConfigLoaded(config));
    } catch (e) {
      emit(SubscriptionFailure(e.toString()));
    }
  }

  Future<void> _onPricingConfigUpdateRequested(
    PricingConfigUpdateRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      await updatePricingConfig(event.config);
      emit(PricingConfigLoaded(event.config));
    } catch (e) {
      emit(SubscriptionFailure(e.toString()));
    }
  }
}
