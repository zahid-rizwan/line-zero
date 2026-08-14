import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignUpWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String role;

  const AuthSignUpWithEmailRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, name, role];
}

class AuthSignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInWithEmailRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthSendOtpRequested extends AuthEvent {
  final String phone;
  const AuthSendOtpRequested(this.phone);

  @override
  List<Object?> get props => [phone];
}

class AuthVerifyOtpRequested extends AuthEvent {
  final String verificationId;
  final String smsCode;
  final String phone;
  final String name;
  final String role;

  const AuthVerifyOtpRequested({
    required this.verificationId,
    required this.smsCode,
    required this.phone,
    required this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [verificationId, smsCode, phone, name, role];
}

class AuthRoleUpdated extends AuthEvent {
  final String role;
  const AuthRoleUpdated(this.role);

  @override
  List<Object?> get props => [role];
}

class AuthSignOutRequested extends AuthEvent {}
