import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/app_root_router.dart';
import 'features/auth/presentation/screens/phone_auth_screen.dart';
import 'features/queue/data/datasources/queue_remote_data_source.dart';
import 'features/queue/data/repositories/queue_repository_impl.dart';
import 'features/queue/domain/usecases/queue_usecases.dart';
import 'features/queue/presentation/bloc/queue_bloc.dart';
import 'features/shop/data/datasources/shop_remote_data_source.dart';
import 'features/shop/data/repositories/shop_repository_impl.dart';
import 'features/shop/domain/usecases/shop_usecases.dart';
import 'features/shop/presentation/bloc/shop_bloc.dart';

import 'core/services/notification_service.dart';

import 'core/widgets/splash_screen.dart';
import 'core/widgets/app_entry_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestNotificationsPermission();
  runApp(const QTokenApp());
}

class QTokenApp extends StatelessWidget {
  const QTokenApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Data Sources
    final authRemoteDataSource = AuthRemoteDataSourceImpl();
    final shopRemoteDataSource = ShopRemoteDataSourceImpl();
    final queueRemoteDataSource = QueueRemoteDataSourceImpl();

    // Repositories
    final authRepository = AuthRepositoryImpl(authRemoteDataSource);
    final shopRepository = ShopRepositoryImpl(shopRemoteDataSource);
    final queueRepository = QueueRepositoryImpl(queueRemoteDataSource);

    // Use Cases
    final signUpWithEmail = SignUpWithEmail(authRepository);
    final signInWithEmail = SignInWithEmail(authRepository);
    final sendOtp = SendOtp(authRepository);
    final verifyOtpAndSignIn = VerifyOtpAndSignIn(authRepository);
    final getCurrentUser = GetCurrentUser(authRepository);
    final setUserRole = SetUserRole(authRepository);
    final signOutUser = SignOutUser(authRepository);

    final getShops = GetShops(shopRepository);
    final getShopByOwnerId = GetShopByOwnerId(shopRepository);
    final createShop = CreateShop(shopRepository);
    final toggleQueueStatus = ToggleQueueStatus(shopRepository);
    final deleteShop = DeleteShop(shopRepository);

    final watchShopQueue = WatchShopQueue(queueRepository);
    final watchCustomerActiveTickets = WatchCustomerActiveTickets(queueRepository);
    final joinQueue = JoinQueue(queueRepository);
    final updateTicketStatus = UpdateTicketStatus(queueRepository);
    final callNextTicket = CallNextTicket(queueRepository);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            signUpWithEmail: signUpWithEmail,
            signInWithEmail: signInWithEmail,
            sendOtp: sendOtp,
            verifyOtpAndSignIn: verifyOtpAndSignIn,
            getCurrentUser: getCurrentUser,
            setUserRole: setUserRole,
            signOutUser: signOutUser,
          )..add(AuthCheckRequested()),
        ),
        BlocProvider<ShopBloc>(
          create: (_) => ShopBloc(
            getShops: getShops,
            getShopByOwnerId: getShopByOwnerId,
            createShop: createShop,
            toggleQueueStatus: toggleQueueStatus,
            deleteShop: deleteShop,
          ),
        ),
        BlocProvider<QueueBloc>(
          create: (_) => QueueBloc(
            watchShopQueue: watchShopQueue,
            watchCustomerActiveTickets: watchCustomerActiveTickets,
            joinQueue: joinQueue,
            updateTicketStatus: updateTicketStatus,
            callNextTicket: callNextTicket,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'LineZero',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: SplashScreen(
          nextScreen: AppEntryGate(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is Authenticated) {
                  return AppRootRouter(user: state.user);
                }
                return const PhoneAuthScreen();
              },
            ),
          ),
        ),
      ),
    );
  }
}
