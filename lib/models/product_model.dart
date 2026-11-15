import 'package:cloud_firestore/cloud_firestore.dart';
class ProductModel {

  final String id;
  final String name;
  final double price;
  final int stock;
  final int alertStock;
  final String category;
  final String storeId;
  final String imageUrl;
  final DateTime createdAt;


  ProductModel({

    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.alertStock,
    required this.category,
    required this.storeId,
    required this.imageUrl,
    required this.createdAt,
  });
  // Convert Firestore data to ProductModel
  factory ProductModel.fromFirestore(String id,Map<String, dynamic> data,) {
  final createdAtData = data['createdAt'];
  DateTime createdDate;
 if (createdAtData is Timestamp) {createdDate = createdAtData.toDate();
  } else {
    createdDate = DateTime.now();
  }
  return ProductModel(id: id,name: data['name']?.toString() ?? '',price: double.tryParse(data['price']?.toString() ?? '0',) ?? 0,stock: int.tryParse(
     data['stock']?.toString() ?? '0',) ?? 0,
    alertStock: int.tryParse(data['alertStock']?.toString() ?? '0',) ?? 0,
    category:data['category']?.toString() ?? '',
    storeId: data['storeId']?.toString() ?? '',
    imageUrl: data['imageUrl']?.toString() ?? '',
    createdAt: createdDate,
  );
}
// Convert ProductModel to Firestore Map
  Map<String, dynamic> toMap() {
return {
'name': name,
'price': price,
'stock': stock,
'alertStock': alertStock,
'category': category,
'storeId': storeId,
'imageUrl': imageUrl,
'createdAt': createdAt,
   };
  }
// Copy with (useful for update/edit product)
  ProductModel copyWith({
    String? name,
    double? price,
    int? stock,
    int? alertStock,
    String? category,
    String? storeId,
    String? imageUrl,
    DateTime? createdAt,
 }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      alertStock: alertStock ?? this.alertStock,
      category: category ?? this.category,
      storeId: storeId ?? this.storeId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}