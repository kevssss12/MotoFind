
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const StoreDetailsScreen({
    super.key,
    required this.data,
  });

  @override
  State<StoreDetailsScreen> createState() =>
      _StoreDetailsScreenState();
}

class _StoreDetailsScreenState
    extends State<StoreDetailsScreen> {
  bool isProcessing = false;

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isRenewalPending {
    return widget.data["renewalStatus"]
            ?.toString()
            .trim()
            .toLowerCase() ==
        "pending";
  }

  bool get isStoreApproved {
    return widget.data["status"]
            ?.toString()
            .trim()
            .toLowerCase() ==
        "approved";
  }

  bool get isStorePending {
    return widget.data["status"]
            ?.toString()
            .trim()
            .toLowerCase() ==
        "pending";
  }

  bool get isStoreDisabled {
    return widget.data["status"]
            ?.toString()
            .trim()
            .toLowerCase() ==
        "disabled";
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String formatTimestamp(dynamic value) {
    if (value == null) {
      return "None";
    }

    try {
      if (value is Timestamp) {
        return DateFormat(
          "MMMM dd, yyyy",
        ).format(value.toDate());
      }

      if (value is DateTime) {
        return DateFormat(
          "MMMM dd, yyyy",
        ).format(value);
      }

      return value.toString();
    } catch (e) {
      return "None";
    }
  }

  // ============================================================
  // GET DATETIME
  // ============================================================

  DateTime? getDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    try {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // APPROVE RENEWAL
  // ============================================================

  Future<void> approveRenewal() async {
    if (isProcessing) return;

    final String renewalPlan =
        widget.data["renewalPlan"]
                ?.toString()
                .trim() ??
            "";

    if (renewalPlan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Renewal plan not found.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Approve Renewal",
          ),
          content: Text(
            "Approve the $renewalPlan renewal "
            "for ${widget.data["storeName"] ?? "this store"}?\n\n"
            "The subscription dates will be updated automatically.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Approve Renewal"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (!mounted) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final DateTime now = DateTime.now();

      final DateTime? oldStartDate =
          getDateTime(
        widget.data["subscriptionStart"],
      );

      final DateTime? oldEndDate =
          getDateTime(
        widget.data["subscriptionEnd"],
      );

      final bool isExpired =
          oldEndDate == null ||
          oldEndDate.isBefore(now);

      // ========================================================
      // START DATE
      // ========================================================

      final DateTime startDate =
          isExpired
              ? now
              : (oldStartDate ?? now);

      // ========================================================
      // BASE DATE
      // ========================================================

      final DateTime baseDate =
          isExpired
              ? now
              : (oldEndDate);

      // ========================================================
      // NEW END DATE
      // ========================================================

      late DateTime endDate;

      switch (renewalPlan.toLowerCase()) {
        case "monthly":
          endDate = DateTime(
            baseDate.year,
            baseDate.month + 1,
            baseDate.day,
          );
          break;

        case "quarterly":
          endDate = DateTime(
            baseDate.year,
            baseDate.month + 3,
            baseDate.day,
          );
          break;

        case "yearly":
          endDate = DateTime(
            baseDate.year + 1,
            baseDate.month,
            baseDate.day,
          );
          break;

        default:
          throw Exception(
            "Invalid renewal plan: $renewalPlan",
          );
      }

      // ========================================================
      // USER ID
      // ========================================================

      final uid = widget.data["uid"];

      if (uid == null ||
          uid.toString().trim().isEmpty) {
        throw Exception(
          "User ID not found.",
        );
      }

      // ========================================================
      // UPDATE USER
      // ========================================================

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid.toString())
          .update({
        "subscriptionPlan": renewalPlan,
        "subscriptionStatus": "Approved",
        "subscriptionStart":
            Timestamp.fromDate(startDate),
        "subscriptionEnd":
            Timestamp.fromDate(endDate),
        "status": "Approved",

        "renewalStatus":
            FieldValue.delete(),
        "renewalPlan":
            FieldValue.delete(),
        "renewalAmount":
            FieldValue.delete(),
        "renewalScreenshot":
            FieldValue.delete(),
        "renewalSubmittedAt":
            FieldValue.delete(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isExpired
                ? "Expired renewal approved successfully!"
                : "Advance renewal approved successfully!",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        "Approve renewal error: $e",
      );

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to approve renewal: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // APPROVE NEW STORE
  // ============================================================

  Future<void> approveNewStore() async {
    if (isProcessing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Approve Store"),
          content: Text(
            "Are you sure you want to approve "
            "${widget.data["storeName"] ?? "this store"}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Approve"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (!mounted) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final uid = widget.data["uid"];

      if (uid == null ||
          uid.toString().trim().isEmpty) {
        throw Exception(
          "User ID not found.",
        );
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid.toString())
          .update({
        "status": "Approved",
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Store approved successfully!",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        "Approve store error: $e",
      );

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to approve store: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // DISABLE STORE
  // ============================================================

  Future<void> disableStore() async {
    if (isProcessing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Disable Store"),
          content: Text(
            "Are you sure you want to disable "
            "${widget.data["storeName"] ?? "this store"}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Disable"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (!mounted) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final uid = widget.data["uid"];

      if (uid == null ||
          uid.toString().trim().isEmpty) {
        throw Exception(
          "User ID not found.",
        );
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid.toString())
          .update({
        "status": "Disabled",
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Store disabled."),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        "Disable store error: $e",
      );

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to disable store: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ENABLE STORE
  // ============================================================

  Future<void> enableStore() async {
    if (isProcessing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enable Store"),
          content: Text(
            "Are you sure you want to enable "
            "${widget.data["storeName"] ?? "this store"}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Enable"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (!mounted) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final uid = widget.data["uid"];

      if (uid == null ||
          uid.toString().trim().isEmpty) {
        throw Exception(
          "User ID not found.",
        );
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid.toString())
          .update({
        "status": "Approved",
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Store enabled successfully.",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        "Enable store error: $e",
      );

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to enable store: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // INFO WIDGET
  // ============================================================

  Widget info(
    String title,
    dynamic value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              "$title:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "",
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INVENTORY SUMMARY
  // ============================================================

  Widget buildInventorySummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
    .collection("products")
    .where(
      "storeId",
      isEqualTo: widget.data["storeId"],
    )
    .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Text(
            "Error loading inventory: ${snapshot.error}",
          );
        }

        final products =
            snapshot.data?.docs ?? [];

        int totalProducts = products.length;
        int totalStocks = 0;
        double inventoryValue = 0;

        for (final item in products) {
          final product =
              item.data()
                  as Map<String, dynamic>;

          final dynamic stockValue =
              product["stock"];

          final int stock =
              stockValue is num
                  ? stockValue.toInt()
                  : int.tryParse(
                        stockValue?.toString() ??
                            "0",
                      ) ??
                      0;

          final dynamic priceValue =
              product["price"];

          final double price =
              priceValue is num
                  ? priceValue.toDouble()
                  : double.tryParse(
                        priceValue?.toString() ??
                            "0",
                      ) ??
                      0;

          totalStocks += stock;
          inventoryValue +=
              stock * price;
        }

        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Inventory Summary",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ==================================================
                // TOTAL PRODUCTS
                // ==================================================

                _summaryRow(
                  icon: Icons.category,
                  title: "Total Products",
                  value:
                      totalProducts.toString(),
                ),

                const Divider(height: 25),

                // ==================================================
                // TOTAL STOCKS
                // ==================================================

                _summaryRow(
                  icon: Icons.inventory,
                  title: "Total Stocks",
                  value:
                      totalStocks.toString(),
                ),

                const Divider(height: 25),

                // ==================================================
                // INVENTORY VALUE
                // ==================================================

                _summaryRow(
                  icon: Icons.payments,
                  title: "Inventory Value",
                  value: NumberFormat.currency(
                    locale: "en_PH",
                    symbol: "₱",
                  ).format(
                    inventoryValue,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget _summaryRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 30,
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String storeName =
        widget.data["storeName"]
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? widget.data["storeName"].toString().trim()
            : "Store Details";

    final String storeImage =
        widget.data["storeImage"]
                ?.toString()
                .trim() ??
            "";

    final bool hasStoreImage =
        storeImage.startsWith("https://") ||
        storeImage.startsWith("http://");

    return Scaffold(
      appBar: AppBar(
        title: Text(storeName),
        centerTitle: true,
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(12),

        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Container(
                width: double.infinity,
                height: constraints.maxHeight,
                constraints: const BoxConstraints(
                  maxWidth: 1000,
                ),
                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    218,
                    212,
                    229,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.05,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),

                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        // ====================================================
                        // STORE IMAGE
                        // ====================================================

                        Center(
                          child: hasStoreImage
                              ? CircleAvatar(
                                  radius: 60,
                                  backgroundImage:
                                      NetworkImage(storeImage),
                                  onBackgroundImageError:
                                      (exception, stackTrace) {},
                                )
                              : const CircleAvatar(
                                  radius: 60,
                                  child: Icon(
                                    Icons.store,
                                    size: 50,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 20),

                        // ====================================================
                        // STORE NAME
                        // ====================================================

                        Center(
                          child: Text(
                            storeName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // ====================================================
                        // STORE INFORMATION
                        // ====================================================

                        const Text(
                          "Store Information",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        info(
                          "Owner Name",
                          widget.data["fullName"],
                        ),

                        info(
                          "Email",
                          widget.data["email"],
                        ),

                        info(
                          "Phone",
                          widget.data["phone"],
                        ),

                        info(
                          "Address",
                          widget.data["storeAddress"],
                        ),

                        info(
                          "Permit Number",
                          widget.data["permitNumber"],
                        ),

                        info(
                          "Status",
                          widget.data["status"],
                        ),

                        const Divider(),

                        // ====================================================
                        // SUBSCRIPTION
                        // ====================================================

                        const SizedBox(height: 10),

                        const Text(
                          "Subscription",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        info(
                          "Plan",
                          widget.data["subscriptionPlan"],
                        ),

                        info(
                          "Subscription Status",
                          widget.data["subscriptionStatus"],
                        ),

                        info(
                          "Start Date",
                          formatTimestamp(
                            widget.data["subscriptionStart"],
                          ),
                        ),

                        info(
                          "End Date",
                          formatTimestamp(
                            widget.data["subscriptionEnd"],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ====================================================
                        // RENEWAL
                        // ====================================================

                        const Text(
                          "Renewal",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        info(
                          "Renewal Plan",
                          widget.data["renewalPlan"] ?? "None",
                        ),

                        info(
                          "Renewal Amount",
                          widget.data["renewalAmount"] != null
                              ? "₱${widget.data["renewalAmount"]}"
                              : "None",
                        ),

                        info(
                          "Renewal Status",
                          widget.data["renewalStatus"] ?? "None",
                        ),

                        info(
                          "Submitted At",
                          formatTimestamp(
                            widget.data["renewalSubmittedAt"],
                          ),
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          "Renewal Payment Screenshot",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ====================================================
                        // RENEWAL SCREENSHOT
                        // ====================================================

                        widget.data["renewalScreenshot"] != null &&
                                widget.data["renewalScreenshot"]
                                    .toString()
                                    .trim()
                                    .isNotEmpty
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(10),

                                child: Image.network(
                                  widget.data["renewalScreenshot"]
                                      .toString(),

                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.contain,

                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return const SizedBox(
                                      height: 150,
                                      child: Center(
                                        child: Text(
                                          "Unable to load screenshot.",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const Text(
                                "No renewal submitted.",
                              ),

                        const SizedBox(height: 20),

                        // ====================================================
                        // RENEWAL APPROVAL CARD
                        // ====================================================

                        if (isRenewalPending)
                          Card(
                            color: Colors.orange.shade50,
                            elevation: 2,

                            child: Padding(
                              padding: const EdgeInsets.all(15),

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.notification_important,
                                        color: Colors.orange,
                                      ),

                                      const SizedBox(width: 10),

                                      Expanded(
                                        child: Text(
                                          "RENEWAL PAYMENT PENDING",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight:
                                                FontWeight.bold,
                                            color:
                                                Colors.orange.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    "Plan: ${widget.data["renewalPlan"] ?? "None"}",
                                  ),

                                  if (widget.data["renewalAmount"] !=
                                      null)
                                    Text(
                                      "Amount: ₱${widget.data["renewalAmount"]}",
                                    ),

                                  const SizedBox(height: 15),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,

                                    child: ElevatedButton.icon(
                                      onPressed: isProcessing
                                          ? null
                                          : approveRenewal,

                                      icon: isProcessing
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.check_circle,
                                            ),

                                      label: Text(
                                        isProcessing
                                            ? "Processing..."
                                            : "Approve Renewal",
                                      ),

                                      style:
                                          ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const Divider(),

                        // ====================================================
                        // INVENTORY SUMMARY
                        // ====================================================

                        const SizedBox(height: 15),

                        buildInventorySummary(),

                        const SizedBox(height: 30),

                        // ====================================================
                        // MAIN STORE BUTTON
                        // ====================================================

                        if (!isRenewalPending)
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: _buildMainStoreButton(),
                          ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // MAIN STORE BUTTON
  // ============================================================

  Widget _buildMainStoreButton() {
    // ==========================================================
    // NEW STORE
    // ==========================================================

    if (isStorePending) {
      return ElevatedButton.icon(
        onPressed:
            isProcessing
                ? null
                : approveNewStore,
        icon: const Icon(
          Icons.check_circle,
        ),
        label: const Text(
          "Approve Store",
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );
    }

    // ==========================================================
    // APPROVED STORE
    // ==========================================================

    if (isStoreApproved) {
      return ElevatedButton.icon(
        onPressed:
            isProcessing
                ? null
                : disableStore,
        icon: const Icon(
          Icons.block,
        ),
        label: const Text(
          "Disable Store",
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      );
    }

    // ==========================================================
    // DISABLED STORE
    // ==========================================================

    if (isStoreDisabled) {
      return ElevatedButton.icon(
        onPressed:
            isProcessing
                ? null
                : enableStore,
        icon: const Icon(
          Icons.check_circle,
        ),
        label: const Text(
          "Enable Store",
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}