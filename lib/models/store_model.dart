
import 'package:cloud_firestore/cloud_firestore.dart';
class StoreModel {
  final String id;
  final String ownerId;
  final String storeName;
  final String ownerName;
  final String address;
  final String phone;
  final String? storeImage;
  final String? gcashQrUrl;
  final double? latitude;
  final double? longitude;
  final Timestamp? createdAt;
  StoreModel({
    required this.id,
    required this.ownerId,
    required this.storeName,
    required this.ownerName,
    required this.address,
    required this.phone,
    this.storeImage,
    this.gcashQrUrl,
    this.latitude,
    this.longitude,
    this.createdAt,
  });
  factory StoreModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return StoreModel(
      id: id,
      ownerId: data['ownerId'] ?? '',
      storeName: data['storeName'] ?? '',
      ownerName: data['ownerName'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      storeImage: data['storeImage'],
      gcashQrUrl: data['gcashQrUrl'],
      latitude: data['latitude'] != null
          ? (data['latitude'] as num).toDouble()
          : null,
      longitude: data['longitude'] != null
          ? (data['longitude'] as num).toDouble()
          : null,
      createdAt: data['createdAt'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'storeName': storeName,
      'ownerName': ownerName,
      'address': address,
      'phone': phone,
      'storeImage': storeImage,
      'gcashQrUrl': gcashQrUrl,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
