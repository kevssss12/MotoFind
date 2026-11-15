
import 'package:flutter/material.dart';
import 'subscription_payment_screen.dart';

class SubscriptionScreen extends StatelessWidget {
  final bool isRenewal;
  final bool isExpiredRenewal;

  const SubscriptionScreen({
    super.key,
    this.isRenewal = false,
    this.isExpiredRenewal = false,
  });

  
@override
Widget build(BuildContext context) {
  const primaryBlue = Color(0xFF0D47A1);
  const darkBlue = Color(0xFF062B63);
  const pageBackground = Color(0xFFF5F8FC);
  const containerColor = Color.fromARGB(255, 209, 209, 238);

  return Scaffold(
    backgroundColor: pageBackground,
    appBar: AppBar(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        "Choose Subscription",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE1E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: darkBlue.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.card_membership_outlined,
                    size: 42,
                    color: primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Choose Your Subscription Plan",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select a plan that suits your motorcycle parts store.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),

                  if (isRenewal) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade400,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isExpiredRenewal
                                  ? "Your subscription has expired. "
                                      "Choose a plan and submit your payment. "
                                      "Your renewal will be reviewed by Admin. "
                                      "You must wait for Admin approval before "
                                      "you can access the Store Dashboard again."
                                  : "Choose a plan and submit your payment. "
                                      "Once your renewal request is pending, "
                                      "you cannot submit another renewal request "
                                      "until the current request is processed.",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                color: darkBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  buildSubscriptionCard(
                    context,
                    icon: Icons.calendar_month_outlined,
                    title: "Monthly",
                    price: "₱199 / Month",
                    plan: "Monthly",
                    amount: 199,
                  ),

                  const SizedBox(height: 14),

                  buildSubscriptionCard(
                    context,
                    icon: Icons.calendar_view_month_outlined,
                    title: "Quarterly",
                    price: "₱499 / 3 Months",
                    plan: "Quarterly",
                    amount: 499,
                  ),

                  const SizedBox(height: 14),

                  buildSubscriptionCard(
                    context,
                    icon: Icons.workspace_premium_outlined,
                    title: "Yearly",
                    price: "₱1,799 / Year",
                    plan: "Yearly",
                    amount: 1799,
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  // ============================================================
  // SUBSCRIPTION CARD
  // ============================================================

  Widget buildSubscriptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String price,
    required String plan,
    required int amount,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ======================================================
            // ICON
            // ======================================================

            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(width: 15),

            // ======================================================
            // PLAN DETAILS
            // ======================================================

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ======================================================
            // SELECT BUTTON
            // ======================================================

            SizedBox(
              width: 90,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SubscriptionPaymentScreen(
                        plan: plan,
                        amount: amount,

                        // IMPORTANT
                        isRenewal: isRenewal,

                        // IMPORTANT FIX
                        // Pass the expired status to the
                        // payment screen.
                        isExpiredRenewal:
                            isExpiredRenewal,
                      ),
                    ),
                  );
                },
                child: const Text("Select"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
