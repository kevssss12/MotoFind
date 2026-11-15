
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationHistoryScreen extends StatelessWidget {
  const ReservationHistoryScreen({super.key});

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";

    final date = timestamp.toDate();

    return "${date.month.toString().padLeft(2, '0')}/"
        "${date.day.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "completed":
        return Colors.green;
      case "expired":
        return Colors.red;
      case "active":
        return Colors.orange;
      case "cancelled":
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case "completed":
        return Icons.check_circle;
      case "expired":
        return Icons.timer_off;
      case "active":
        return Icons.access_time;
      case "cancelled":
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Future<String?> _getProductImageUrl(String productId) async {
    if (productId.isEmpty) return null;

    try {
      final productDoc = await FirebaseFirestore.instance
          .collection("products")
          .doc(productId)
          .get();

      if (!productDoc.exists) return null;

      final data = productDoc.data() as Map<String, dynamic>;
      final imageUrl = data["imageUrl"]?.toString();

      if (imageUrl == null || imageUrl.isEmpty) return null;

      return imageUrl;
    } catch (e) {
      debugPrint("ERROR LOADING PRODUCT IMAGE: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Reservation History"),
        ),
        body: const Center(
          child: Text(
            "Please login first.",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text("Reservation History"),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reservations")
            .where("customerId", isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            debugPrint(
              "RESERVATION HISTORY ERROR: ${snapshot.error}",
            );

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Unable to load reservation history.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final reservations = snapshot.data!.docs.toList();

          reservations.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;

            final dateA = dataA["reservedAt"] is Timestamp
                ? dataA["reservedAt"] as Timestamp
                : Timestamp(0, 0);

            final dateB = dataB["reservedAt"] is Timestamp
                ? dataB["reservedAt"] as Timestamp
                : Timestamp(0, 0);

            return dateB.compareTo(dateA);
          });

          // Isang main container para sa buong Reservation History.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: reservations.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () async {
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                        },
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Icon(
                              Icons.history,
                              size: 70,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 15),
                            Center(
                              child: Text(
                                "No reservation history",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            Center(
                              child: Text(
                                "Your reservations will appear here.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: reservations.length,
                        itemBuilder: (context, index) {
                          final doc = reservations[index];
                          final data =
                              doc.data() as Map<String, dynamic>;

                          final String productId =
                              data["productId"]?.toString() ?? "";

                          final String productName =
                              data["productName"]?.toString() ??
                                  "Unknown Product";

                          final String status =
                              data["status"]?.toString() ?? "Unknown";

                          final Color color = statusColor(status);
                          final IconData icon = statusIcon(status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            color: const Color(0xFFFAFBFD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              leading: FutureBuilder<String?>(
                                future: _getProductImageUrl(productId),
                                builder: (context, imageSnapshot) {
                                  final imageUrl =
                                      imageSnapshot.data;

                                  return Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EFFB),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: imageUrl != null &&
                                            imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Icon(
                                                Icons.motorcycle,
                                                color: Color(0xFF0D47A1),
                                                size: 27,
                                              );
                                            },
                                          )
                                        : const Icon(
                                            Icons.motorcycle,
                                            color: Color(0xFF0D47A1),
                                            size: 27,
                                          ),
                                  );
                                },
                              ),
                              title: Text(
                                productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsets.only(top: 7),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 13,
                                        color: color,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF0D47A1),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ReservationDetailsScreen(
                                      reservationId: doc.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  static Widget _statusMessage(String status) {
    switch (status.toLowerCase()) {
      case "completed":
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Reservation completed.",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

      case "expired":
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.timer_off,
                color: Colors.red,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Reservation expired.",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

      case "active":
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.orange,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Reservation is still active.",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

      case "cancelled":
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.cancel,
                color: Colors.grey,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Reservation cancelled.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class ReservationDetailsScreen extends StatelessWidget {
  final String reservationId;

  const ReservationDetailsScreen({
    super.key,
    required this.reservationId,
  });

  Future<void> _cancelReservation(BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Cancel Reservation?"),
        content: const Text(
          "Are you sure you want to cancel this reservation?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text("Keep Reservation"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final db = FirebaseFirestore.instance;

      final reservationRef =
          db.collection("reservations").doc(reservationId);

      await db.runTransaction((transaction) async {
        final reservationSnapshot =
            await transaction.get(reservationRef);

        if (!reservationSnapshot.exists) {
          throw Exception("Reservation not found.");
        }

        final data = reservationSnapshot.data()!;

        if (data["customerId"] != user.uid) {
          throw Exception(
            "You cannot cancel this reservation.",
          );
        }

        final status = data["status"]?.toString().toLowerCase();

        if (status != "active") {
          throw Exception(
            "Only active reservations can be cancelled.",
          );
        }

        final productId = data["productId"]?.toString() ?? "";
        final quantity = data["quantity"];

        if (productId.isEmpty || quantity is! num) {
          throw Exception("Invalid reservation details.");
        }

        final productRef =
            db.collection("products").doc(productId);

        final productSnapshot =
            await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception(
            "Product not found. Please contact the store owner.",
          );
        }

        final productData = productSnapshot.data()!;
        final stock = productData["stock"];

        if (stock is! num) {
          throw Exception("Invalid product stock.");
        }

        // Panatilihin ang stock restoration behavior.
        transaction.update(productRef, {
          "stock": stock + quantity,
        });

        transaction.update(reservationRef, {
          "status": "cancelled",
          "cancelledAt": FieldValue.serverTimestamp(),
        });
      });

      if (!context.mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to cancel reservation: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text("Reservation Details"),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("reservations")
            .doc(reservationId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            debugPrint(
              "RESERVATION DETAILS ERROR: ${snapshot.error}",
            );

            return const Center(
              child: Text(
                "Unable to load reservation details.",
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Reservation not found."),
            );
          }

          final data = snapshot.data!.data()!;

          if (user == null || data["customerId"] != user.uid) {
            return const Center(
              child: Text(
                "You do not have access to this reservation.",
              ),
            );
          }

          final productId = data["productId"]?.toString() ?? "";

          final productName =
              data["productName"]?.toString() ?? "Unknown Product";

          final customerName =
              data["customerName"]?.toString() ?? "";

          final status = data["status"]?.toString() ?? "Unknown";

          final String reservationNote =
    data["reservationNote"]?.toString() ?? "";

          final paymentProofUrl =
    data["paymentProofUrl"]?.toString() ?? "";

final paymentStatus =
    data["paymentStatus"]?.toString() ?? "Pending";

          final quantity = data["quantity"] is num
              ? (data["quantity"] as num).toInt()
              : 0;

          final price = data["price"] is num
              ? (data["price"] as num).toDouble()
              : 0.0;

          final total = price * quantity;

          final reservedAt = data["reservedAt"] is Timestamp
              ? data["reservedAt"] as Timestamp
              : null;

        

          final color =
              ReservationHistoryScreen().statusColor(status);

          final icon =
              ReservationHistoryScreen().statusIcon(status);

          final canCancel = status.toLowerCase() == "active";

          // Isang main container para sa buong details at button.
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<String?>(
                        future: _getProductImageUrl(productId),
                        builder: (context, imageSnapshot) {
                          final imageUrl = imageSnapshot.data;

                          if (imageUrl == null || imageUrl.isEmpty) {
                            return Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.motorcycle,
                                size: 65,
                                color: Color(0xFF0D47A1),
                              ),
                            );
                          }

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return Container(
                                  height: 150,
                                  color: Colors.grey.shade100,
                                  child: const Icon(
                                    Icons.motorcycle,
                                    size: 60,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 17, color: color),
                              const SizedBox(width: 6),
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(height: 28),

                      if (customerName.isNotEmpty)
                        ReservationHistoryScreen._infoRow(
                          Icons.person,
                          "Customer",
                          customerName,
                        ),

                      ReservationHistoryScreen._infoRow(
                        Icons.shopping_cart,
                        "Quantity",
                        "$quantity",
                      ),

                      ReservationHistoryScreen._infoRow(
                        Icons.payments,
                        "Price",
                        "₱${price.toStringAsFixed(2)}",
                      ),

                      ReservationHistoryScreen._infoRow(
                        Icons.calculate,
                        "Total",
                        "₱${total.toStringAsFixed(2)}",
                      ),

                      ReservationHistoryScreen._infoRow(
                        Icons.calendar_today,
                        "Reserved",
                        _formatDate(reservedAt),
                      ),


                      const SizedBox(height: 8),

                      ReservationHistoryScreen._statusMessage(status),

        
ReservationHistoryScreen._statusMessage(status),

// CUSTOMER RESERVATION NOTE
if (reservationNote.trim().isNotEmpty) ...[
  const SizedBox(height: 20),

  const Text(
    "Customer Note",
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 10),

  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE8EFFB),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFBBDEFB),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.note_alt_outlined,
          color: Color(0xFF0D47A1),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            reservationNote,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF263238),
            ),
          ),
        ),
      ],
    ),
  ),
],

const SizedBox(height: 20),

const Text(
  "Payment Information",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 10),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: const Color(0xFFF5F8FC),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade200),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            color: Color(0xFF0D47A1),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Payment Verification",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            child: Text(
              paymentStatus.toUpperCase(),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: paymentStatus.toLowerCase() == "verified" ||
                        paymentStatus.toLowerCase() == "approved" ||
                        paymentStatus.toLowerCase() == "paid"
                    ? Colors.green
                    : Colors.orange.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 14),

      if (paymentProofUrl.isNotEmpty) ...[
        const Text(
          "Uploaded Payment Screenshot",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (dialogContext) => Dialog(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: InteractiveViewer(
                        child: Image.network(
                          paymentProofUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(
                            height: 180,
                            child: Center(
                              child: Text(
                                "Unable to load payment screenshot.",
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              paymentProofUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                height: 120,
                alignment: Alignment.center,
                color: Colors.grey.shade200,
                child: const Text(
                  "Unable to load payment screenshot.",
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          "Tap the screenshot to view it larger.",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ] else
        const Text(
          "No payment screenshot was found for this reservation.",
          style: TextStyle(color: Colors.grey),
        ),
    ],
  ),
),

if (canCancel) ...[
 
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _cancelReservation(context);
                            },
                            icon: const Icon(
                              Icons.cancel_outlined,
                            ),
                            label: const Text(
                              "Cancel Reservation",
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(
                                color: Colors.red,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";

    final date = timestamp.toDate();

    return "${date.month.toString().padLeft(2, '0')}/"
        "${date.day.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  Future<String?> _getProductImageUrl(String productId) async {
    if (productId.isEmpty) return null;

    try {
      final productDoc = await FirebaseFirestore.instance
          .collection("products")
          .doc(productId)
          .get();

      if (!productDoc.exists) return null;

      final data = productDoc.data()!;
      final imageUrl = data["imageUrl"]?.toString();

      if (imageUrl == null || imageUrl.isEmpty) return null;

      return imageUrl;
    } catch (e) {
      debugPrint("ERROR LOADING PRODUCT IMAGE: $e");
      return null;
    }
  }
}