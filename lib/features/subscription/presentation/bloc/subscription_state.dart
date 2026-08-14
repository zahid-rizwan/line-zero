import '../../domain/entities/subscription_entity.dart';

abstract class SubscriptionState {}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final SubscriptionEntity subscription;
  SubscriptionLoaded(this.subscription);
}

class SubscriptionFailure extends SubscriptionState {
  final String message;
  SubscriptionFailure(this.message);
}
