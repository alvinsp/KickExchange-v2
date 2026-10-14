import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/products/presentation/bloc/product_bloc.dart';
import 'features/products/presentation/bloc/product_event.dart';
import 'features/sync/presentation/bloc/sync_bloc.dart';
import 'features/sync/presentation/bloc/sync_event.dart';
import 'features/trade/presentation/bloc/trade_bloc.dart';
import 'features/trade/presentation/bloc/trade_event.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';
import 'features/transactions/presentation/bloc/transaction_event.dart';
import 'injection_container.dart';
import 'main_navigation_shell.dart';

class KickExchangeApp extends StatelessWidget {
  const KickExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(CheckAuthSessionEvent()),
        ),
        BlocProvider<ProductBloc>(
          create: (_) => sl<ProductBloc>()..add(const LoadProductsEvent()),
        ),
        BlocProvider<TradeBloc>(
          create: (_) => sl<TradeBloc>()..add(const LoadTradesEvent()),
        ),
        BlocProvider<TransactionBloc>(
          create: (_) => sl<TransactionBloc>()..add(LoadTransactionsEvent()),
        ),
        BlocProvider<SyncBloc>(
          create: (_) => sl<SyncBloc>()..add(CheckPendingSyncCountEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'KickExchange v2',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppRootNavigator(),
      ),
    );
  }
}

class AppRootNavigator extends StatefulWidget {
  const AppRootNavigator({super.key});

  @override
  State<AppRootNavigator> createState() => _AppRootNavigatorState();
}

class _AppRootNavigatorState extends State<AppRootNavigator> {
  bool _fallbackToLogin = false;

  @override
  void initState() {
    super.initState();
    // Maximum 2.5s splash screen timeout: guarantees user is never stuck loading
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && !_fallbackToLogin) {
        setState(() => _fallbackToLogin = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const MainNavigationShell();
        }

        if (state is Unauthenticated || state is AuthFailureState || _fallbackToLogin) {
          return const LoginPage();
        }

        // Splash / Initial Loading Screen
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '👟 KICK EXCHANGE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: AppColors.neonVolt,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Next-Gen Sneaker Marketplace: Buy, Sell, Trade',
                  style: TextStyle(color: AppColors.textGreySecondary, fontSize: 13),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: AppColors.neonVolt),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    setState(() => _fallbackToLogin = true);
                  },
                  child: const Text(
                    'Lewati ke Halaman Masuk ➔',
                    style: TextStyle(color: AppColors.textGreySecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
