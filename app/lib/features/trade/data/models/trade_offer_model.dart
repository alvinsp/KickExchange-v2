import '../../domain/entities/trade_offer_entity.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/domain/entities/product_entity.dart';

class TradeOfferModel extends TradeOfferEntity {
  const TradeOfferModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.offeredProductId,
    required super.targetProductId,
    required super.cashAdjustment,
    super.notes,
    required super.status,
    super.clientCreatedAt,
    required super.createdAt,
    required super.updatedAt,
    super.isSynced,
    super.senderName,
    super.receiverName,
    super.offeredProduct,
    super.targetProduct,
  });

  factory TradeOfferModel.fromJson(Map<String, dynamic> json) {
    ProductModel? offered;
    ProductModel? target;

    if (json['offered_product'] is Map) {
      offered = ProductModel.fromJson(json['offered_product'] as Map<String, dynamic>);
    }
    if (json['target_product'] is Map) {
      target = ProductModel.fromJson(json['target_product'] as Map<String, dynamic>);
    }

    final sender = json['sender'];
    final receiver = json['receiver'];

    return TradeOfferModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      offeredProductId: json['offered_product_id'] as String,
      targetProductId: json['target_product_id'] as String,
      cashAdjustment: (json['cash_adjustment'] as num).toDouble(),
      notes: (json['notes'] as String?) ?? '',
      status: json['status'] as String,
      clientCreatedAt: json['client_created_at'] != null ? DateTime.tryParse(json['client_created_at'].toString()) : null,
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
      isSynced: json['is_synced'] == null ? true : (json['is_synced'] == 1 || json['is_synced'] == true),
      senderName: sender is Map ? sender['name'] as String? : json['sender_name'] as String?,
      receiverName: receiver is Map ? receiver['name'] as String? : json['receiver_name'] as String?,
      offeredProduct: offered,
      targetProduct: target,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'offered_product_id': offeredProductId,
      'target_product_id': targetProductId,
      'cash_adjustment': cashAdjustment.toInt(),
      'notes': notes,
      'status': status,
      'client_created_at': clientCreatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqliteRow() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'offered_product_id': offeredProductId,
      'target_product_id': targetProductId,
      'cash_adjustment': cashAdjustment,
      'notes': notes,
      'status': status,
      'client_created_at': clientCreatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  TradeOfferModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? offeredProductId,
    String? targetProductId,
    double? cashAdjustment,
    String? notes,
    String? status,
    DateTime? clientCreatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? senderName,
    String? receiverName,
    ProductEntity? offeredProduct,
    ProductEntity? targetProduct,
  }) {
    return TradeOfferModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      offeredProductId: offeredProductId ?? this.offeredProductId,
      targetProductId: targetProductId ?? this.targetProductId,
      cashAdjustment: cashAdjustment ?? this.cashAdjustment,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      offeredProduct: offeredProduct ?? this.offeredProduct,
      targetProduct: targetProduct ?? this.targetProduct,
    );
  }
}

