import 'dart:convert';
import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.ownerId,
    required super.name,
    required super.brand,
    required super.sizeUs,
    required super.price,
    required super.condition,
    super.description,
    super.imageUrls,
    super.isForSale,
    super.isForTrade,
    super.isSold,
    super.status,
    required super.createdAt,
    required super.updatedAt,
    super.isSynced,
    super.ownerName,
    super.ownerEmail,
    super.ownerPhone,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    final rawImages = json['image_urls'];
    if (rawImages is List) {
      images = rawImages.map((e) => e.toString()).toList();
    } else if (rawImages is String && rawImages.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawImages);
        if (decoded is List) {
          images = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    final owner = json['owner'];

    return ProductModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      sizeUs: (json['size_us'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      condition: json['condition'] as String,
      description: (json['description'] as String?) ?? '',
      imageUrls: images,
      isForSale: json['is_for_sale'] == 1 || json['is_for_sale'] == true,
      isForTrade: json['is_for_trade'] == 1 || json['is_for_trade'] == true,
      isSold: json['is_sold'] == 1 || json['is_sold'] == true,
      status: (json['status'] as String?) ?? 'AVAILABLE',
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
      isSynced: json['is_synced'] == null ? true : (json['is_synced'] == 1 || json['is_synced'] == true),
      ownerName: owner is Map ? owner['name'] as String? : json['owner_name'] as String?,
      ownerEmail: owner is Map ? owner['email'] as String? : json['owner_email'] as String?,
      ownerPhone: owner is Map ? owner['phone'] as String? : json['owner_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'brand': brand,
      'size_us': sizeUs,
      'price': price,
      'condition': condition,
      'description': description,
      'image_urls': imageUrls,
      'is_for_sale': isForSale,
      'is_for_trade': isForTrade,
      'is_sold': isSold,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqliteRow() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'brand': brand,
      'size_us': sizeUs,
      'price': price,
      'condition': condition,
      'description': description,
      'image_urls': jsonEncode(imageUrls),
      'is_for_sale': isForSale ? 1 : 0,
      'is_for_trade': isForTrade ? 1 : 0,
      'is_sold': isSold ? 1 : 0,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      brand: entity.brand,
      sizeUs: entity.sizeUs,
      price: entity.price,
      condition: entity.condition,
      description: entity.description,
      imageUrls: entity.imageUrls,
      isForSale: entity.isForSale,
      isForTrade: entity.isForTrade,
      isSold: entity.isSold,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: entity.isSynced,
      ownerName: entity.ownerName,
      ownerEmail: entity.ownerEmail,
      ownerPhone: entity.ownerPhone,
    );
  }
}
