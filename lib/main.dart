import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'service_locator.dart' as di;

import 'core/theme/app_theme.dart';
import 'core/presentation/widgets/admin_shell.dart';

import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/subscription/presentation/bloc/subscription_bloc.dart';
import 'features/deposit/presentation/bloc/deposit_bloc.dart';
import 'features/withdrawal/presentation/bloc/withdrawal_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/users/presentation/bloc/user_management_bloc.dart';
import 'features/smm_orders/presentation/bloc/smm_order_bloc.dart';
import 'features/smm_notices/presentation/bloc/smm_notice_bloc.dart';
import 'features/ads_views/presentation/bloc/ads_view_bloc.dart';
import 'features/app_limits/presentation/bloc/app_limits_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(CheckAuthRequested()),
        ),
        BlocProvider(create: (_) => di.sl<SubscriptionBloc>()),
        BlocProvider(create: (_) => di.sl<DepositBloc>()),
        BlocProvider(create: (_) => di.sl<WithdrawalBloc>()),
        BlocProvider(create: (_) => di.sl<DashboardBloc>()),
        BlocProvider(create: (_) => di.sl<UserManagementBloc>()),
        BlocProvider(create: (_) => di.sl<SmmOrderBloc>()),
        BlocProvider(create: (_) => di.sl<SmmNoticeBloc>()),
        BlocProvider(create: (_) => di.sl<AdsViewBloc>()),
        BlocProvider(create: (_) => di.sl<AppLimitsBloc>()),
      ],
      child: MaterialApp(
        title: 'Golden Power Admin panel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        } else if (state is AuthActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        } else if (state is AuthAuthenticated) {
          return const AdminShell();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
