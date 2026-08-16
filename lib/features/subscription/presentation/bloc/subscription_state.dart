import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/pricing_config_entity.dart';

abstract class SubscriptionState {}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final SubscriptionEntity subscription;
  final PricingConfigEntity pricingConfig;

  SubscriptionLoaded({
    required this.subscription,
    required this.pricingConfig,
  });

  SubscriptionLoaded copyWith({
    SubscriptionEntity? subscription,
    PricingConfigEntity? pricingConfig,
  }) {
    return SubscriptionLoaded(
      subscription: subscription ?? this.subscription,
      pricingConfig: pricingConfig ?? this.pricingConfig,
    );
  }
}

class PricingConfigLoaded extends SubscriptionState {
  final PricingConfigEntity config;
  PricingConfigLoaded(this.config);
}

class SubscriptionFailure extends SubscriptionState {
  final String message;
  SubscriptionFailure(this.message);
}
