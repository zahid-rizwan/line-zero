import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmail {
  final AuthRepository repository;
  SignUpWithEmail(this.repository);

  Future<UserEntity> call({
    required String email,
    required String password,
    required String name,
    required String role,
  }) {
    return repository.signUpWithEmail(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  }
}

class SignInWithEmail {
  final AuthRepository repository;
  SignInWithEmail(this.repository);

  Future<UserEntity> call({
    required String email,
    required String password,
  }) {
    return repository.signInWithEmail(
      email: email,
      password: password,
    );
  }
}

class SendOtp {
  final AuthRepository repository;
  SendOtp(this.repository);

  Future<String> call({required String phone}) {
    return repository.sendOtp(phone: phone);
  }
}

class VerifyOtpAndSignIn {
  final AuthRepository repository;
  VerifyOtpAndSignIn(this.repository);

  Future<UserEntity> call({
    required String verificationId,
    required String smsCode,
    required String phone,
    required String name,
    required String role,
  }) {
    return repository.verifyOtpAndSignIn(
      verificationId: verificationId,
      smsCode: smsCode,
      phone: phone,
      name: name,
      role: role,
    );
  }
}

class GetCurrentUser {
  final AuthRepository repository;
  GetCurrentUser(this.repository);

  Future<UserEntity?> call() {
    return repository.getCurrentUser();
  }
}

class SetUserRole {
  final AuthRepository repository;
  SetUserRole(this.repository);

  Future<void> call(String role) {
    return repository.setUserRole(role);
  }
}

class SignOutUser {
  final AuthRepository repository;
  SignOutUser(this.repository);

  Future<void> call() {
    return repository.signOut();
  }
}
