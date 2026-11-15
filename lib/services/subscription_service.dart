import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> createSubscription({

    required String storeId,
    required String storeName,
    required String storeAddress,

    required String ownerId,
    required String ownerName,
    required String email,
    required String phone,

    required String plan,
    required int amount,

    required String paymentImageUrl,

  }) async {

    await _firestore
    .collection("subscriptions")
    .add({

  "storeId": storeId,
  "storeName": storeName,
  "storeAddress": storeAddress,

  "ownerId": ownerId,
  "ownerName": ownerName,

  "email": email,
  "phone": phone,

  "plan": plan,
  "amount": amount,

  "paymentImageUrl": paymentImageUrl,

  "status": "Pending",

  "type": "New",

  "createdAt": FieldValue.serverTimestamp(),

});

  }
}