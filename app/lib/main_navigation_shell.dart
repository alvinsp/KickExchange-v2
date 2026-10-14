import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/presentation/pages/profile_page.dart';
import 'features/products/presentation/pages/product_catalog_page.dart';
import 'features/sync/presentation/bloc/sync_bloc.dart';
import 'features/sync/presentation/bloc/sync_state.dart';
import 'features/trade/presentation/pages/trade_offers_page.dart';
import 'features/transactions/presentation/pages/order_history_page.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ProductCatalogPage(),
    TradeOffersPage(),
    OrderHistoryPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, syncState) {
          final pendingCount = syncState.pendingCount;

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.storefront_outlined),
                activeIcon: Icon(Icons.storefront),
                label: 'Katalog',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.swap_horiz_outlined),
                activeIcon: Icon(Icons.swap_horiz),
                label: 'Barter',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Transaksi',
              ),
              BottomNavigationBarItem(
                icon: pendingCount > 0
                    ? Badge(
                        label: Text('$pendingCount'),
                        backgroundColor: AppColors.stateOffline,
                        child: const Icon(Icons.person_outline),
                      )
                    : const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }
}
