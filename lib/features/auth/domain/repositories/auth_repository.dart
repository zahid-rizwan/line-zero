import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  });

  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  Future<String> sendOtp({required String phone});

  Future<UserEntity> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
    required String phone,
    required String name,
    required String role,
  });

  Future<UserEntity?> getCurrentUser();

  Future<void> setUserRole(String role);

  Future<void> signOut();
}
