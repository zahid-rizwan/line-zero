import 'package:equatable/equatable.dart';
import 'package:queue_token_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSentState extends AuthState {
  final String verificationId;
  final String phone;

  const AuthOtpSentState({
    required this.verificationId,
    required this.phone,
  });

  @override
  List<Object?> get props => [verificationId, phone];
}

class Authenticated extends AuthState {
  final UserEntity user;
  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthFailureState extends AuthState {
  final String message;
  const AuthFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
