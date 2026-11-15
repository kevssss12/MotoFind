import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});
  @override
  State<ManageUsers> createState() =>
      _ManageUsersState();
}
class _ManageUsersState extends State<ManageUsers> {
  final TextEditingController searchController =
      TextEditingController();
  final ValueNotifier<String> searchNotifier =
      ValueNotifier<String>("");
      final FocusNode searchFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      searchNotifier.value =
          searchController.text.trim().toLowerCase();
    });
  }
  @override
void dispose() {
  searchController.dispose();
  searchFocusNode.dispose();
  searchNotifier.dispose();
  super.dispose();
}
  // ================================================================
  // SEARCH
  // ================================================================
  bool matchesSearch(
    Map<String, dynamic> data,
    String query,
  ) {
    if (query.isEmpty) {
      return true;
    }
    final String fullName =
        data["fullName"]
                ?.toString()
                .toLowerCase() ?? "";
    final String email =
        data["email"]
                ?.toString()
                .toLowerCase() ?? "";
    final String phone =
        data["phone"]
                ?.toString()
                .toLowerCase() ?? "";
    final String role =
        data["role"]
                ?.toString()
                .toLowerCase() ?? "";
    final String storeName =
        data["storeName"]
                ?.toString()
                .toLowerCase() ?? "";
    final String storeAddress =
        data["storeAddress"]
                ?.toString()
                .toLowerCase() ?? "";
    return fullName.contains(query) ||
        email.contains(query) ||
        phone.contains(query) ||
        role.contains(query) ||
        storeName.contains(query) ||
        storeAddress.contains(query);
  }
  // ================================================================
  // CUSTOMER PROFILE IMAGE
  // ================================================================
  String getCustomerProfileImage(
    Map<String, dynamic> data,
  ) {
    if (data["role"]?.toString() == "Customer") {
      return data["profileImageUrl"]
              ?.toString()
              .trim() ?? "";
    }
    return "";
  }
  // ================================================================
  // BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Users",
        ),
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
                  color: const Color.fromARGB(255, 218, 212, 229),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ==========================================================
                    // SEARCH BAR
                    // ==========================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        7,
                        7,
                        7,
                        5,
                      ),
                      child: TextField(
                     controller: searchController,
                     focusNode: searchFocusNode,
                     enabled: true,
                     readOnly: false,
                     keyboardType: TextInputType.text,
                     textInputAction: TextInputAction.search,
                     enableInteractiveSelection: true,
  onTap: () {
    searchFocusNode.requestFocus();
  },
  decoration: InputDecoration(
    hintText: "Search users...",
    prefixIcon: const Icon(Icons.search),
    suffixIcon: ValueListenableBuilder<String>(
      valueListenable: searchNotifier,
      builder: (context, value, child) {
        if (value.isEmpty) {
          return const SizedBox.shrink();
        }
        return IconButton(
          tooltip: "Clear",
          icon: const Icon(Icons.clear),
          onPressed: () {
            searchController.clear();
            searchFocusNode.requestFocus();
          },
        );
      },
    ),
    filled: true,
    fillColor: Colors.grey.shade100,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Colors.grey.shade300,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.blue,
        width: 2,
      ),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
),
                    ),
                    // ==========================================================
                    // USERS STREAM
                    // ==========================================================
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("users")
                            .where(
                              "role",
                              whereIn: [
                                "Customer",
                                "Store Owner",
                              ],
                            )
                            .snapshots(),
                        builder: (context,snapshot,) {
                          // ====================================================
                          // LOADING
                          // ====================================================
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          // ====================================================
                          // ERROR
                          // ====================================================
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  "Error: ${snapshot.error}",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: Text(
                                "No users found.",
                              ),
                            );
                          }
                          final users = snapshot.data!.docs;
                          // ====================================================
                          // SEARCH FILTER
                          // ====================================================
                          return ValueListenableBuilder<String>(
                            valueListenable: searchNotifier,
                            builder: (
                              context,
                              query,
                              child,
                            ) {
                              final filteredUsers = users.where((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>;
                                return matchesSearch(
                                  data,
                                  query,
                                );
                              }).toList();
                              // ================================================
                              // RESULT COUNT
                              // ================================================
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      5,
                                      10,
                                      5,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        query.isEmpty
                                            ? "Total Users: ${users.length}"
                                            : "Found Users: ${filteredUsers.length}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // ==============================================
                                  // NO RESULT
                                  // ==============================================
                                  if (filteredUsers.isEmpty)
                                    Expanded(
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.search_off,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(
                                              height: 15,
                                            ),
                                            Text(
                                              query.isEmpty
                                                  ? "No users found."
                                                  : "No users match \"$query\".",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  // ==============================================
                                  // USER LIST
                                  // ==============================================
                                  else
                                    Expanded(
                                      child: ListView.builder(
                                        padding:
                                            const EdgeInsets.fromLTRB(
                                          7,
                                          5,
                                          7,
                                          15,
                                        ),
                                        itemCount: filteredUsers.length,
                                        itemBuilder: (
                                          context,
                                          index,
                                        ) {
                                          final doc = filteredUsers[index];
                                          final data = doc.data()
                                          as Map<String, dynamic>;
                                          // --------------------------------------
                                          // NAME
                                          // --------------------------------------
                                          final String name =
                                              data["fullName"]
                                                          ?.toString()
                                                          .trim()
                                                          .isNotEmpty ==
                                                      true
                                                  ? data["fullName"].toString()
                                                  : "No Name";
                                          // --------------------------------------
                                          // ROLE
                                          // --------------------------------------
                                          final String role =
                                              data["role"]?.toString() ??
                                                  "Unknown";
                                          // --------------------------------------
                                          // STORE IMAGE
                                          // --------------------------------------
                                          final String storeImage =
                                              data["storeImage"]
                                                      ?.toString()
                                                      .trim() ??
                                                  "";
                                          final bool hasStoreImage =
                                              role == "Store Owner" &&
                                                  storeImage.isNotEmpty;
                                          // --------------------------------------
                                          // CUSTOMER PROFILE IMAGE
                                          // --------------------------------------
                                          final String
                                              customerProfileImage =
                                              getCustomerProfileImage(data);
                                          final bool
                                              hasCustomerProfileImage =
                                              role == "Customer" &&
                                                  customerProfileImage
                                                      .isNotEmpty;
                                          // --------------------------------------
                                          // STATUS
                                          // --------------------------------------
                                          final String status =
                                              data["status"]?.toString() ??
                                                  "Active";
                                          final bool isDisabled =
                                              status.toLowerCase() ==
                                                  "disabled";
                                          return Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            elevation: 2,
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              // ==================================
                                              // IMAGE
                                              // ==================================
                                              leading: hasStoreImage
                                                  ? CircleAvatar(
                                                      radius: 27,
                                                      backgroundImage:
                                                          NetworkImage(
                                                        storeImage,
                                                      ),
                                                    )
                                                  : hasCustomerProfileImage
                                                      ? CircleAvatar(
                                                          radius: 27,
                                                          backgroundImage:
                                                              NetworkImage(
                                                            customerProfileImage,
                                                          ),
                                                        )
                                                      : CircleAvatar(
                                                          radius: 27,
                                                          child: Icon(
                                                            role == "Store Owner"
                                                                ? Icons.store
                                                                : Icons.person,
                                                            size: 28,
                                                          ),
                                                        ),
                                              // ==================================
                                              // NAME
                                              // ==================================
                                              title: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              // ==================================
                                              // ROLE
                                              // ==================================
                                              subtitle: Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      role,
                                                      style: TextStyle(
                                                        color:
                                                            role == "Store Owner"
                                                                ? Colors.orange
                                                                : Colors.blue,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 8,
                                                    ),
                                                    if (isDisabled)
                                                      const Text(
                                                        "• Disabled",

                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              // ==================================
                                              // ARROW
                                              // ==================================
                                              trailing: const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 18,
                                              ),
                                              // ==================================
                                              // DETAILS
                                              // ==================================
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (
                                                      context,
                                                    ) =>
                                                        UserDetailsScreen(
                                                      data: {
                                                        ...data,
                                                        "uid": doc.id,
                                                      },
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
            );
          },
        ),
      ),
    );
  }
}
// ==================================================================
// USER DETAILS SCREEN
// ==================================================================
class UserDetailsScreen
    extends StatefulWidget {
  final Map<String, dynamic> data;

  const UserDetailsScreen({
    super.key,
    required this.data,
  });
  @override
  State<UserDetailsScreen> createState() =>
      _UserDetailsScreenState();
}
class _UserDetailsScreenState
    extends State<UserDetailsScreen> {
  bool isProcessing = false;
  // ================================================================
  // HELPERS
  // ================================================================
  String get userStatus {
    final status =
        widget.data["status"]
            ?.toString()
            .trim();
    if (status == null ||
        status.isEmpty) {
      return "Active";
    }
    return status;
  }
  bool get isDisabled {
    return userStatus.toLowerCase() ==
        "disabled";
  }
  bool get isStoreOwner {
    return widget.data["role"]
            ?.toString() ==
        "Store Owner";
  }
  bool get isCustomer {
    return widget.data["role"]
            ?.toString() ==
        "Customer";
  }
  // ================================================================
  // CUSTOMER PROFILE IMAGE
  // ================================================================

  String get customerProfileImage {
    if (!isCustomer) {
      return "";
    }
    return widget.data["profileImageUrl"]
            ?.toString()
            .trim() ??
        "";
  }
  bool get hasCustomerProfileImage {
    return customerProfileImage.isNotEmpty &&
        (customerProfileImage.startsWith(
              "http://",
            ) ||
            customerProfileImage.startsWith(
              "https://",
            ));
  }
  // ================================================================
  // CHANGE STATUS
  // ================================================================
Future<void> changeUserStatus() async {
  if (isProcessing) return;
  final bool disable = !isDisabled;
  final String userName =
      widget.data["fullName"]?.toString() ??
          "this user";
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          disable ? "Disable User" : "Enable User",
        ),
        content: Text(
          disable
              ? "Are you sure you want to disable $userName?"
              : "Are you sure you want to enable $userName?",
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
            child: Text(
              disable ? "Disable" : "Enable",
            ),
          ),
        ],
      );
    },
  );
  if (confirm != true) return;
  setState(() {
    isProcessing = true;
  });
  try {
    final uid = widget.data["uid"];
    if (uid == null || uid.toString().trim().isEmpty) {
      throw Exception("User ID not found.");
    }
    final userRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid.toString());
    if (disable) {
      // Save the current status before disabling.
      final String currentStatus =
          widget.data["status"]?.toString().trim() ?? "";
      await userRef.update({
        "statusBeforeDisabled": currentStatus.isNotEmpty &&
                currentStatus.toLowerCase() != "disabled"
            ? currentStatus
            : "Active",
        "status": "Disabled",
      });
      widget.data["statusBeforeDisabled"] =
          currentStatus.isNotEmpty &&
                  currentStatus.toLowerCase() != "disabled"
              ? currentStatus
              : "Active";
      widget.data["status"] = "Disabled";
    } else {
      // Restore the saved status.
      final String savedStatus =
          widget.data["statusBeforeDisabled"]?.toString().trim() ?? "";
      final String restoredStatus =
          savedStatus.isNotEmpty &&
                  savedStatus.toLowerCase() != "disabled"
              ? savedStatus
              : (isStoreOwner ? "Approved" : "Active");
      await userRef.update({
        "status": restoredStatus,
        "statusBeforeDisabled": FieldValue.delete(),
      });
      widget.data["status"] = restoredStatus;
      widget.data.remove("statusBeforeDisabled");
    }
    if (!mounted) return;
    setState(() {
      isProcessing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          disable
              ? "User disabled successfully."
              : "User enabled successfully.",
        ),
        backgroundColor:
            disable ? Colors.orange : Colors.green,
      ),
    );
  } catch (e) {
    debugPrint("Change user status error: $e");
    if (!mounted) return;
    setState(() {
      isProcessing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to update user: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  // ================================================================
  // INFO
  // ================================================================
  Widget info(
    String title,
    dynamic value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              "$title:",
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value == null ||
                      value
                          .toString()
                          .isEmpty
                  ? "None"
                  : value.toString(),
            ),
          ),
        ],
      ),
    );
  }
  // ================================================================
  // BUILD
  // ================================================================
  @override
  Widget build(
    BuildContext context,
  ) {
    final String name =
        widget.data["fullName"]?.toString() ??
            "User Details";
    final String role =
        widget.data["role"]?.toString() ??
            "Unknown";
    final String storeImage =
        widget.data["storeImage"]
                ?.toString()
                .trim() ?? "";
    final bool hasStoreImage =
        isStoreOwner &&
            storeImage.isNotEmpty &&
            (storeImage.startsWith("http://") ||
                storeImage.startsWith("https://"));
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
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
                constraints: const BoxConstraints(
                  maxWidth: 1000,
                ),
                height: constraints.maxHeight,
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
                        // ======================================================
                        // PROFILE
                        // ======================================================
                        Center(
                          child: hasStoreImage
                              ? CircleAvatar(
                                  radius: 65,
                                  backgroundImage: NetworkImage(
                                    storeImage,
                                  ),
                                )
                              : hasCustomerProfileImage
                                  ? CircleAvatar(
                                      radius: 65,
                                      backgroundImage: NetworkImage(
                                        customerProfileImage,
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 65,
                                      child: Icon(
                                        role == "Store Owner"
                                            ? Icons.store
                                            : Icons.person,
                                        size: 60,
                                      ),
                                    ),
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: role == "Store Owner"
                                  ? Colors.orange.shade100
                                  : Colors.blue.shade100,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: role == "Store Owner"
                                    ? Colors.orange.shade800
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // ======================================================
                        // ACCOUNT INFORMATION
                        // ======================================================
                        const Text(
                          "Account Information",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        info(
                          "Full Name",
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
                          "Role",
                          role,
                        ),
                        info(
                          "Status",
                          userStatus,
                        ),
                        const Divider(),
                        // ======================================================
                        // STORE OWNER INFORMATION
                        // ======================================================
                        if (isStoreOwner) ...[
                          const SizedBox(height: 10),
                          const Text(
                            "Store Information",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          info(
                            "Store Name",
                            widget.data["storeName"],
                          ),
                          info(
                            "Store Address",
                            widget.data["storeAddress"],
                          ),
                          info(
                            "Permit Number",
                            widget.data["permitNumber"],
                          ),
                          info(
                            "Store Status",
                            widget.data["status"],
                          ),
                          const Divider(),
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
                            formatDate(
                              widget.data["subscriptionStart"],
                            ),
                          ),
                          info(
                            "End Date",
                            formatDate(
                              widget.data["subscriptionEnd"],
                            ),
                          ),
                          // ====================================================
                          // RENEWAL INFORMATION
                          // ====================================================
                          if (widget.data["renewalStatus"] != null ||
                              widget.data["renewalPlan"] != null) ...[
                            const Divider(),
                            const SizedBox(height: 10),
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
                              widget.data["renewalPlan"],
                            ),
                            info(
                              "Renewal Amount",
                              widget.data["renewalAmount"] != null
                                  ? "₱${widget.data["renewalAmount"]}"
                                  : "None",
                            ),
                            info(
                              "Renewal Status",
                              widget.data["renewalStatus"],
                            ),
                            info(
                              "Submitted At",
                              formatDate(
                                widget.data["renewalSubmittedAt"],
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 25),
                        // ======================================================
                        // ENABLE / DISABLE USER
                        // ======================================================
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : changeUserStatus,
                            icon: isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    isDisabled
                                        ? Icons.check_circle
                                        : Icons.block,
                                  ),
                            label: Text(
                              isProcessing
                                  ? "Processing..."
                                  : isDisabled
                                      ? "Enable User"
                                      : "Disable User",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDisabled
                                  ? Colors.green
                                  : Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
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
  // ================================================================
  // DATE FORMAT
  // ================================================================
  String formatDate(
    dynamic value,
  ) {
    if (value == null) {
      return "None";
    }
    try {
      if (value is Timestamp) {
        final date =
            value.toDate();
        return "${_month(date.month)} "
            "${date.day}, "
            "${date.year}";
      }
      if (value is DateTime) {
        return "${_month(value.month)} "
            "${value.day}, "
            "${value.year}";
      }
      return value.toString();
    } catch (e) {
      return "None";
    }
  }
  String _month(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    if (month < 1 ||
        month > 12) {
      return "";
    }
    return months[month - 1];
  }
}