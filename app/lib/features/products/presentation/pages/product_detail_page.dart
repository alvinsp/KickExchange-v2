import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../trade/presentation/bloc/trade_bloc.dart';
import '../../../trade/presentation/bloc/trade_event.dart';
import '../../../transactions/presentation/pages/checkout_page.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import 'add_edit_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  ProductEntity? _product;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userRes = await sl<AuthRepository>().getCurrentUser();
    userRes.fold((_) => null, (u) => _currentUserId = u?.id);

    final result = await sl<ProductRepository>().getProductById(widget.productId);
    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _errorMessage = failure.message;
      }),
      (product) => setState(() {
        _isLoading = false;
        _product = product;
      }),
    );
  }

  void _showTradeProposalDialog() async {
    if (_product == null) return;

    // Load current user's products available for trade
    final myProductsRes = await sl<ProductRepository>().getProducts(onlyMine: true);
    final myTradeables = myProductsRes.fold(
      (_) => <ProductEntity>[],
      (list) => list.where((p) => p.isForTrade && p.id != _product!.id).toList(),
    );

    if (!mounted) return;

    if (myTradeables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.solarOrange,
          content: Text('Anda belum memiliki sepatu yang siap ditukar. Tambahkan listing sepatu Anda terlebih dahulu.'),
        ),
      );
      return;
    }

    String selectedOfferedId = myTradeables.first.id;
    final cashDiffController = TextEditingController(text: '0');
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppDimens.space24,
                right: AppDimens.space24,
                top: AppDimens.space24,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.space24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Ajukan Barter / Tukar Sepatu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppDimens.space8),
                    Text(
                      'Tukar dengan: ${_product!.name} (US ${_product!.sizeUs})',
                      style: const TextStyle(color: AppColors.neonVolt, fontSize: 13),
                    ),
                    const SizedBox(height: AppDimens.space16),
                    const Text('Pilih Sepatu Milik Anda:', style: TextStyle(fontSize: 12, color: AppColors.textGreySecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedOfferedId,
                      dropdownColor: AppColors.elevatedCardDark,
                      items: myTradeables.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} (US ${p.sizeUs})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedOfferedId = val);
                      },
                    ),
                    const SizedBox(height: AppDimens.space16),
                    const Text('Penyesuaian Tunai (+ Anda bayar / - Pemilik bayar):', style: TextStyle(fontSize: 12, color: AppColors.textGreySecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: cashDiffController,
                      keyboardType: const TextInputType.numberWithOptions(signed: true),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 250000 atau -150000',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),
                    TextFormField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Pesan / Catatan Tambahan',
                        hintText: 'Kondisi mulus, box lengkap...',
                      ),
                    ),
                    const SizedBox(height: AppDimens.space24),
                    ElevatedButton(
                      onPressed: () {
                        final cashDiff = double.tryParse(cashDiffController.text.trim()) ?? 0.0;
                        context.read<TradeBloc>().add(
                              SubmitTradeOfferEvent(
                                offeredProductId: selectedOfferedId,
                                targetProductId: _product!.id,
                                cashAdjustment: cashDiff,
                                notes: notesController.text.trim(),
                              ),
                            );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.stateSuccess,
                            content: Text('Tawaran barter berhasil dikirim! Periksa menu Trade.'),
                          ),
                        );
                      },
                      child: const Text('KIRIM PENAWARAN'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.neonVolt)),
      );
    }

    if (_errorMessage != null || _product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.stateDanger, size: 48),
              const SizedBox(height: AppDimens.space16),
              Text(_errorMessage ?? 'Produk tidak ditemukan.'),
              const SizedBox(height: AppDimens.space16),
              ElevatedButton(onPressed: _loadProduct, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    final p = _product!;
    final isOwner = _currentUserId != null && _currentUserId == p.ownerId;
    final hasImages = p.imageUrls.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.brand.toUpperCase()),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.neonVolt),
              tooltip: 'Edit Data (Offline Ready)',
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => AddEditProductPage(initialProduct: p)),
                );
                if (updated == true) _loadProduct();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sneaker Gallery Banner
            SizedBox(
              height: 280,
              child: hasImages
                  ? Image.network(
                      p.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.elevatedCardDark,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Text(
                          p.condition.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textWhitePrimary),
                        ),
                      ),
                      const SizedBox(width: AppDimens.space8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.elevatedCardDark,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Text(
                          'SIZE US ${p.sizeUs}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neonVolt),
                        ),
                      ),
                      const Spacer(),
                      if (!p.isSynced)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.stateOffline,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('OFFLINE CACHE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space12),
                  Text(
                    p.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textWhitePrimary),
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Text(
                    CurrencyFormatter.format(p.price),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.neonVolt),
                  ),
                  const SizedBox(height: AppDimens.space24),
                  const Divider(color: AppColors.dividerGrey),
                  const SizedBox(height: AppDimens.space16),
                  const Text('Deskripsi Sepatu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppDimens.space8),
                  Text(
                    p.description.isEmpty ? 'Tidak ada deskripsi tambahan.' : p.description,
                    style: const TextStyle(color: AppColors.textGreySecondary, height: 1.5),
                  ),
                  const SizedBox(height: AppDimens.space24),
                  // Seller Info Card with Masking
                  Container(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCardDark,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.elevatedCardDark,
                          child: Icon(Icons.person, color: AppColors.neonVolt),
                        ),
                        const SizedBox(width: AppDimens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.ownerName ?? 'Sneakerhead', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(p.ownerEmail ?? '-', style: const TextStyle(color: AppColors.textGreySecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (isOwner)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.neonVolt.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: const Text('MILIK SAYA', style: TextStyle(color: AppColors.neonVolt, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Spacing for sticky bottom buttons
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: !isOwner
          ? Container(
              color: AppColors.surfaceCardDark,
              padding: const EdgeInsets.all(AppDimens.space16),
              child: SafeArea(
                child: Row(
                  children: [
                    if (p.isForTrade)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showTradeProposalDialog,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.solarOrange, width: 1.5),
                            foregroundColor: AppColors.solarOrange,
                          ),
                          child: const Text('TUKAR (TRADE) 🔄'),
                        ),
                      ),
                    if (p.isForTrade && p.isForSale) const SizedBox(width: AppDimens.space12),
                    if (p.isForSale)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutPage(product: p),
                              ),
                            );
                          },
                          child: const Text('BELI SEKARANG 💳'),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.elevatedCardDark,
      child: const Center(child: Icon(Icons.sports_baseball, size: 64, color: AppColors.borderGrey)),
    );
  }
}
