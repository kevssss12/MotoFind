import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservedOrdersScreen extends StatefulWidget {
  const ReservedOrdersScreen({super.key});

  @override
  State<ReservedOrdersScreen> createState() =>
      _ReservedOrdersScreenState();
}

class _ReservedOrdersScreenState
    extends State<ReservedOrdersScreen> {
  final FirestoreService firestoreService =
      FirestoreService();

  final TextEditingController searchController =
      TextEditingController();

  String? storeId;
  String searchQuery = "";

  final Map<String, String> customerProfileImages = {};

 
@override
void initState() {
  super.initState();

  getStoreId();

  searchController.addListener(() {
    if (!mounted) return;

    setState(() {
      searchQuery =
          searchController.text.trim().toLowerCase();
    });
  });
}

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // GET STORE ID
  // =========================================================

  Future<void> getStoreId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return;
      }

      final data = userDoc.data();

      if (data == null) {
        return;
      }

      final fetchedStoreId =
          data["storeId"]?.toString().trim();

      if (fetchedStoreId == null ||
          fetchedStoreId.isEmpty) {
        return;
      }

      if (!mounted) return;

      setState(() {
        storeId = fetchedStoreId;
      });
    } catch (e) {
      debugPrint(
        "ERROR GETTING STORE ID: $e",
      );
    }
  }

  // =========================================================
  // COMPLETE RESERVATION
  // =========================================================

  Future<void> completeReservation(
    String reservationId,
  ) async {
    try {
      await firestoreService.completeReservation(
        reservationId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Reservation completed successfully.",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to complete reservation: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // GET CUSTOMER PROFILE IMAGE
  // =========================================================

  Future<String?> getCustomerProfileImage(
    String customerId,
    String customerName,
  ) async {
    try {
      final cleanCustomerId =
          customerId.trim();

      final cleanCustomerName =
          customerName.trim();

      if (cleanCustomerId.isEmpty) {
        return null;
      }

      // =====================================================
      // CHECK CACHE FIRST
      // =====================================================

      if (customerProfileImages.containsKey(
        cleanCustomerId,
      )) {
        final cachedImage =
            customerProfileImages[cleanCustomerId];

        if (cachedImage != null &&
            cachedImage.isNotEmpty) {
          return cachedImage;
        }
      }

      // =====================================================
      // GET USER USING CUSTOMER UID
      // =====================================================

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(cleanCustomerId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();

        if (data != null) {
          final imageUrl =
              data["profileImageUrl"]
                      ?.toString()
                      .trim() ??
                  "";

          if (imageUrl.isNotEmpty) {
            customerProfileImages[
                    cleanCustomerId] =
                imageUrl;

            debugPrint(
              "CUSTOMER PROFILE IMAGE FOUND: "
              "$cleanCustomerId",
            );

            return imageUrl;
          }
        }
      }

      // =====================================================
      // FALLBACK: SEARCH BY CUSTOMER NAME
      // =====================================================

      if (cleanCustomerName.isNotEmpty) {
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection("users")
                .where(
                  "fullName",
                  isEqualTo: cleanCustomerName,
                )
                .limit(10)
                .get();

        for (final doc in querySnapshot.docs) {
          final data = doc.data();

          final imageUrl =
              data["profileImageUrl"]
                      ?.toString()
                      .trim() ??
                  "";

          if (imageUrl.isNotEmpty) {
            customerProfileImages[
                    cleanCustomerId] =
                imageUrl;

            debugPrint(
              "CUSTOMER PROFILE IMAGE FOUND BY NAME: "
              "$cleanCustomerName",
            );

            return imageUrl;
          }
        }
      }
    } catch (e) {
      debugPrint(
        "ERROR GETTING CUSTOMER PROFILE IMAGE: $e",
      );
    }

    debugPrint(
      "NO CUSTOMER PROFILE IMAGE: $customerId",
    );

    return null;
  }

  // =========================================================
  // GET PRODUCT IMAGE
  // =========================================================
  //
  // Reservation document contains:
  //
  // productId
  // productName
  //
  // We use productId to get the actual product document
  // from the products collection and retrieve imageUrl.
  //
  // =========================================================

  Future<String?> getProductImage(
    String productId,
  ) async {
    try {
      final cleanProductId =
          productId.trim();

      if (cleanProductId.isEmpty) {
        return null;
      }

      final productDoc =
          await FirebaseFirestore.instance
              .collection("products")
              .doc(cleanProductId)
              .get();

      if (!productDoc.exists) {
        debugPrint(
          "PRODUCT NOT FOUND: $cleanProductId",
        );

        return null;
      }

      final data =
          productDoc.data();

      if (data == null) {
        return null;
      }

      final imageUrl =
          data["imageUrl"]
                  ?.toString()
                  .trim() ??
              "";

      if (imageUrl.isNotEmpty) {
        debugPrint(
          "PRODUCT IMAGE FOUND: "
          "$cleanProductId",
        );

        return imageUrl;
      }
    } catch (e) {
      debugPrint(
        "ERROR GETTING PRODUCT IMAGE: $e",
      );
    }

    debugPrint(
      "NO PRODUCT IMAGE: $productId",
    );

    return null;
  }

  // =========================================================
  // CUSTOMER PROFILE AVATAR
  // =========================================================

  Widget buildCustomerProfileAvatar(
    String customerId,
    String customerName,
    double radius,
  ) {
    return FutureBuilder<String?>(
      future: getCustomerProfileImage(
        customerId,
        customerName,
      ),
      builder: (
        context,
        snapshot,
      ) {
        // ===================================================
        // LOADING
        // ===================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return CircleAvatar(
            radius: radius,
            backgroundColor:
                Colors.grey.shade200,
            child: SizedBox(
              width: radius * 0.65,
              height: radius * 0.65,
              child:
                  const CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        }

        // ===================================================
        // PROFILE IMAGE
        // ===================================================

        final imageUrl =
            snapshot.data?.trim() ?? "";

        if (imageUrl.isNotEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundColor:
                Colors.grey.shade200,
            backgroundImage:
                NetworkImage(imageUrl),
          );
        }

        // ===================================================
        // DEFAULT PROFILE ICON
        // ===================================================

        return CircleAvatar(
          radius: radius,
          backgroundColor:
              Colors.blue.shade100,
          child: Icon(
            Icons.person,
            size: radius * 1.1,
            color: Colors.blue.shade700,
          ),
        );
      },
    );
  }

  // =========================================================
  // GET STATUS COLOR
  // =========================================================

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.orange;

      case "completed":
        return Colors.green;

      case "expired":
        return Colors.red;

      case "cancelled":
        return Colors.grey;

      default:
        return Colors.blue;
    }
  }

  // =========================================================
  // GET STATUS BACKGROUND
  // =========================================================

  Color getStatusBackgroundColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.orange.shade50;

      case "completed":
        return Colors.green.shade50;

      case "expired":
        return Colors.red.shade50;

      case "cancelled":
        return Colors.grey.shade100;

      default:
        return Colors.blue.shade50;
    }
  }

  // =========================================================
  // GET DATE VALUE FROM FIRESTORE
  //
  // IMPORTANT:
  // This handles:
  // Timestamp
  // DateTime
  // String date
  //
  // Primary field = createdAt
  // =========================================================

  DateTime getReservationDate(
    QueryDocumentSnapshot reservation,
  ) {
    final data =
        reservation.data()
            as Map<String, dynamic>;

    final value = data["createdAt"];

    // ---------------------------------------------------------
    // FIRESTORE TIMESTAMP
    // ---------------------------------------------------------

    if (value is Timestamp) {
      return value.toDate();
    }

    // ---------------------------------------------------------
    // DATETIME
    // ---------------------------------------------------------

    if (value is DateTime) {
      return value;
    }

    // ---------------------------------------------------------
    // STRING DATE
    // ---------------------------------------------------------

    if (value is String) {
      final parsed =
          DateTime.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    // ---------------------------------------------------------
    // FALLBACK FIELDS
    // ---------------------------------------------------------

    final fallbackFields = [
      "reservedAt",
      "reservationDate",
      "timestamp",
      "date",
    ];

    for (final field in fallbackFields) {
      final fallbackValue = data[field];

      if (fallbackValue is Timestamp) {
        return fallbackValue.toDate();
      }

      if (fallbackValue is DateTime) {
        return fallbackValue;
      }

      if (fallbackValue is String) {
        final parsed =
            DateTime.tryParse(fallbackValue);

        if (parsed != null) {
          return parsed;
        }
      }
    }

    // ---------------------------------------------------------
    // NO DATE
    // ---------------------------------------------------------

    return DateTime(2000);
  }

  // =========================================================
  // GET LATEST DATE OF CUSTOMER
  // =========================================================

  DateTime getLatestReservationDate(
    List<QueryDocumentSnapshot> reservations,
  ) {
    DateTime latest = DateTime(2000);

    for (final reservation in reservations) {
      final date =
          getReservationDate(reservation);

      if (date.isAfter(latest)) {
        latest = date;
      }
    }

    return latest;
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String formatDate(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, "0");

    final period =
        date.hour >= 12 ? "PM" : "AM";

    return "${date.month}/${date.day}/${date.year} "
        "$hour:$minute $period";
  }

  // =========================================================
  // SORT RESERVATIONS LATEST FIRST
  // =========================================================

  void sortReservationsLatestFirst(
    List<QueryDocumentSnapshot> reservations,
  ) {
    reservations.sort(
      (a, b) {
        final dateA =
            getReservationDate(a);

        final dateB =
            getReservationDate(b);

        return dateB.compareTo(dateA);
      },
    );
  }

  // =========================================================
  // SHOW CUSTOMER HISTORY
  // =========================================================

  void showCustomerReservationHistory(
    String customerId,
    String customerName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 25,
          ),
          child: SizedBox(
            width: 700,
            height:
                MediaQuery.of(context).size.height *
                    0.85,
            child: Column(
              children: [
                // =====================================================
                // HEADER
                // =====================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color:
                        Colors.blue.shade700,
                    borderRadius:
                        const BorderRadius.only(
                      topLeft:
                          Radius.circular(12),
                      topRight:
                          Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      buildCustomerProfileAvatar(
                        customerId,
                        customerName,
                        28,
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              "Customer Reservation History",
                              style: TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              customerName,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                        icon: const Icon(
                          Icons.close,
                          color:
                              Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // =====================================================
                // HISTORY
                // =====================================================

                Expanded(
                  child:
                      StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore
                            .instance
                            .collection(
                              "reservations",
                            )
                            .where(
                              "storeId",
                              isEqualTo:
                                  storeId,
                            )
                            .snapshots(),
                    builder: (
                      context,
                      snapshot,
                    ) {
                      if (snapshot
                              .connectionState ==
                          ConnectionState
                              .waiting) {
                        return const Center(
                          child:
                              CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(20),
                            child: Text(
                              "Error loading reservations:\n${snapshot.error}",
                              textAlign:
                                  TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final docs =
                          snapshot.data?.docs ??
                              [];

                      // =================================================
                      // FILTER USING CUSTOMER ID
                      // =================================================

                      final customerReservations =
                          docs.where((doc) {
                        final data =
                            doc.data()
                                as Map<String,
                                    dynamic>;

                        final id =
                            data["customerId"]
                                ?.toString()
                                .trim();

                        return id ==
                            customerId;
                      }).toList();

                      // =================================================
                      // LATEST FIRST
                      // =================================================

                      sortReservationsLatestFirst(
                        customerReservations,
                      );

                      if (customerReservations
                          .isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 60,
                                color:
                                    Colors.grey,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "No reservation history found.",
                                style: TextStyle(
                                  color:
                                      Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding:
                            const EdgeInsets.all(
                          15,
                        ),
                        itemCount:
                            customerReservations
                                .length,
                        itemBuilder: (
                          context,
                          index,
                        ) {
                          return buildHistoryCard(
                            customerReservations[
                                index],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // HISTORY CARD
  // =========================================================

  Widget buildHistoryCard(
    QueryDocumentSnapshot reservation,
  ) {
    final data =
        reservation.data()
            as Map<String, dynamic>;

    final productName =
        data["productName"]
            ?.toString() ??
        "Unknown Product";

    // =========================================================
    // PRODUCT ID
    // =========================================================
    //
    // Example from your reservation:
    //
    // productId = "IhLjz5j0VGizI4GccjEp"
    //
    // This will be used to get the product image.
    // =========================================================

    final productId =
        data["productId"]
            ?.toString()
            .trim() ??
        "";

    final status =
        data["status"]
            ?.toString() ??
        "Unknown";

        final reservationNote =
    data["reservationNote"]
        ?.toString()
        .trim() ??
    "";

final paymentProofUrl =
    data["paymentProofUrl"]?.toString().trim() ?? "";

final paymentStatus =
    data["paymentStatus"]?.toString().trim() ?? "Pending";
    final quantity =
        data["quantity"] ?? 0;

    final price =
        data["price"] ?? 0;

    final total =
        (double.tryParse(
              price.toString(),
            ) ??
            0) *
        (double.tryParse(
              quantity.toString(),
            ) ??
            0);

    final createdAt =
        getReservationDate(reservation);

    final statusColor =
        getStatusColor(status);

    final statusBackground =
        getStatusBackgroundColor(status);

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =====================================================
            // PRODUCT
            // =====================================================

          
LayoutBuilder(
  builder: (context, constraints) {
    final isNarrow = constraints.maxWidth < 360;

    Widget productImage = FutureBuilder<String?>(
      future: getProductImage(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final imageUrl = snapshot.data?.trim() ?? '';

        if (imageUrl.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey.shade600,
                    size: 30,
                  ),
                );
              },
            ),
          );
        }

        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.motorcycle,
            color: Colors.blue.shade700,
            size: 30,
          ),
        );
      },
    );

    Widget productTitle = Text(
      productName,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );

    Widget statusBadge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              productImage,
              const SizedBox(width: 12),
              Expanded(child: productTitle),
            ],
          ),
          const SizedBox(height: 8),
          statusBadge,
        ],
      );
    }

    return Row(
      children: [
        productImage,
        const SizedBox(width: 12),
        Expanded(child: productTitle),
        const SizedBox(width: 8),
        Flexible(child: statusBadge),
      ],
    );
  },
),

            const SizedBox(
              height: 15,
            ),

            // =====================================================
            // DETAILS
            // =====================================================

            detailRow(
              Icons.confirmation_number,
              "Reservation ID",
              reservation.id,
            ),

            detailRow(
              Icons.shopping_cart,
              "Quantity",
              quantity.toString(),
            ),

            detailRow(
              Icons.payments,
              "Price",
              "₱${price.toString()}",
            ),

            detailRow(
              Icons.calculate,
              "Total",
              "₱${total.toStringAsFixed(2)}",
            ),

            detailRow(
              Icons.access_time,
              "Reserved",
              formatDate(createdAt),
            ),
              // =====================================================
// CUSTOMER NOTE
// =====================================================

if (reservationNote.isNotEmpty) ...[
  const SizedBox(height: 8),

  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Colors.blue.shade200,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notes,
              color: Colors.blue.shade700,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              "Customer Note",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SelectableText(
          reservationNote,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  ),
],
// =====================================================
// CUSTOMER PAYMENT PROOF
// =====================================================

const SizedBox(height: 12),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.orange.shade50,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: Colors.orange.shade200,
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(
            Icons.receipt_long,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "GCash Payment Proof",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),

      Text(
        "Payment Status: $paymentStatus",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.orange.shade900,
        ),
      ),

      const SizedBox(height: 10),

      if (paymentProofUrl.isNotEmpty)
        Center(
          child: InkWell(
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) {
                  return Dialog(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: InteractiveViewer(
                        child: Image.network(
                          paymentProofUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (
                            context,
                            child,
                            progress,
                          ) {
                            if (progress == null) {
                              return child;
                            }

                            return const SizedBox(
                              height: 250,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "Unable to load payment screenshot.",
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                paymentProofUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.contain,
                loadingBuilder: (
                  context,
                  child,
                  progress,
                ) {
                  if (progress == null) {
                    return child;
                  }

                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      "Unable to load payment screenshot.",
                    ),
                  );
                },
              ),
            ),
          ),
        )
      else
        const Text(
          "No payment screenshot found for this reservation.",
          style: TextStyle(color: Colors.red),
        ),

      if (paymentProofUrl.isNotEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            "Tap the image to enlarge it.",
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ),
    ],
  ),
),

            // =====================================================
            // COMPLETE SALE
            // =====================================================

           
if (status.toLowerCase() == "active") ...[
  const SizedBox(height: 10),

  Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text("Cancel Reservation"),
                content: const Text(
                  "Are you sure you want to cancel this reservation? "
                  "The reserved stock will be returned.",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text("No"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Yes, Cancel"),
                  ),
                ],
              ),
            );

            if (confirmed != true) return;

            try {
              await firestoreService.cancelReservation(
                reservation.id,
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Reservation cancelled successfully.",
                  ),
                ),
              );
            } catch (e) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Failed to cancel reservation: $e",
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.cancel_outlined),
          label: const Text("Cancel"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
          ),
        ),
      ),

      const SizedBox(width: 8),

      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            completeReservation(reservation.id);
          },
          icon: const Icon(Icons.check_circle),
          label: const Text("Complete Sale"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    ],
  ),
],

            // =====================================================
            // COMPLETED
            // =====================================================

            if (status.toLowerCase() ==
                "completed") ...[
              const SizedBox(
                height: 10,
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  10,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.green.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color:
                          Colors.green,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        "This reservation has been completed.",
                        style: TextStyle(
                          color:
                              Colors.green,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // =====================================================
            // EXPIRED
            // =====================================================

            if (status.toLowerCase() ==
                "expired") ...[
              const SizedBox(
                height: 10,
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  10,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.timer_off,
                      color: Colors.red,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        "This reservation has expired.",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DETAIL ROW
  // =========================================================

 
  Widget detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 105,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SEARCH BAR
  // =========================================================

  Widget buildSearchBar() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        10,
      ),
      child: TextField(
        controller:
            searchController,
        decoration:
            InputDecoration(
          hintText:
              "Search customer name...",
          prefixIcon:
              const Icon(
            Icons.search,
          ),
          suffixIcon:
              searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        searchController
                            .clear();
                      },
                      icon:
                          const Icon(
                        Icons.clear,
                      ),
                    )
                  : null,
          filled: true,
          fillColor:
              Colors.grey.shade100,
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            borderSide:
                BorderSide.none,
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            borderSide:
                BorderSide.none,
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            borderSide:
                BorderSide(
              color:
                  Colors.blue.shade600,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CUSTOMER CARD
  // =========================================================

  Widget buildCustomerCard(
    String customerId,
    List<QueryDocumentSnapshot>
        customerReservations,
  ) {
    if (customerReservations.isEmpty) {
      return const SizedBox();
    }

    // =======================================================
    // SORT CUSTOMER RESERVATIONS FIRST
    // =======================================================

    sortReservationsLatestFirst(
      customerReservations,
    );

    // =======================================================
    // FIRST = LATEST RESERVATION
    // =======================================================

    final latestReservation =
        customerReservations.first;

    final latestData =
        latestReservation.data()
            as Map<String, dynamic>;

    final customerName =
        latestData["customerName"]
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? latestData["customerName"]
            .toString()
        : "Unknown Customer";

    // =======================================================
    // LATEST DATE
    // =======================================================

    final latestDate =
        getReservationDate(
      latestReservation,
    );

    // =======================================================
    // STATUS COUNTS
    // =======================================================

    int activeCount = 0;
    int completedCount = 0;
    int expiredCount = 0;

    for (final reservation
        in customerReservations) {
      final data =
          reservation.data()
              as Map<String, dynamic>;

      final status =
          data["status"]
              ?.toString()
              .toLowerCase()
              .trim();

      if (status == "active") {
        activeCount++;
      } else if (status == "completed") {
        completedCount++;
      } else if (status == "expired") {
        expiredCount++;
      }
    }

    // =======================================================
    // BORDER COLOR
    // =======================================================

    Color borderColor =
        Colors.blue.shade200;

    if (activeCount > 0) {
      borderColor =
          Colors.orange.shade300;
    } else if (completedCount > 0) {
      borderColor =
          Colors.green.shade300;
    } else if (expiredCount > 0) {
      borderColor =
          Colors.red.shade300;
    }

    // =======================================================
    // CUSTOMER CARD
    // =======================================================

    return Card(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 6,
      ),
      elevation: 2,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        side: BorderSide(
          color: borderColor,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        onTap: () {
          showCustomerReservationHistory(
            customerId,
            customerName,
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(
            14,
          ),
          child: Row(
            children: [
              // =================================================
              // PROFILE
              // =================================================

              buildCustomerProfileAvatar(
                customerId,
                customerName,
                30,
              ),

              const SizedBox(
                width: 13,
              ),

              // =================================================
              // CUSTOMER INFO
              // =================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      "${customerReservations.length} "
                      "reservation"
                      "${customerReservations.length == 1 ? '' : 's'}",
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    // =================================================
                    // LATEST DATE
                    // =================================================

                  
Row(
  children: [
    Icon(
      Icons.access_time,
      size: 14,
      color: Colors.grey.shade600,
    ),
    const SizedBox(width: 4),
    Expanded(
      child: Text(
        "Latest: ${formatDate(latestDate)}",
        maxLines: 2,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ],
),


                    const SizedBox(
                      height: 8,
                    ),

                    // =================================================
                    // STATUS
                    // =================================================

                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        if (activeCount > 0)
                          _buildStatusChip(
                            "Active $activeCount",
                            Colors.orange,
                          ),

                        if (completedCount > 0)
                          _buildStatusChip(
                            "Completed $completedCount",
                            Colors.green,
                          ),

                        if (expiredCount > 0)
                          _buildStatusChip(
                            "Expired $expiredCount",
                            Colors.red,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Icon(
                Icons.chevron_right,
                color:
                    Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // STATUS CHIP
  // =========================================================

  Widget _buildStatusChip(
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(0.10),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0D47A1);
    const Color darkBlue = Color(0xFF062B63);
    const Color pageBackground = Color(0xFFF5F8FC);
    const Color containerColor = Color.fromARGB(255, 209, 209, 238);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Menu',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Reserved Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 1100),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE1E8F0)),
              boxShadow: [
                BoxShadow(
                  color: darkBlue.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // RESERVED ORDERS HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: primaryBlue,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reserved Orders',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkBlue,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Manage customer reservations and payment details.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // SEARCH FIELD
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search customer name...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: primaryBlue,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: searchController.clear,
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      filled: true,
                      fillColor: pageBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE1E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const Divider(
                  height: 1,
                  color: Color(0xFFE8EDF4),
                ),

                // RESERVATION CONTENT
                Expanded(
                  child: storeId == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: primaryBlue,
                          ),
                        )
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('reservations')
                              .where('storeId', isEqualTo: storeId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: primaryBlue,
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'Error loading reservations:\n${snapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }

                            final allReservations =
                                snapshot.data?.docs ?? [];

                            if (allReservations.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.event_available,
                                        size: 60,
                                        color: Colors.blueGrey,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No reservations yet.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: darkBlue,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // GROUP RESERVATIONS BY CUSTOMER
                            final Map<String, List<QueryDocumentSnapshot>>
                                groupedCustomers = {};

                            for (final reservation in allReservations) {
                              final data = reservation.data()
                                  as Map<String, dynamic>;

                              final customerId =
                                  data['customerId']?.toString().trim() ??
                                      '';

                              if (customerId.isEmpty) continue;

                              groupedCustomers.putIfAbsent(
                                customerId,
                                () => [],
                              ).add(reservation);
                            }

                            for (final entry in groupedCustomers.entries) {
                              sortReservationsLatestFirst(entry.value);
                            }

                            // FILTER CUSTOMERS
                            final filteredCustomers =
                                groupedCustomers.entries.where((entry) {
                              if (searchQuery.isEmpty) return true;
                              if (entry.value.isEmpty) return false;

                              final data = entry.value.first.data()
                                  as Map<String, dynamic>;

                              final customerName =
                                  data['customerName']
                                          ?.toString()
                                          .toLowerCase() ??
                                      '';

                              return customerName.contains(searchQuery);
                            }).toList();

                            // SORT LATEST CUSTOMERS FIRST
                            filteredCustomers.sort((a, b) {
                              return getLatestReservationDate(b.value)
                                  .compareTo(
                                getLatestReservationDate(a.value),
                              );
                            });

                            if (filteredCustomers.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.search_off_rounded,
                                        size: 58,
                                        color: Colors.blueGrey,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'No customer found',
                                        style: TextStyle(
                                          color: darkBlue,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Try searching with another name.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (searchQuery.isNotEmpty)
                                        TextButton.icon(
                                          onPressed: searchController.clear,
                                          icon: const Icon(Icons.clear),
                                          label: const Text('Clear search'),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // RESULT COUNT
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20, 15, 20, 5,
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Customer Reservations',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: darkBlue,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryBlue.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${filteredCustomers.length} ${filteredCustomers.length == 1 ? 'customer' : 'customers'}',
                                          style: const TextStyle(
                                            color: primaryBlue,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // CUSTOMER LIST
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      16, 10, 16, 20,
                                    ),
                                    itemCount: filteredCustomers.length,
                                    itemBuilder: (context, index) {
                                      final entry = filteredCustomers[index];

                                      return buildCustomerCard(
                                        entry.key,
                                        entry.value,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}