
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubscriptionApprovalScreen extends StatelessWidget {
  const SubscriptionApprovalScreen({
    super.key,
  });

  // ============================================================
  // ADD MONTHS SAFELY
  // ============================================================

  DateTime _addMonths(
    DateTime date,
    int months,
  ) {
    final int year =
        date.year +
            ((date.month - 1 + months) ~/ 12);

    final int month =
        ((date.month - 1 + months) % 12) + 1;

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
  // GET PLAN MONTHS
  // ============================================================

  int _getPlanMonths(
    String plan,
  ) {
    switch (plan.toLowerCase().trim()) {
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
  // APPROVE SUBSCRIPTION
  // ============================================================

  Future<void> _approveSubscription(
    BuildContext context,
    DocumentSnapshot subscription,
  ) async {
    try {
      final data =
          subscription.data()
              as Map<String, dynamic>;

      final String ownerId =
          data["ownerId"]?.toString() ?? "";

      final String plan =
          data["plan"]?.toString() ?? "";

      if (ownerId.isEmpty) {
        throw Exception(
          "Owner ID is missing.",
        );
      }

      if (plan.isEmpty) {
        throw Exception(
          "Subscription plan is missing.",
        );
      }

      final int months =
          _getPlanMonths(plan);

      final firestore =
          FirebaseFirestore.instance;

      final subscriptionRef =
          firestore
              .collection("subscriptions")
              .doc(subscription.id);

      final userRef =
          firestore
              .collection("users")
              .doc(ownerId);

      // ========================================================
      // TRANSACTION
      // ========================================================

      await firestore.runTransaction(
        (transaction) async {
          // ======================================================
          // GET SUBSCRIPTION AGAIN
          // ======================================================

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
              subscriptionSnap.data()
                  as Map<String, dynamic>;

          final currentStatus =
              subscriptionData["status"]
                      ?.toString() ??
                  "";

          if (currentStatus == "Approved") {
            throw Exception(
              "This subscription is already approved.",
            );
          }

          // ======================================================
          // GET USER
          // ======================================================

          final userSnap =
              await transaction.get(
            userRef,
          );

          if (!userSnap.exists) {
            throw Exception(
              "Store owner account not found.",
            );
          }

          final userData =
              userSnap.data()
                  as Map<String, dynamic>;

          // ======================================================
          // CURRENT DATE
          // ======================================================

          final DateTime now =
              DateTime.now();

          // ======================================================
          // GET EXISTING START DATE
          // ======================================================

          DateTime? oldStartDate;

          final existingStart =
              userData[
                  "subscriptionStartDate"];

          if (existingStart
              is Timestamp) {
            oldStartDate =
                existingStart.toDate();
          }

          // ======================================================
          // GET EXISTING END DATE
          // ======================================================

          DateTime? oldEndDate;

          final existingEnd =
              userData[
                  "subscriptionEndDate"];

          if (existingEnd
              is Timestamp) {
            oldEndDate =
                existingEnd.toDate();
          }

          // ======================================================
          // ALSO CHECK SUBSCRIPTION DOCUMENT
          //
          // Para compatible sa existing data.
          // ======================================================

          if (oldStartDate == null) {
            final subscriptionStart =
                subscriptionData[
                    "startDate"];

            if (subscriptionStart
                is Timestamp) {
              oldStartDate =
                  subscriptionStart.toDate();
            }
          }

          if (oldEndDate == null) {
            final subscriptionEnd =
                subscriptionData[
                    "endDate"];

            if (subscriptionEnd
                is Timestamp) {
              oldEndDate =
                  subscriptionEnd.toDate();
            }
          }

          // ======================================================
          // CHECK IF ACTIVE
          //
          // IMPORTANT:
          // Kung hindi pa expired ang old subscription,
          // advance payment ito.
          // ======================================================

          final bool isStillActive =
              oldEndDate != null &&
                  now.isBefore(
                    oldEndDate,
                  );

          DateTime newStartDate;
          DateTime newEndDate;

          // ======================================================
          // ACTIVE SUBSCRIPTION
          //
          // ADVANCE PAYMENT
          //
          // START DATE:
          // KEEP ORIGINAL START DATE
          //
          // END DATE:
          // OLD END DATE + NEW PLAN
          // ======================================================

          if (isStillActive) {
            newStartDate =
                oldStartDate ?? now;

            newEndDate =
                _addMonths(
              oldEndDate,
              months,
            );
          }

          // ======================================================
          // EXPIRED / NO EXISTING SUBSCRIPTION
          //
          // START DATE = NOW
          // END DATE = NOW + PLAN
          // ======================================================

          else {
            newStartDate =
                now;

            newEndDate =
                _addMonths(
              now,
              months,
            );
          }

          // ======================================================
          // APPROVE SUBSCRIPTION DOCUMENT
          // ======================================================

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
                  FieldValue.serverTimestamp(),

              "approvedBy":
                  "Admin",

              "advancePayment":
                  isStillActive,
            },
          );

          // ======================================================
          // UPDATE USER
          // ======================================================

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
        },
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Subscription Approved successfully.",
          ),
          backgroundColor:
              Colors.green,
        ),
      );
    } catch (e) {
      // ========================================================
      // ERROR
      // ========================================================

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Approval failed: $e",
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // REJECT SUBSCRIPTION
  // ============================================================

  Future<void> _rejectSubscription(
    BuildContext context,
    String subscriptionId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection("subscriptions")
          .doc(subscriptionId)
          .update({
        "status": "Rejected",

        "rejectedAt":
            FieldValue.serverTimestamp(),
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Subscription Rejected.",
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Rejection failed: $e",
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    Timestamp? timestamp,
  ) {
    if (timestamp == null) {
      return "Not available";
    }

    final date =
        timestamp.toDate();

    return "${date.month.toString().padLeft(2, '0')}/"
        "${date.day.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Subscription Payments",
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<
          QuerySnapshot>(
        stream: FirebaseFirestore
            .instance
            .collection(
              "subscriptions",
            )
            .where(
              "status",
              isEqualTo: "Pending",
            )
            .orderBy(
              "createdAt",
              descending: true,
            )
            .snapshots(),

        builder:
            (context, snapshot) {
          // ======================================================
          // LOADING
          // ======================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          // ======================================================
          // ERROR
          // ======================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child: Text(
                  "Error loading subscriptions:\n${snapshot.error}",
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          // ======================================================
          // NO DATA
          // ======================================================

          if (!snapshot.hasData ||
              snapshot
                  .data!
                  .docs
                  .isEmpty) {
            return const Center(
              child: Text(
                "No Pending Subscription",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            );
          }

          final subscriptions =
              snapshot.data!.docs;

          // ======================================================
          // LIST
          // ======================================================

          return ListView.builder(
            padding:
                const EdgeInsets.all(
              10,
            ),

            itemCount:
                subscriptions.length,

            itemBuilder:
                (context, index) {
              final subscription =
                  subscriptions[index];

              final data =
                  subscription.data()
                      as Map<String, dynamic>;

              final String plan =
                  data["plan"]
                          ?.toString() ??
                      "Unknown";

              final String ownerName =
                  data["ownerName"]
                          ?.toString() ??
                      "Unknown Owner";

              final String storeName =
                  data["storeName"]
                          ?.toString() ??
                      "Unknown Store";

              final String amount =
                  data["amount"]
                          ?.toString() ??
                      "0";

              final String? imageUrl =
                  data["paymentImageUrl"]
                      ?.toString();

              final Timestamp?
                  oldEndDate =
                  data["endDate"]
                      is Timestamp
                      ? data["endDate"]
                          as Timestamp
                      : null;

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),

                elevation: 3,

                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ==================================================
                      // STORE
                      // ==================================================

                      Text(
                        storeName,
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        "Owner: $ownerName",
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // ==================================================
                      // PLAN
                      // ==================================================

                      Text(
                        "Plan: $plan",
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        "Amount: ₱$amount",
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // ==================================================
                      // ADVANCE PAYMENT INFO
                      // ==================================================

                      if (oldEndDate != null)
                        Container(
                          width:
                              double.infinity,

                          padding:
                              const EdgeInsets.all(
                            10,
                          ),

                          decoration:
                              BoxDecoration(
                            color: Colors
                                .orange
                                .withValues(
                              alpha: 0.12,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              8,
                            ),
                          ),

                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              const Icon(
                                Icons
                                    .info_outline,
                                color:
                                    Colors.orange,
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              Expanded(
                                child: Text(
                                  "Existing subscription end date: "
                                  "${_formatDate(oldEndDate)}\n"
                                  "If still active, this payment will be added after that date.",
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ==================================================
                      // PAYMENT IMAGE
                      // ==================================================

                      if (imageUrl != null &&
                          imageUrl.isNotEmpty)
                        Center(
                          child:
                              ClipRRect(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),

                            child:
                                Image.network(
                              imageUrl,
                              height: 220,
                              fit: BoxFit
                                  .contain,

                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const SizedBox(
                                  height: 220,
                                  child:
                                      Center(
                                    child: Text(
                                      "Unable to load payment image.",
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ==================================================
                      // BUTTONS
                      // ==================================================

                      Row(
                        children: [
                          // APPROVE
                          Expanded(
                            child:
                                ElevatedButton(
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    Colors.green,
                                ),
                              onPressed: () {
                                _approveSubscription(
                                  context,
                                  subscription,
                                );
                              },
                              child:
                                  const Text(
                                "Approve",
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          // REJECT
                          Expanded(
                            child:
                                ElevatedButton(
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    Colors.red,
                              ),
                              onPressed: () {
                                _rejectSubscription(
                                  context,
                                  subscription
                                      .id,
                                );
                              },
                              child:
                                  const Text(
                                "Reject",
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}