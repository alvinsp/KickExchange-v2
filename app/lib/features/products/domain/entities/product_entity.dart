import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String brand;
  final double sizeUs;
  final double price;
  final String condition; // BNIB, BNWD, USED_VERY_GOOD, USED_GOOD
  final String description;
  final List<String> imageUrls;
  final bool isForSale;
  final bool isForTrade;
  final bool isSold;
  final String status; // AVAILABLE, RESERVED, SOLD
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerPhone;

  const ProductEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.brand,
    required this.sizeUs,
    required this.price,
    required this.condition,
    this.description = '',
    this.imageUrls = const [],
    this.isForSale = true,
    this.isForTrade = true,
    this.isSold = false,
    this.status = 'AVAILABLE',
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
  });

  ProductEntity copyWith({
    String? name,
    String? brand,
    double? sizeUs,
    double? price,
    String? condition,
    String? description,
    List<String>? imageUrls,
    bool? isForSale,
    bool? isForTrade,
    bool? isSold,
    String? status,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return ProductEntity(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      sizeUs: sizeUs ?? this.sizeUs,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      isForSale: isForSale ?? this.isForSale,
      isForTrade: isForTrade ?? this.isForTrade,
      isSold: isSold ?? this.isSold,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerPhone: ownerPhone,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        brand,
        sizeUs,
        price,
        condition,
        description,
        imageUrls,
        isForSale,
        isForTrade,
        isSold,
        status,
        createdAt,
        updatedAt,
        isSynced,
        ownerName,
        ownerEmail,
        ownerPhone,
      ];
}
