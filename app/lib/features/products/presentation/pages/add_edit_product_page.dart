import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';

class AddEditProductPage extends StatefulWidget {
  final ProductEntity? initialProduct;

  const AddEditProductPage({super.key, this.initialProduct});

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _sizeController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;

  String _condition = 'BNIB';
  bool _isForSale = true;
  bool _isForTrade = true;

  final List<String> _brands = [
    'Nike',
    'Jordan',
    'Adidas',
    'New Balance',
    'Salomon',
    'Asics',
    'Converse',
    'Vans',
    'Puma',
  ];

  final Map<String, String> _conditionLabels = {
    'BNIB': 'BNIB (Brand New In Box)',
    'BNWD': 'BNWD (Brand New With Defect)',
    'USED_VERY_GOOD': 'VNDS / Used - Very Good',
    'USED_GOOD': 'Used - Good Condition',
  };

  bool get _isEditing => widget.initialProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    _nameController = TextEditingController(text: p?.name ?? '');
    _brandController = TextEditingController(text: p?.brand ?? 'Nike');
    _sizeController = TextEditingController(text: p != null ? p.sizeUs.toString() : '9.0');
    _priceController = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(0) : '2500000',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _imageUrlController = TextEditingController(
      text: p != null && p.imageUrls.isNotEmpty ? p.imageUrls.first : '',
    );
    if (p != null) {
      _condition = p.condition;
      _isForSale = p.isForSale;
      _isForTrade = p.isForTrade;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isForSale && !_isForTrade) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.stateDanger,
          content: Text('Pilih minimal satu opsi: Dijual atau Ditukar.'),
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final sizeUs = double.tryParse(_sizeController.text.trim()) ?? 9.0;
    final imageUrl = _imageUrlController.text.trim();
    final imageUrls = imageUrl.isNotEmpty
        ? [imageUrl]
        : [
            'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800&auto=format&fit=crop&q=80',
          ];

    if (_isEditing) {
      final current = widget.initialProduct!;
      final updated = current.copyWith(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        sizeUs: sizeUs,
        price: price,
        condition: _condition,
        description: _descriptionController.text.trim(),
        imageUrls: imageUrls,
        isForSale: _isForSale,
        isForTrade: _isForTrade,
      );
      context.read<ProductBloc>().add(
            UpdateProductSubmittedEvent(
              product: updated,
              baseUpdatedAt: current.updatedAt,
            ),
          );
    } else {
      context.read<ProductBloc>().add(
            CreateProductSubmittedEvent(
              name: _nameController.text.trim(),
              brand: _brandController.text.trim(),
              sizeUs: sizeUs,
              price: price,
              condition: _condition,
              description: _descriptionController.text.trim(),
              imageUrls: imageUrls,
              isForSale: _isForSale,
              isForTrade: _isForTrade,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'EDIT LISTING SEPATU' : 'LISTING SEPATU BARU'),
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.stateSuccess,
                content: Text(state.message),
              ),
            );
            Navigator.pop(context, true);
          } else if (state is ProductFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.stateDanger,
                content: Text(state.errorMessage),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ProductLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Offline First Tip Banner
                  Container(
                    padding: const EdgeInsets.all(AppDimens.space12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCardDark,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                      border: Border.all(color: AppColors.stateOffline.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.offline_bolt, color: AppColors.neonVolt, size: 20),
                        SizedBox(width: AppDimens.space8),
                        Expanded(
                          child: Text(
                            'Offline-First: Perubahan tersimpan lokal di SQLite dan otomatis tersinkronisasi saat sinyal aktif.',
                            style: TextStyle(fontSize: 12, color: AppColors.textWhitePrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.space20),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Sneaker *',
                      hintText: 'Contoh: Air Jordan 1 Retro High OG Chicago',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 3) {
                        return 'Nama sneaker minimal 3 karakter.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // Brand & Size Row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _brands.contains(_brandController.text)
                              ? _brandController.text
                              : _brands.first,
                          decoration: const InputDecoration(labelText: 'Brand *'),
                          items: _brands.map((b) {
                            return DropdownMenuItem(value: b, child: Text(b));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _brandController.text = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimens.space12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _sizeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Size US *',
                            hintText: '9.5',
                          ),
                          validator: (val) {
                            final n = double.tryParse(val ?? '');
                            if (n == null || n <= 0) return 'Tidak valid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // Price (IDR)
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Harga (IDR) *',
                      prefixText: 'Rp ',
                      hintText: '2500000',
                    ),
                    validator: (val) {
                      final n = double.tryParse(val ?? '');
                      if (n == null || n < 10000) {
                        return 'Harga minimal Rp 10.000.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // Condition Dropdown
                  DropdownButtonFormField<String>(
                    value: _condition,
                    decoration: const InputDecoration(labelText: 'Kondisi Sepatu *'),
                    items: _conditionLabels.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _condition = val);
                    },
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // Image URL
                  TextFormField(
                    controller: _imageUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL Gambar Sepatu (Opsional)',
                      hintText: 'https://images.unsplash.com/...',
                      prefixIcon: Icon(Icons.image_outlined, color: AppColors.textGreySecondary),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi & Kelengkapan (Box, Tag, Receipt)',
                      hintText: 'Sepatu mulus, box original lengkap, pembelian dari Atmos Jakarta...',
                    ),
                  ),
                  const SizedBox(height: AppDimens.space20),

                  // Toggles
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCardDark,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Buka untuk Dijual Langsung', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Pembeli dapat membeli via QRIS / Bank VA', style: TextStyle(color: AppColors.textGreySecondary, fontSize: 12)),
                          activeColor: AppColors.neonVolt,
                          value: _isForSale,
                          onChanged: (val) => setState(() => _isForSale = val),
                        ),
                        const Divider(height: 1, color: AppColors.borderGrey),
                        SwitchListTile(
                          title: const Text('Buka untuk Barter / Trade 🔄', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Pengguna lain dapat mengajukan penawaran tukar tambah', style: TextStyle(color: AppColors.textGreySecondary, fontSize: 12)),
                          activeColor: AppColors.solarOrange,
                          value: _isForTrade,
                          onChanged: (val) => setState(() => _isForTrade = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.space32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(_isEditing ? 'SIMPAN PERUBAHAN' : 'TAYANGKAN LISTING SEPATU'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
