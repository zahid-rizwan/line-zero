import 'package:queue_token_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:queue_token_app/features/auth/domain/entities/user_entity.dart';
import 'package:queue_token_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  }) {
    return remoteDataSource.signUpWithEmail(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) {
    return remoteDataSource.signInWithEmail(
      email: email,
      password: password,
    );
  }

  @override
  Future<String> sendOtp({required String phone}) {
    return remoteDataSource.sendOtp(phone: phone);
  }

  @override
  Future<UserEntity> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
    required String phone,
    required String name,
    required String role,
  }) {
    return remoteDataSource.verifyOtpAndSignIn(
      verificationId: verificationId,
      smsCode: smsCode,
      phone: phone,
      name: name,
      role: role,
    );
  }

  @override
  Future<UserEntity?> getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Future<void> setUserRole(String role) {
    return remoteDataSource.setUserRole(role);
  }

  @override
  Future<void> signOut() {
    return remoteDataSource.signOut();
  }
}
