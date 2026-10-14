import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../sync/presentation/widgets/sync_status_banner.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../widgets/product_card.dart';
import 'add_edit_product_page.dart';
import 'product_detail_page.dart';

class ProductCatalogPage extends StatefulWidget {
  const ProductCatalogPage({super.key});

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  final _searchController = TextEditingController();
  String? _selectedMode;
  String? _selectedBrand;

  final _brands = ['Nike', 'Adidas', 'Jordan', 'New Balance', 'Salomon', 'Asics', 'Converse'];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    context.read<ProductBloc>().add(
          LoadProductsEvent(
            query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
            brand: _selectedBrand,
            mode: _selectedMode,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KICK EXCHANGE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.neonVolt, size: 28),
            tooltip: 'Jual / Pasang Sepatu',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditProductPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: AppDimens.space8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama sneaker, seri, atau brand...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textGreySecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textGreySecondary),
                        onPressed: () {
                          _searchController.clear();
                          _refresh();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _refresh(),
            ),
          ),
          // Quick Mode Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('Semua', _selectedMode == null, () {
                  setState(() => _selectedMode = null);
                  _refresh();
                }),
                const SizedBox(width: AppDimens.space8),
                _buildFilterChip('Bisa Barter 🔄', _selectedMode == 'trade', () {
                  setState(() => _selectedMode = _selectedMode == 'trade' ? null : 'trade');
                  _refresh();
                }),
                const SizedBox(width: AppDimens.space8),
                _buildFilterChip('Bisa Beli 💳', _selectedMode == 'sale', () {
                  setState(() => _selectedMode = _selectedMode == 'sale' ? null : 'sale');
                  _refresh();
                }),
                const SizedBox(width: AppDimens.space16),
                const Text('|', style: TextStyle(color: AppColors.dividerGrey)),
                const SizedBox(width: AppDimens.space16),
                // Brand Chips
                ..._brands.map((brand) {
                  final isSelected = _selectedBrand?.toLowerCase() == brand.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: AppDimens.space8),
                    child: _buildFilterChip(brand, isSelected, () {
                      setState(() {
                        _selectedBrand = isSelected ? null : brand;
                      });
                      _refresh();
                    }),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          // Product Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refresh(),
              color: AppColors.neonVolt,
              backgroundColor: AppColors.surfaceCardDark,
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.neonVolt),
                    );
                  }

                  if (state is ProductFailureState) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimens.space24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.stateDanger, size: 48),
                            const SizedBox(height: AppDimens.space16),
                            Text(
                              state.errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textWhitePrimary),
                            ),
                            const SizedBox(height: AppDimens.space16),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is ProductEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppDimens.space24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, color: AppColors.textGreySecondary, size: 48),
                            SizedBox(height: AppDimens.space16),
                            Text(
                              'Tidak ada sneaker yang sesuai.',
                              style: TextStyle(color: AppColors.textWhitePrimary, fontSize: 16),
                            ),
                            SizedBox(height: AppDimens.space8),
                            Text(
                              'Coba ganti filter atau jadilah yang pertama menjual!',
                              style: TextStyle(color: AppColors.textGreySecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is ProductLoaded) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: AppDimens.space16,
                        mainAxisSpacing: AppDimens.space16,
                      ),
                      itemCount: state.products.length,
                      itemBuilder: (context, index) {
                        final product = state.products[index];
                        return ProductCard(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailPage(productId: product.id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.neonVolt,
      backgroundColor: AppColors.surfaceCardDark,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textWhitePrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        side: BorderSide(
          color: isSelected ? AppColors.neonVolt : AppColors.borderGrey,
        ),
      ),
    );
  }
}
