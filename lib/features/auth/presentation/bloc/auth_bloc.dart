import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_token_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:queue_token_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:queue_token_app/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUpWithEmail signUpWithEmail;
  final SignInWithEmail signInWithEmail;
  final SendOtp sendOtp;
  final VerifyOtpAndSignIn verifyOtpAndSignIn;
  final GetCurrentUser getCurrentUser;
  final SetUserRole setUserRole;
  final SignOutUser signOutUser;

  AuthBloc({
    required this.signUpWithEmail,
    required this.signInWithEmail,
    required this.sendOtp,
    required this.verifyOtpAndSignIn,
    required this.getCurrentUser,
    required this.setUserRole,
    required this.signOutUser,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpWithEmailRequested>(_onAuthSignUpWithEmailRequested);
    on<AuthSignInWithEmailRequested>(_onAuthSignInWithEmailRequested);
    on<AuthSendOtpRequested>(_onAuthSendOtpRequested);
    on<AuthVerifyOtpRequested>(_onAuthVerifyOtpRequested);
    on<AuthRoleUpdated>(_onAuthRoleUpdated);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthSignUpWithEmailRequested(
    AuthSignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await signUpWithEmail(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailureState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAuthSignInWithEmailRequested(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await signInWithEmail(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailureState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAuthSendOtpRequested(
    AuthSendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final verificationId = await sendOtp(phone: event.phone);
      emit(AuthOtpSentState(verificationId: verificationId, phone: event.phone));
    } catch (e) {
      emit(AuthFailureState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAuthVerifyOtpRequested(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await verifyOtpAndSignIn(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
        phone: event.phone,
        name: event.name,
        role: event.role,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailureState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAuthRoleUpdated(
    AuthRoleUpdated event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is Authenticated) {
      try {
        await setUserRole(event.role);
        final updatedUser = await getCurrentUser();
        if (updatedUser != null) {
          emit(Authenticated(updatedUser));
        }
      } catch (e) {
        emit(AuthFailureState(e.toString()));
      }
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await signOutUser();
    emit(Unauthenticated());
  }
}
