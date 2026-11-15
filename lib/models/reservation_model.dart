import 'package:cloud_firestore/cloud_firestore.dart';
class ReservationModel {
  final String id;
  final String storeId;
  final String productId;
  final String productName;
  final String customerId;
  final String customerName;
  final int quantity;
  final String status;
  final Timestamp? createdAt;
  ReservationModel({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.customerId,
    required this.customerName,
    required this.quantity,
    required this.status,
    this.createdAt,
  });
  factory ReservationModel.fromFirestore(
      DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReservationModel(
      id: doc.id,
      storeId:data["storeId"] ?? "",        
      productId:data["productId"] ?? "",
      productName: data["productName"] ?? "",
      customerId:data["customerId"] ?? "",          
      customerName: data["customerName"] ?? "",
      quantity: data["quantity"] ?? 0,         
      status:data["status"] ?? "",         
      createdAt:data["createdAt"],         
    );
  }
  Map<String, dynamic> toMap() {
    return {
      "storeId": storeId,
      "productId": productId,
      "productName": productName,
      "customerId": customerId,
      "customerName": customerName,
      "quantity": quantity,
      "status": status,
      "createdAt":
          FieldValue.serverTimestamp(),
    };
  }
}