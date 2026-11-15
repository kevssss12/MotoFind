import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/product_model.dart';
import '../models/store_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        "Please enable your device location.",
      );
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception(
          "Location permission was denied.",
        );
      }
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        "Location permission is permanently denied. Please enable it in settings.",
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // ============================================================
  // SAVE USER
  // ============================================================

  Future<void> saveUser({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
    required String role,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set({
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,

      // Subscription
      'hasSubscribed': false,

      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // GET USER ROLE
  // ============================================================

  Future<String?> getUserRole(
    String uid,
  ) async {
    DocumentSnapshot doc =
        await _firestore
            .collection('users')
            .doc(uid)
            .get();

    if (doc.exists) {
      return doc['role'];
    }

    return null;
  }

  // ============================================================
  // ADD PRODUCT
  // ============================================================

  Future<void> addProduct({
    required String name,
    required double price,
    required int stock,
    required int alertStock,
    required String storeId,
    required String imageUrl,
  }) async {
    await _firestore
        .collection('products')
        .add({
      'name': name,
      'price': price,
      'stock': stock,
      'alertStock': alertStock,
      'storeId': storeId,
      'imageUrl': imageUrl,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // SAVE STORE (OLD)
  // ============================================================

  Future<void> saveStore({
    required String storeName,
    required String address,
    required String phone,
  }) async {
    await _firestore
        .collection('stores')
        .add({
      'storeName': storeName,
      'address': address,
      'phone': phone,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // SAVE STORE PROFILE
  // ============================================================

  Future<void> saveStoreProfile(
    StoreModel store,
  ) async {
    await _firestore
        .collection("stores")
        .doc(store.id)
        .set(
          store.toMap(),
        );
  }

  // ============================================================
  // GET STORE PROFILE
  // ============================================================

  Future<StoreModel?> getStoreProfile(
    String storeId,
  ) async {
    final doc = await _firestore
        .collection("stores")
        .doc(storeId)
        .get();

    if (doc.exists) {
      return StoreModel.fromFirestore(
        doc.id,
        doc.data()!,
      );
    }

    return null;
  }

  // ============================================================
  // UPDATE STORE PROFILE
  // ============================================================

  Future<void> updateStoreProfile(
    StoreModel store,
  ) async {
    await _firestore
        .collection("stores")
        .doc(store.id)
        .update(
          store.toMap(),
        );
  }

  // ============================================================
  // GET PRODUCTS STREAM
  // FOR STORE OWNER ONLY
  // ============================================================

  Stream<QuerySnapshot> getOwnerProducts(
    String storeId,
  ) {
    return _firestore
        .collection('products')
        .where(
          'storeId',
          isEqualTo: storeId,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // FOR CUSTOMER (ALL PRODUCTS)
  // ============================================================

  Stream<QuerySnapshot> getProducts() {
    return _firestore
        .collection('products')
        .snapshots();
  }

  // ============================================================
  // GET ALL PRODUCTS
  // ============================================================

  Stream<QuerySnapshot> getAllProducts() {
    return _firestore
        .collection('products')
        .snapshots();
  }

  // ============================================================
  // GET PRODUCTS LIST
  // ============================================================

  Future<List<ProductModel>> getProductsList() async {
    QuerySnapshot snapshot =
        await _firestore
            .collection('products')
            .get();

    return snapshot.docs.map((doc) {
      return ProductModel.fromFirestore(
        doc.id,
        doc.data()
            as Map<String, dynamic>,
      );
    }).toList();
  }

  // ============================================================
  // SELL PRODUCT - WALK IN
  // ============================================================

 
Future<void> sellProduct({
  required String productId,
  required String productName,
  required double price,
  required int currentStock,
  required int quantitySold,
  required String storeId,
}) async {
  if (quantitySold <= 0) {
    throw Exception("Invalid quantity.");
  }

  final productRef =
      _firestore.collection("products").doc(productId);

  final saleRef =
      _firestore.collection("sales").doc();

  await _firestore.runTransaction((transaction) async {
    final productSnap = await transaction.get(productRef);

    if (!productSnap.exists) {
      throw Exception("Product not found.");
    }

    final productData = productSnap.data();

    if (productData == null) {
      throw Exception("Product information is unavailable.");
    }

    final int latestStock =
        (productData["stock"] as num?)?.toInt() ?? 0;

    final double latestPrice =
        (productData["price"] as num?)?.toDouble() ?? 0;

    final String latestName =
        productData["name"]?.toString() ?? productName;

    final String latestStoreId =
        productData["storeId"]?.toString() ?? "";

    if (latestStoreId != storeId) {
      throw Exception("Invalid store ownership.");
    }

    if (quantitySold > latestStock) {
      throw Exception("Not enough stock.");
    }

    transaction.update(productRef, {
      "stock": latestStock - quantitySold,
    });

    transaction.set(saleRef, {
      "productId": productId,
      "productName": latestName,
      "price": latestPrice,
      "quantity": quantitySold,
      "total": latestPrice * quantitySold,
      "storeId": latestStoreId,
      "saleType": "Walk-in",
      "soldAt": FieldValue.serverTimestamp(),
    });
  });
}
  // ============================================================
  // RESERVE PRODUCT WITH GCASH PAYMENT PROOF
  // ============================================================

Future<void> reserveProduct({
  required String customerId,
  required String customerName,
  required ProductModel product,
  required int quantity,
  required String paymentProofUrl,
  String reservationNote = '',
}) async {
    if (quantity <= 0) {
      throw Exception("Invalid quantity.");
    }

    if (paymentProofUrl.trim().isEmpty) {
      throw Exception(
        "Please upload your GCash payment screenshot.",
      );
    }

    final reservationRef =
        _firestore.collection("reservations").doc();

    final productRef =
        _firestore.collection("products").doc(product.id);

    await _firestore.runTransaction((transaction) async {
      // Read the latest stock inside the transaction.
      final productSnap = await transaction.get(productRef);

      if (!productSnap.exists) {
        throw Exception("Product not found.");
      }

      final productData = productSnap.data();

      if (productData == null) {
        throw Exception("Product information is unavailable.");
      }

      final int currentStock =
          (productData["stock"] as num?)?.toInt() ?? 0;

      if (quantity > currentStock) {
        throw Exception("Not enough stock.");
      }

      final double currentPrice =
          (productData["price"] as num?)?.toDouble() ??
              product.price;

      final double totalAmount = currentPrice * quantity;

      // Deduct stock exactly once.
     transaction.update(productRef, {
  "stock": currentStock - quantity,
  "lastReservationId": reservationRef.id,
});

      // Create the reservation and save its payment proof.
transaction.set(reservationRef, {
  "customerId": customerId,
  "customerName": customerName,
  "productId": product.id,
  "productName": product.name,
  "price": currentPrice,
  "quantity": quantity,
  "totalAmount": totalAmount,
  "storeId": product.storeId,

  "paymentMethod": "GCash",
  "paymentProofUrl": paymentProofUrl,
  "reservationNote": reservationNote.trim(),
  "paymentStatus": "Pending",
  "paymentSubmittedAt": FieldValue.serverTimestamp(),

  "status": "Active",
  "reservedAt": FieldValue.serverTimestamp(),
});
    });
  }

    // ============================================================
    // COMPLETE RESERVATION
    // ============================================================

    Future<void>
        completeReservation(
      String reservationId,
    ) async {
      final reservationRef =
          _firestore
              .collection(
                "reservations",
              )
              .doc(reservationId);

      await _firestore
          .runTransaction(
        (transaction) async {
          final reservationSnap =
              await transaction.get(
            reservationRef,
          );

          if (!reservationSnap.exists) {
            throw Exception(
              "Reservation not found.",
            );
          }

          final data =
              reservationSnap.data();

          if (data == null) {
            throw Exception(
              "Reservation data not found.",
            );
          }

          // IMPORTANT:
          // Only ACTIVE reservation can be completed.

         if (data["status"] != "Active") {
  throw Exception(
    "This reservation is no longer active.",
  );
}

          final double price =
              (data["price"] as num?)
                      ?.toDouble() ??
                  0;

          final int quantity =
              (data["quantity"] as num?)
                      ?.toInt() ??
                  0;

          if (quantity <= 0) {
            throw Exception(
              "Invalid reservation quantity.",
            );
          }

          // ==============================================
          // CREATE SALES RECORD
          // RESERVATION ONLY
          // ==============================================

          final saleRef =
              _firestore
                  .collection("sales")
                  .doc();

          transaction.set(
            saleRef,
            {
              "productId":
                  data["productId"],

              "productName":
                  data["productName"],

              "customerId":
                  data["customerId"],

              "customerName":
                  data["customerName"],

              "price":
                  price,

              "quantity":
                  quantity,

              "total":
                  price * quantity,

              "storeId":
                  data["storeId"],

              "saleType":
                  "Reservation",

              "soldAt":
                  FieldValue
                      .serverTimestamp(),

              "reservationId":
                  reservationId,
            },
          );

          // ==============================================
          // MARK RESERVATION AS COMPLETED
          // ==============================================

          transaction.update(
            reservationRef,
            {
              "status":
                  "Completed",

              "completedAt":
                  FieldValue
                      .serverTimestamp(),
            },
          );
        },
      );
    }
    
  // ============================================================
  // CANCEL RESERVATION
  // Restore reserved stock only once.
  // ============================================================

  Future<void> cancelReservation(
    String reservationId,
  ) async {
    final reservationRef = _firestore
        .collection("reservations")
        .doc(reservationId);

    await _firestore.runTransaction(
      (transaction) async {
        final reservationSnap =
            await transaction.get(reservationRef);

        if (!reservationSnap.exists) {
          throw Exception("Reservation not found.");
        }

        final data = reservationSnap.data();

        if (data == null) {
          throw Exception("Reservation data not found.");
        }

        // Only an active reservation can be cancelled.
        if (data["status"] != "Active") {
          throw Exception(
            "This reservation is no longer active.",
          );
        }

        final String productId =
            data["productId"]?.toString() ?? "";

        final int quantity =
            (data["quantity"] as num?)?.toInt() ?? 0;

        if (productId.isEmpty) {
          throw Exception("Product ID is missing.");
        }

        if (quantity <= 0) {
          throw Exception("Invalid reservation quantity.");
        }

        final productRef = _firestore
            .collection("products")
            .doc(productId);

        // Read product before performing any transaction writes.
        final productSnap =
            await transaction.get(productRef);

        // Restore stock if the product still exists.
        if (productSnap.exists) {
          final productData = productSnap.data();

          if (productData == null) {
            throw Exception("Product data not found.");
          }

          final int currentStock =
              (productData["stock"] as num?)?.toInt() ?? 0;

          transaction.update(productRef, {
            "stock": currentStock + quantity,
          });
        }

        // Mark cancelled in the same transaction.
        // A second cancellation cannot restore stock again.
        transaction.update(reservationRef, {
          "status": "Cancelled",
          "cancelledAt": FieldValue.serverTimestamp(),
        });
      },
    );
  }


  // ============================================================
  // GET STORE APPROVAL STATUS
  // ============================================================

  Future<String?>
      getStoreApprovalStatus(
    String userId,
  ) async {
    final doc =
        await FirebaseFirestore
            .instance
            .collection("users")
            .doc(userId)
            .get();

    if (!doc.exists) {
      return null;
    }

    return doc.data()?["status"];
  }

  // ============================================================
  // GET SUBSCRIPTION STATUS
  // ============================================================

  Future<String?>
      getSubscriptionStatus(
    String userId,
  ) async {
    final doc =
        await _firestore
            .collection("users")
            .doc(userId)
            .get();

    if (!doc.exists) {
      return null;
    }

    return doc.data()?[
        "subscriptionStatus"];
  }

  // ============================================================
  // GET SUBSCRIPTION PLAN MONTHS
  // ============================================================

  int getSubscriptionMonths(
    String plan,
  ) {
    switch (plan
        .toLowerCase()
        .trim()) {
      case "monthly":
        return 1;

      case "quarterly":
        return 3;

      case "yearly":
        return 12;

      default:
        throw Exception(
          "Invalid subscription plan: $plan",
        );
    }
  }

  // ============================================================
  // CREATE SUBSCRIPTION PAYMENT
  //
  // IMPORTANT:
  // Pending muna.
  //
  // HINDI pa gagalawin ang:
  // startDate
  // endDate
  //
  // Kapag Admin approved lamang
  // mag-uupdate ang dates.
  // ============================================================

  Future<void>
      createSubscription({
    required String storeId,
    required String ownerId,
    required String plan,
    required double amount,
    required String paymentImageUrl,
  }) async {
    await _firestore
        .collection(
          "subscriptions",
        )
        .add({
      "storeId":
          storeId,

      "ownerId":
          ownerId,

      "plan":
          plan,

      "amount":
          amount,

      "paymentImageUrl":
          paymentImageUrl,

      "status":
          "Pending",

      "createdAt":
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // ADD MONTHS SAFELY
  // ============================================================

  DateTime _addMonths(
    DateTime date,
    int months,
  ) {
    final int year =
        date.year +
            ((date.month - 1 + months) ~/
                12);

    final int month =
        ((date.month - 1 + months) %
                12) +
            1;

    // Last valid day of target month
    final int lastDayOfMonth =
        DateTime(
      year,
      month + 1,
      0,
    ).day;

    final int day =
        date.day > lastDayOfMonth
            ? lastDayOfMonth
            : date.day;

    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  // ============================================================
  // APPROVE SUBSCRIPTION
  //
  // ACTIVE:
  // Existing startDate stays.
  // Existing endDate + plan duration.
  //
  // EXPIRED:
  // startDate = NOW.
  // endDate = NOW + plan duration.
  // ============================================================

  Future<void>
      approveSubscription(
    String subscriptionId,
  ) async {
    final subscriptionRef =
        _firestore
            .collection(
              "subscriptions",
            )
            .doc(
              subscriptionId,
            );

    await _firestore
        .runTransaction(
      (transaction) async {
        // ==============================================
        // GET SUBSCRIPTION
        // ==============================================

        final subscriptionSnap =
            await transaction.get(
          subscriptionRef,
        );

        if (!subscriptionSnap.exists) {
          throw Exception(
            "Subscription not found.",
          );
        }

        final subscriptionData =
            subscriptionSnap.data();

        if (subscriptionData == null) {
          throw Exception(
            "Subscription data not found.",
          );
        }

        // ==============================================
        // CHECK STATUS
        // ==============================================

        final String status =
            subscriptionData["status"]
                    ?.toString() ??
                "";

        if (status == "Approved") {
          throw Exception(
            "This subscription is already approved.",
          );
        }

        // ==============================================
        // GET OWNER
        // ==============================================

        final String ownerId =
            subscriptionData["ownerId"]
                    ?.toString() ??
                "";

        if (ownerId.isEmpty) {
          throw Exception(
            "Owner ID is missing.",
          );
        }

        // ==============================================
        // GET PLAN
        // ==============================================

        final String plan =
            subscriptionData["plan"]
                    ?.toString() ??
                "";

        final int months =
            getSubscriptionMonths(
          plan,
        );

        // ==============================================
        // GET USER
        // ==============================================

        final userRef =
            _firestore
                .collection("users")
                .doc(ownerId);

        final userSnap =
            await transaction.get(
          userRef,
        );

        // ==============================================
        // CURRENT TIME
        // ==============================================

        final DateTime now =
            DateTime.now();

        DateTime? oldStartDate;
        DateTime? oldEndDate;

        // ==============================================
        // GET EXISTING DATES FROM
        // SUBSCRIPTION DOCUMENT
        // ==============================================

        final startValue =
            subscriptionData[
                "startDate"];

        final endValue =
            subscriptionData[
                "endDate"];

        if (startValue
            is Timestamp) {
          oldStartDate =
              startValue.toDate();
        }

        if (endValue
            is Timestamp) {
          oldEndDate =
              endValue.toDate();
        }

        // ==============================================
        // ALSO CHECK USER DATES
        //
        // This makes the system compatible with
        // existing subscriptions where the dates
        // are stored in users.
        // ==============================================

        if (oldStartDate == null &&
            userSnap.exists) {
          final userData =
              userSnap.data();

          final userStart =
              userData?[
                  "subscriptionStartDate"];

          if (userStart
              is Timestamp) {
            oldStartDate =
                userStart.toDate();
          }
        }

        if (oldEndDate == null &&
            userSnap.exists) {
          final userData =
              userSnap.data();

          final userEnd =
              userData?[
                  "subscriptionEndDate"];

          if (userEnd
              is Timestamp) {
            oldEndDate =
                userEnd.toDate();
          }
        }

        // ==============================================
        // CHECK IF STILL ACTIVE
        // ==============================================

        final bool isStillActive =
            oldEndDate != null &&
                now.isBefore(
                  oldEndDate,
                );

        DateTime newStartDate;
        DateTime newEndDate;

        // ==============================================
        // ACTIVE + ADVANCE PAYMENT
        //
        // KEEP ORIGINAL START DATE
        // EXTEND FROM OLD END DATE
        // ==============================================

        if (isStillActive) {
          newStartDate =
              oldStartDate ?? now;

          newEndDate =
    _addMonths(
  oldEndDate,
  months,
);
        }

        // ==============================================
        // EXPIRED PAYMENT
        //
        // NEW START = NOW
        // NEW END = NOW + PLAN
        // ==============================================

        else {
          newStartDate =
              now;

          newEndDate =
              _addMonths(
            now,
            months,
          );
        }

        // ==============================================
        // UPDATE SUBSCRIPTION DOCUMENT
        // ==============================================

        transaction.update(
          subscriptionRef,
          {
            "status":
                "Approved",

            "subscriptionStatus":
                "Active",

            "startDate":
                Timestamp.fromDate(
              newStartDate,
            ),

            "endDate":
                Timestamp.fromDate(
              newEndDate,
            ),

            "approvedAt":
                FieldValue
                    .serverTimestamp(),
          },
        );

        // ==============================================
        // UPDATE USER DOCUMENT
        // ==============================================

        if (userSnap.exists) {
          transaction.update(
            userRef,
            {
              "hasSubscribed":
                  true,

              "subscriptionStatus":
                  "Active",

              "subscriptionPlan":
                  plan,

              "subscriptionStartDate":
                  Timestamp.fromDate(
                newStartDate,
              ),

              "subscriptionEndDate":
                  Timestamp.fromDate(
                newEndDate,
              ),
            },
          );
        }
      },
    );
  }

  // ============================================================
  // GET ACTIVE SUBSCRIPTION
  // ============================================================

  Future<
          DocumentSnapshot<
              Map<String, dynamic>>?>
      getActiveSubscription(
    String ownerId,
  ) async {
    final snapshot =
        await _firestore
            .collection(
              "subscriptions",
            )
            .where(
              "ownerId",
              isEqualTo: ownerId,
            )
            .where(
              "status",
              isEqualTo: "Approved",
            )
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first;
  }

  // ============================================================
  // CHECK SUBSCRIPTION EXPIRATION
  //
  // Kapag lumampas na sa endDate:
  //
  // subscriptionStatus = Expired
  // hasSubscribed = false
  // ============================================================

  Future<void>
      checkSubscriptionExpiration(
    String ownerId,
  ) async {
    final userRef =
        _firestore
            .collection("users")
            .doc(ownerId);

    final userSnap =
        await userRef.get();

    if (!userSnap.exists) {
      return;
    }

    final data =
        userSnap.data();

    if (data == null) {
      return;
    }

    final endValue =
        data[
            "subscriptionEndDate"];

    if (endValue
        is! Timestamp) {
      return;
    }

    final DateTime endDate =
        endValue.toDate();

    final DateTime now =
        DateTime.now();

    // ==============================================
    // EXPIRED
    // ==============================================

    if (!now.isBefore(endDate)) {
      await userRef.update({
        "subscriptionStatus":
            "Expired",

        "hasSubscribed":
            false,
      });
    }
  }

  // ============================================================
  // CHECK SUBSCRIPTION ALERT
  //
  // DEFAULT:
  // 7 DAYS BEFORE EXPIRATION
  //
  // TRUE = SHOW WARNING ICON
  // FALSE = NO WARNING
  // ============================================================

  Future<bool>
      hasSubscriptionAlert(
    String ownerId, {
    int warningDays = 7,
  }) async {
    final userSnap =
        await _firestore
            .collection("users")
            .doc(ownerId)
            .get();

    if (!userSnap.exists) {
      return false;
    }

    final data =
        userSnap.data();

    if (data == null) {
      return false;
    }

    final endValue =
        data[
            "subscriptionEndDate"];

    if (endValue
        is! Timestamp) {
      return false;
    }

    final DateTime endDate =
        endValue.toDate();

    final DateTime now =
        DateTime.now();

    // ==============================================
    // EXPIRED
    // ==============================================

    if (!now.isBefore(endDate)) {
      return false;
    }

    final Duration remaining =
        endDate.difference(now);

    return remaining.inDays <=
        warningDays;
  }

  // ============================================================
  // GET SUBSCRIPTION DAYS REMAINING
  // ============================================================

  Future<int?>
      getSubscriptionDaysRemaining(
    String ownerId,
  ) async {
    final userSnap =
        await _firestore
            .collection("users")
            .doc(ownerId)
            .get();

    if (!userSnap.exists) {
      return null;
    }

    final data =
        userSnap.data();

    if (data == null) {
      return null;
    }

    final endValue =
        data[
            "subscriptionEndDate"];

    if (endValue
        is! Timestamp) {
      return null;
    }

    final DateTime endDate =
        endValue.toDate();

    final DateTime now =
        DateTime.now();

    if (!now.isBefore(endDate)) {
      return 0;
    }

    return endDate
        .difference(now)
        .inDays;
  }
}