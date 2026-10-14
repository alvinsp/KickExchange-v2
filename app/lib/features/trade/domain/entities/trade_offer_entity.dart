import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product_entity.dart';

class TradeOfferEntity extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String offeredProductId;
  final String targetProductId;
  final double cashAdjustment; // > 0: sender pays, < 0: receiver pays, 0: even
  final String notes;
  final String status; // PENDING, ACCEPTED, REJECTED, CANCELLED, COMPLETED
  final DateTime? clientCreatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? senderName;
  final String? receiverName;
  final ProductEntity? offeredProduct;
  final ProductEntity? targetProduct;

  const TradeOfferEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.offeredProductId,
    required this.targetProductId,
    required this.cashAdjustment,
    this.notes = '',
    required this.status,
    this.clientCreatedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
    this.senderName,
    this.receiverName,
    this.offeredProduct,
    this.targetProduct,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        offeredProductId,
        targetProductId,
        cashAdjustment,
        notes,
        status,
        clientCreatedAt,
        createdAt,
        updatedAt,
        isSynced,
        senderName,
        receiverName,
        offeredProduct,
        targetProduct,
      ];
}
