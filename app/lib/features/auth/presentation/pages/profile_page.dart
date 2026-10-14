import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/security/data_masking.dart';
import '../../../products/presentation/bloc/product_bloc.dart';
import '../../../products/presentation/bloc/product_event.dart';
import '../../../products/presentation/pages/add_edit_product_page.dart';
import '../../../sync/presentation/bloc/sync_bloc.dart';
import '../../../sync/presentation/bloc/sync_event.dart';
import '../../../sync/presentation/bloc/sync_state.dart';
import '../../../transactions/presentation/pages/order_history_page.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFIL SNEAKERHEAD 👤'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is Authenticated ? state.user : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Info Card
                _buildUserCard(user),
                const SizedBox(height: AppDimens.space20),

                // Offline Sync Center
                _buildSyncCenter(context),
                const SizedBox(height: AppDimens.space20),

                // Quick Menu
                _buildQuickMenu(context),
                const SizedBox(height: AppDimens.space24),

                // Security & Encryption Info Box
                _buildSecurityBox(),
                const SizedBox(height: AppDimens.space32),

                // Logout Button
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: AppColors.stateDanger),
                  label: const Text('KELUAR DARI AKUN', style: TextStyle(color: AppColors.stateDanger, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.stateDanger),
                  ),
                  onPressed: () {
                    _confirmLogout(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(UserEntity? user) {
    final name = user?.name ?? 'Sneaker Enthusiast';
    final email = DataMasking.maskEmail(user?.email);
    final phone = DataMasking.maskPhone(user?.phone);

    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.neonVolt.withOpacity(0.15),
            child: const Text('👟', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: AppDimens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 13),
                ),
                if (phone != '-') ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.neonVolt.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VERIFIED SNEAKERHEAD',
                    style: TextStyle(color: AppColors.neonVolt, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCenter(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final pending = state.pendingCount;
        final isSyncing = state is SyncInProgress;

        return Container(
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCardDark,
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            border: Border.all(
              color: pending > 0 ? AppColors.stateOffline : AppColors.borderGrey,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sync_outlined, color: AppColors.neonVolt),
                      SizedBox(width: 8),
                      Text('Offline Sync Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pending > 0 ? AppColors.stateOffline : AppColors.stateSuccess.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pending > 0 ? '$pending antrean offline' : 'Semua tersinkron',
                      style: TextStyle(
                        color: pending > 0 ? Colors.white : AppColors.stateSuccess,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space12),
              const Text(
                'Mutasi data saat offline (listing sepatu baru, barter, transaksi) disimpan terenkripsi di SQLite lokal dan disinkronisasi otomatis.',
                style: TextStyle(fontSize: 12, color: AppColors.textGreySecondary, height: 1.4),
              ),
              const SizedBox(height: AppDimens.space12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.elevatedCardDark,
                  foregroundColor: AppColors.textWhitePrimary,
                ),
                icon: isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonVolt),
                      )
                    : const Icon(Icons.cloud_upload_outlined, color: AppColors.neonVolt, size: 18),
                label: Text(isSyncing ? 'Menyinkronkan antrean...' : 'Sinkronkan Sekarang'),
                onPressed: isSyncing
                    ? null
                    : () {
                        context.read<SyncBloc>().add(TriggerSyncEvent());
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickMenu(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.add_circle_outline,
          title: 'Pasang Listing Sepatu Baru',
          subtitle: 'Jual atau tukar sepatu Anda (Offline-First)',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditProductPage()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.inventory_2_outlined,
          title: 'Sepatu Saya (My Listings)',
          subtitle: 'Kelola sepatu yang Anda tawarkan',
          onTap: () {
            context.read<ProductBloc>().add(const LoadProductsEvent(onlyMine: true));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.neonVolt,
                content: Text('Filter sepatu milik saya diaktifkan di tab Katalog.', style: TextStyle(color: Colors.black)),
              ),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.receipt_long_outlined,
          title: 'Riwayat Transaksi',
          subtitle: 'Struk pembelian & pembayaran selisih barter',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.space8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.elevatedCardDark,
          child: Icon(icon, color: AppColors.neonVolt, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textGreySecondary),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSecurityBox() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: AppColors.inputFillDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_clock_outlined, color: AppColors.electricCyan, size: 20),
          SizedBox(width: AppDimens.space12),
          Expanded(
            child: Text(
              'Keamanan Data: Sesuai UU PDP Indonesia. Penyimpanan lokal dienkripsi AES-256 dan token disimpan di Keystore/Keychain.',
              style: TextStyle(fontSize: 11, color: AppColors.textGreySecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCardDark,
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.stateDanger),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthBloc>().add(LogoutRequestedEvent());
              },
              child: const Text('Keluar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
