import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_screen.dart';

class SubscriptionExpiryCard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const SubscriptionExpiryCard({
    super.key,
    required this.userData,
  });

  // ============================================================
  // GET DAYS REMAINING
  // ============================================================

  int getDaysRemaining(Timestamp? endTimestamp) {
    if (endTimestamp == null) {
      return 0;
    }

    final DateTime endDate = endTimestamp.toDate();
    final DateTime now = DateTime.now();

    if (!now.isBefore(endDate)) {
      return 0;
    }

    return endDate.difference(now).inDays;
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // SUBSCRIPTION STATUS
    // ============================================================

    final String status =
        userData["subscriptionStatus"]?.toString() ?? "";

    // ============================================================
    // IMPORTANT:
    // FIRESTORE FIELD IS "subscriptionEnd"
    // ============================================================

    final Timestamp? endDate =
        userData["subscriptionEnd"] is Timestamp
            ? userData["subscriptionEnd"] as Timestamp
            : null;

    // ============================================================
    // DAYS REMAINING
    // ============================================================

    final int daysRemaining =
        getDaysRemaining(endDate);

    // ============================================================
    // CHECK IF EXPIRED
    // ============================================================

    final bool expired =
        status == "Expired" ||
        (endDate != null &&
            !DateTime.now().isBefore(
              endDate.toDate(),
            ));

    // ============================================================
    // SHOW ALERT IF:
    // EXPIRED OR 7 DAYS OR LESS REMAINING
    // ============================================================

    final bool shouldShow =
        expired ||
        (endDate != null &&
            daysRemaining <= 7);

    // ============================================================
    // DON'T SHOW CARD IF SUBSCRIPTION IS NOT NEAR EXPIRY
    // ============================================================

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    // ============================================================
    // CARD
    // ============================================================

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: expired
            ? Colors.red.withOpacity(0.08)
            : Colors.orange.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: expired
              ? Colors.red
              : Colors.orange,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ==================================================
          // TITLE
          // ==================================================

          Row(
            children: [

              Icon(
                expired
                    ? Icons.error_outline
                    : Icons.warning_amber_rounded,
                color: expired
                    ? Colors.red
                    : Colors.orange,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  expired
                      ? "Subscription Expired"
                      : "Subscription Expiring Soon",

                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    color: expired
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ==================================================
          // MESSAGE
          // ==================================================

          Text(
            expired
                ? "Your subscription has expired. "
                    "Please choose a new subscription plan."
                : daysRemaining == 0
                    ? "Your subscription expires today."
                    : "Your subscription will expire in "
                        "$daysRemaining day(s).",

            style: const TextStyle(
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // ADVANCE / RENEW BUTTON
          // ==================================================

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(

              onPressed: () {

                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) =>
                        const SubscriptionScreen(
                      isRenewal: true,
                    ),
                  ),
                );

              },

              icon: Icon(
                expired
                    ? Icons.refresh
                    : Icons.payment,
              ),

              label: Text(
                expired
                    ? "Renew Subscription"
                    : "Advance Payment",
              ),
            ),
          ),
        ],
      ),
    );
  }
}