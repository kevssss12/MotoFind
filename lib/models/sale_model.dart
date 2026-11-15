import 'package:cloud_firestore/cloud_firestore.dart';
class SaleModel {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double total;
  final Timestamp? soldAt;
  SaleModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
    this.soldAt,
  });
  factory SaleModel.fromFirestore(String id,Map<String, dynamic> data,) {
    return SaleModel(
      id: id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      price: (data['price'] as num).toDouble(),
      quantity: data['quantity'] ?? 0,
      total: (data['total'] as num).toDouble(),
      soldAt: data['soldAt'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'total': total,
      'soldAt': soldAt,
    };
  }
}