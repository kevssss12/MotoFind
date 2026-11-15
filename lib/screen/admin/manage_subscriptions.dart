
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageSubscriptions extends StatefulWidget {
  const ManageSubscriptions({super.key});
  @override
  State<ManageSubscriptions> createState() =>
      _ManageSubscriptionsState();
}
class _ManageSubscriptionsState
    extends State<ManageSubscriptions> {
  // ==========================================================
  // SEARCH
  // ==========================================================
  final TextEditingController _searchController =
      TextEditingController();
  final ValueNotifier<String> _searchTextNotifier =
      ValueNotifier<String>("");
  final FocusNode _searchFocusNode = FocusNode();
  late final Stream<QuerySnapshot> _subscriptionsStream;
  // ==========================================================
  // INIT STATE
  // ==========================================================
  @override
  void initState() {
    super.initState();
    _subscriptionsStream = FirebaseFirestore.instance
        .collection("subscriptions")
        .snapshots();
    _searchController.addListener(() {
      _searchTextNotifier.value =
          _searchController.text.trim().toLowerCase();
    });
  }
  @override
  void dispose() {
    _searchController.dispose();
    _searchTextNotifier.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  // ==========================================================
  // GET STORE IMAGE
  // ==========================================================
  Future<String?> getStoreImage(String storeId) async {
    try {
      final cleanStoreId = storeId.trim();
      if (cleanStoreId.isEmpty) {
        return null;
      }
      final storeDoc = await FirebaseFirestore.instance
          .collection("stores")
          .doc(cleanStoreId)
          .get();
      if (!storeDoc.exists) {
        return null;
      }
      final data = storeDoc.data();

      if (data == null) {
        return null;
      }
      final imageUrl =
          data["storeImage"]?.toString().trim() ?? "";
      if (imageUrl.isNotEmpty) {
        return imageUrl;
      }
    } catch (e) {
      debugPrint("ERROR GETTING STORE IMAGE: $e");
    }
    return null;
  }
  // ==========================================================
  // SEARCH BAR
  // ==========================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 5),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        enabled: true,
        readOnly: false,
        autofocus: false,
        showCursor: true,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        enableInteractiveSelection: true,
        decoration: InputDecoration(
        hintText: "Search store, owner, plan, status...",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<String>(
        valueListenable: _searchTextNotifier,
        builder: (context, value, child) {
              if (value.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: "Clear",
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              );
            },
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.blue,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Manage Subscriptions"),
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
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255, 218, 212, 229,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // Search bar is outside StreamBuilder.
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _subscriptionsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  "Error: ${snapshot.error}",
                                ),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No Subscription Found",
                                ),
                              );
                            }
                            final docs = snapshot.data!.docs;
                            // GROUP BY STORE ID
                            final Map<String,
                                    List<QueryDocumentSnapshot>>
                                groupedStores = {};
                            for (final doc in docs) {
                              final data =
                                  doc.data() as Map<String, dynamic>;
                              final String storeId =
                                  data["storeId"]
                                          ?.toString()
                                          .trim() ??
                                      "";
                              final String key = storeId.isNotEmpty
                                  ? storeId
                                  : "no_store_id_${doc.id}";

                              groupedStores.putIfAbsent(
                                key,
                                () => [],
                              );
                              groupedStores[key]!.add(doc);
                            }
                            // SEARCH RESULTS
                            return ValueListenableBuilder<String>(
                              valueListenable: _searchTextNotifier,
                              builder: (
                                context,
                                searchText,
                                child,
                              ) {
                                final filteredStores =
                                    groupedStores.entries.where(
                                  (entry) {
                                    for (final doc in entry.value) {
                                      final data = doc.data()
                                          as Map<String, dynamic>;
                                      final fields = [
                                        data["storeName"],
                                        data["ownerName"],
                                        data["fullName"],
                                        data["email"],
                                        data["phone"],
                                        data["storeAddress"],
                                        data["plan"],
                                        data["status"],
                                      ];
                                      if (fields.any(
                                        (field) =>
                                            field
                                                ?.toString()
                                                .trim()
                                                .toLowerCase()
                                                .contains(searchText) ??
                                            false,
                                      )) {
                                        return true;
                                      }
                                    }
                                    return false;
                                  },
                                ).toList();
                                return Column(
                                  children: [
                                    // RESULT COUNT
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 8,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          searchText.isEmpty
                                              ? "Stores: ${groupedStores.length}"
                                              : "Results: ${filteredStores.length}",
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // EMPTY SEARCH RESULT
                                    if (filteredStores.isEmpty)
                                      Expanded(
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .workspace_premium_outlined,
                                                size: 65,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(height: 15),
                                              Text(
                                                searchText.isEmpty
                                                    ? "No Subscription Found"
                                                    : "No subscriptions match \"$searchText\".",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: ListView.builder(
                                          keyboardDismissBehavior:
                                              ScrollViewKeyboardDismissBehavior
                                                  .onDrag,
                                          padding:
                                              const EdgeInsets.fromLTRB(
                                            16, 5, 16, 16,
                                          ),
                                          itemCount: filteredStores.length,

                                          itemBuilder: (context, index) {
                                            final entry =
                                                filteredStores[index];

                                            final subscriptions =
                                                entry.value;

                                            final firstData =
                                                subscriptions.first.data()
                                                    as Map<String, dynamic>;

                                            final String storeName =
                                                firstData["storeName"]
                                                            ?.toString()
                                                            .trim()
                                                            .isNotEmpty ==
                                                        true
                                                    ? firstData["storeName"]
                                                        .toString()
                                                        .trim()
                                                    : "Unknown Store";

                                            final String storeId =
                                                firstData["storeId"]
                                                        ?.toString()
                                                        .trim() ??
                                                    "";
                                            bool hasPending = false;
                                            for (final doc
                                                in subscriptions) {
                                              final data = doc.data()
                                                  as Map<String, dynamic>;
                                              final status =
                                                  data["status"]
                                                          ?.toString()
                                                          .toLowerCase() ??
                                                      "";
                                              if (status == "pending") {
                                                hasPending = true;
                                                break;
                                              }
                                            }
                                            return Card(
                                              color: Colors.white,
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 18,
                                                  vertical: 8,
                                                ),
                                                leading:
                                                    FutureBuilder<String?>(
                                                  future:
                                                      getStoreImage(storeId),
                                                  builder: (
                                                    context,
                                                    imageSnapshot,
                                                  ) {
                                                    if (imageSnapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return CircleAvatar(
                                                        backgroundColor:
                                                            hasPending
                                                                ? Colors.orange
                                                                    .shade100
                                                                : Colors.blue
                                                                    .shade100,
                                                        child:
                                                            const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    final imageUrl =
                                                        imageSnapshot.data
                                                                ?.trim() ?? "";
                                                    if (imageUrl.isNotEmpty) {
                                                      return CircleAvatar(
                                                        radius: 28,
                                                        backgroundColor:
                                                            Colors.grey
                                                                .shade200,
                                                        backgroundImage:
                                                            NetworkImage(
                                                          imageUrl,
                                                        ),
                                                        onBackgroundImageError:
                                                            (
                                                          exception,
                                                          stackTrace,
                                                        ) {
                                                          debugPrint(
                                                            "STORE IMAGE ERROR: $exception",
                                                          );
                                                        },
                                                      );
                                                    }
                                                    return CircleAvatar(
                                                      radius: 28,
                                                      backgroundColor:
                                                          hasPending
                                                              ? Colors.orange
                                                                  .shade100
                                                              : Colors.blue
                                                                  .shade100,
                                                      child: Icon(
                                                        hasPending
                                                            ? Icons
                                                                .pending_actions
                                                            : Icons.storefront,
                                                        color: hasPending
                                                            ? Colors.orange
                                                            : Colors.blue,
                                                      ),
                                                    );
                                                  },
                                                ),
                                                title: Text(
                                                  storeName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                                subtitle: hasPending
                                                    ? const Text(
                                                        "Pending subscription",
                                                        style: TextStyle(
                                                          color: Colors.orange,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      )
                                                    : Text(
                                                        "${subscriptions.length} subscription record(s)",
                                                      ),
                                                trailing: Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 18,
                                                  color: hasPending
                                                      ? Colors.orange
                                                      : Colors.grey,
                                                ),
                                                onTap: () {
                                                  _searchFocusNode.unfocus();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          SubscriptionDetailsScreen(
                                                        storeName: storeName,
                                                        subscriptions:
                                                            subscriptions,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
// ================================================================
// SUBSCRIPTION DETAILS
// ================================================================
class SubscriptionDetailsScreen extends StatefulWidget {
  final String storeName;
  final List<QueryDocumentSnapshot> subscriptions;
  const SubscriptionDetailsScreen({
    super.key,
    required this.storeName,
    required this.subscriptions,
  });
  @override
  State<SubscriptionDetailsScreen> createState() =>
      _SubscriptionDetailsScreenState();
}
class _SubscriptionDetailsScreenState
    extends State<SubscriptionDetailsScreen> {
  String? processingId;
  // ============================================================
  // GET STORE IMAGE
  // ============================================================
  Future<String?> getStoreImage(String storeId) async {
    try {
      final cleanStoreId = storeId.trim();
      if (cleanStoreId.isEmpty) {
        return null;
      }
      final storeDoc = await FirebaseFirestore.instance
          .collection("stores")
          .doc(cleanStoreId)
          .get();
      if (!storeDoc.exists) {
        return null;
      }
      final data = storeDoc.data();
      if (data == null) {
        return null;
      }
      final imageUrl =
          data["storeImage"]?.toString().trim() ?? "";
      if (imageUrl.isNotEmpty) {
        return imageUrl;
      }
    } catch (e) {
      debugPrint("ERROR GETTING STORE IMAGE: $e");
    }
    return null;
  }
  // ============================================================
  // APPROVE SUBSCRIPTION
  // ============================================================
  Future<void> approveSubscription(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    if (processingId != null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Approve Subscription?"),
          content: Text(
            "Are you sure you want to approve the subscription "
            "of ${widget.storeName}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Confirm Approval"),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    setState(() {
      processingId = doc.id;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final String ownerId =
          data["ownerId"]?.toString().trim() ?? "";
      final String plan =
          data["plan"]?.toString().trim() ?? "";
      if (ownerId.isEmpty) {
        throw Exception("Owner ID not found.");
      }
      if (plan.isEmpty) {
        throw Exception("Subscription plan not found.");
      }
      final DateTime startDate = DateTime.now();
      DateTime endDate;
      switch (plan.toLowerCase()) {
        case "monthly":
          endDate = DateTime(
            startDate.year,
            startDate.month + 1,
            startDate.day,
          );
          break;
        case "quarterly":
          endDate = DateTime(
            startDate.year,
            startDate.month + 3,
            startDate.day,
          );
          break;
        case "yearly":
          endDate = DateTime(
            startDate.year + 1,
            startDate.month,
            startDate.day,
          );
          break;
        default:
          throw Exception(
            "Invalid subscription plan: $plan",
          );
      }
      // UPDATE BOTH DOCUMENTS TOGETHER
      final batch = FirebaseFirestore.instance.batch();
      final subscriptionRef = FirebaseFirestore.instance
          .collection("subscriptions")
          .doc(doc.id);
      final userRef = FirebaseFirestore.instance
          .collection("users")
          .doc(ownerId);
      batch.update(subscriptionRef, {
        "status": "Approved",
      });
      batch.update(userRef, {
        "status": "Approved",
        "subscriptionStatus": "Approved",
        "subscriptionPlan": plan,
        "subscriptionStart": Timestamp.fromDate(startDate),
        "subscriptionEnd": Timestamp.fromDate(endDate),
      });
      await batch.commit();
      if (!mounted) return;
      setState(() {
        processingId = null;
      });
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Subscription approved successfully!",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Approve subscription error: $e");
      if (!mounted) return;
      setState(() {
        processingId = null;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Failed to approve subscription: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // ============================================================
  // REJECT SUBSCRIPTION
  // ============================================================
  Future<void> rejectSubscription(
    QueryDocumentSnapshot doc,
  ) async {
    if (processingId != null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Reject Subscription"),
          content: Text(
            "Reject this subscription request "
            "for ${widget.storeName}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    setState(() {
      processingId = doc.id;
    });
    try {
      await FirebaseFirestore.instance
          .collection("subscriptions")
          .doc(doc.id)
          .update({
        "status": "Rejected",
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Subscription Rejected"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint("Reject subscription error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to reject subscription: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          processingId = null;
        });
      }
    }
  }
  // ============================================================
  // INFO
  // ============================================================
  Widget info(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              "$title:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "None",
            ),
          ),
        ],
      ),
    );
  }
  // ============================================================
  // BUILD DETAILS
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName),
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
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255, 218, 212, 229,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: widget.subscriptions.length,
                    itemBuilder: (context, index) {
                      final doc = widget.subscriptions[index];
                      final data =
                          doc.data() as Map<String, dynamic>;
                      final String status =
                          data["status"]?.toString() ?? "Unknown";
                      final bool pending =
                          status.toLowerCase() == "pending";
                      final String storeId =
                          data["storeId"]?.toString().trim() ?? "";
                      return Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // RECORD HEADER
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  FutureBuilder<String?>(
                                    future: getStoreImage(storeId),
                                    builder: (
                                      context,
                                      imageSnapshot,
                                    ) {
                                      if (imageSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircleAvatar(
                                          radius: 32,
                                          backgroundColor:
                                              Colors.blue.shade100,
                                          child: const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      }
                                      final imageUrl =
                                          imageSnapshot.data?.trim() ?? "";
                                      if (imageUrl.isNotEmpty) {
                                        return CircleAvatar(
                                          radius: 32,
                                          backgroundColor:
                                              Colors.grey.shade200,
                                          backgroundImage:
                                              NetworkImage(imageUrl),
                                        );
                                      }
                                      return CircleAvatar(
                                        radius: 32,
                                        backgroundColor:
                                            Colors.blue.shade100,
                                        child: const Icon(
                                          Icons.storefront,
                                          size: 32,
                                          color: Colors.blue,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      "Subscription ${index + 1}",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              // STORE INFORMATION
                              info("Store Name", data["storeName"]),
                              info("Owner", data["ownerName"]),
                              info("Email", data["email"]),
                              info("Phone", data["phone"]),
                              info("Address", data["storeAddress"]),
                              const Divider(height: 30),
                              // SUBSCRIPTION INFORMATION
                              info("Plan", data["plan"]),
                              info(
                                "Amount",
                                data["amount"] != null
                                    ? "₱${data["amount"]}"
                                    : "None",
                              ),
                              info("Status", status),
                              const SizedBox(height: 15),
                              // PAYMENT SCREENSHOT
                              const Text(
                                "Payment Screenshot",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (data["paymentImageUrl"] != null &&
                                  data["paymentImageUrl"]
                                      .toString()
                                      .isNotEmpty)
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  child: Image.network(
                                    data["paymentImageUrl"].toString(),
                                    width: double.infinity,
                                    height: 300,
                                    fit: BoxFit.contain,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return const SizedBox(
                                        height: 200,
                                        child: Center(
                                          child: Text(
                                            "Unable to load payment screenshot.",
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                const Text(
                                  "No payment screenshot.",
                                ),
                              const SizedBox(height: 20),
                              // APPROVE / REJECT
                              if (pending)
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 50,
                                        child: ElevatedButton.icon(
                                          onPressed: processingId != null
                                              ? null
                                              : () => approveSubscription(
                                                    doc,
                                                    data,
                                                  ),
                                          icon: processingId == doc.id
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(Icons.check),
                                          label: const Text("Approve"),
                                          style:
                                              ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: SizedBox(
                                        height: 50,
                                        child: ElevatedButton.icon(
                                          onPressed: processingId != null
                                              ? null
                                              : () => rejectSubscription(
                                                    doc,
                                                  ),
                                          icon: const Icon(Icons.close),
                                          label: const Text("Reject"),
                                          style:
                                              ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: status.toLowerCase() ==
                                            "approved"
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: status.toLowerCase() ==
                                                "approved"
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}