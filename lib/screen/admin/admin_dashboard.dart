
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'manage_stores_screen.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'manage_subscriptions.dart';
import 'manage_users.dart';
import 'store_approval_screen.dart';
import 'manage_products.dart';
import 'reports_screen.dart';
import 'store_details_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}
class _AdminDashboardState extends State<AdminDashboard> {
  // ============================================================
  // GET CURRENT ADMIN DATA
  // ============================================================
  Future<Map<String, dynamic>?> getAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      return null;
    }
    return doc.data();
  }
  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        bool didPop,
        dynamic result,
      ) async {
        if (didPop) {
          return;
        }
        final bool? shouldExit = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text("Exit App?"),
              content: const Text(
                "Are you sure you want to leave the app?",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text("Exit"),
                ),
              ],
            );
          },
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      // ==========================================================
      // SCAFFOLD
      // ==========================================================
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Admin Dashboard",
          ),
          centerTitle: true,
          actions: [
            // ====================================================
            // NOTIFICATIONS
            // ====================================================
          StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection("users")
      .where("role", isEqualTo: "Store Owner")
      .snapshots(),
  builder: (context, usersSnapshot) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("subscriptions")
          .snapshots(),
      builder: (context, subscriptionsSnapshot) {
        int notificationCount = 0;
        // Pending store applications and renewals
        if (usersSnapshot.hasData) {
          for (final doc in usersSnapshot.data!.docs) {
            final data =
                doc.data() as Map<String, dynamic>;
            final status = (data["status"] ?? "")
                .toString()
                .trim()
                .toLowerCase();
            final renewalStatus =
                (data["renewalStatus"] ?? "")
                    .toString()
                    .trim()
                    .toLowerCase();
            if (status == "pending") {
              notificationCount++;
            }
            if (renewalStatus == "pending") {
              notificationCount++;
            }
          }
        }
        // Pending subscription payments
        if (subscriptionsSnapshot.hasData) {
          for (final doc
              in subscriptionsSnapshot.data!.docs) {
            final data =
                doc.data() as Map<String, dynamic>;

            final status = (data["status"] ?? "")
                .toString()
                .trim()
                .toLowerCase();
            if (status == "pending") {
              notificationCount++;
            }
          }
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications,
                size: 28,
              ),
              onPressed: () {
                _showNotifications(context);
              },
            ),
            if (notificationCount > 0)
              Positioned(
                right: 4,
                top: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    notificationCount > 99
                        ? "99+"
                        : notificationCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  },
),
            const SizedBox(width: 8),
          ],
        ),
        // ========================================================
        // DRAWER
        // ========================================================
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ==================================================
              // ADMIN PROFILE
              // ==================================================
              FutureBuilder<Map<String, dynamic>?>(
                future: getAdminData(),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const UserAccountsDrawerHeader(
                      accountName: Text(
                        "Loading...",
                      ),
                      accountEmail: Text(
                        "",
                      ),
                      currentAccountPicture:
                          CircleAvatar(
                        child: Icon(
                          Icons.admin_panel_settings,
                        ),
                      ),
                    );
                  }
                  final data = snapshot.data;
                  final String adminName =
                      data?["fullName"]
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                          ? data!["fullName"].toString()
                          : "Admin";
                  final String adminEmail =
                      data?["email"]
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                          ? data!["email"].toString()
                          : FirebaseAuth
                                  .instance
                                  .currentUser
                                  ?.email ??
                              "MotoFind Administrator";
                  final String profileImage =
                      data?["profileImage"]
                              ?.toString()
                              .trim() ?? "";
                  return UserAccountsDrawerHeader(
                    accountName: Text(
                      adminName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    accountEmail: Text(
                      adminEmail,
                    ),
                    currentAccountPicture:
                        profileImage.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage:
                                    NetworkImage(
                                  profileImage,
                                ),
                              )
                            : const CircleAvatar(
                                child: Icon(
                                  Icons.admin_panel_settings,
                                  size: 32,
                                ),
                              ),
                  );
                },
              ),
              // ==================================================
              // MANAGE USERS
              // ==================================================
              ListTile(
                leading: const Icon(
                  Icons.people,
                ),
                title: const Text(
                  "Manage Users",
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ManageUsers(),
                    ),
                  );
                },
              ),
              // ==================================================
              // STORE APPLICATIONS
              // ==================================================
              ListTile(
                leading: const Icon(
                  Icons.fact_check,
                ),
                title: const Text(
                  "Store Applications",
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const StoreApprovalScreen(),
                    ),
                  );
                },
              ),
              // ==================================================
              // MANAGE STORES
              // ==================================================
              ListTile(
                leading: const Icon(
                  Icons.store,
                ),
                title: const Text(
                  "Manage Stores",
                ),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ManageStoresScreen(),
                    ),
                  );
                },
              ),
              // ==================================================
              // MANAGE SUBSCRIPTIONS
              // ==================================================
              ListTile(
                leading: const Icon(
                  Icons.payment,
                ),
                title: const Text(
                  "Manage Subscriptions",
                ),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ManageSubscriptions(),
                    ),
                  );
                },
              ),
              // ==================================================
              // MANAGE PRODUCTS
              // ==================================================
              ListTile(
                leading: const Icon(
                  Icons.inventory_2,
                ),
                title: const Text(
                  "Manage Products",
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ManageProducts(),
                    ),
                  );
                },
              ),
              // ==================================================
              // REPORTS
              // ==================================================
              ListTile(
                leading: const Icon(
                  Icons.analytics,
                ),
                title: const Text(
                  "Reports",
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ReportsScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              // ==================================================
              // LOGOUT
              // ==================================================
              ListTile(
                leading: const Icon(
                  Icons.logout,
                ),
                title: const Text(
                  "Logout",
                ),
                onTap: () async {
                  final bool? confirmLogout =
                      await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text(
                          "Logout",
                        ),
                        content: const Text(
                          "Are you sure you want to logout?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                                false,
                              );
                            },
                            child: const Text(
                              "Cancel",
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                                true,
                              );
                            },
                            child: const Text(
                              "Logout",
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirmLogout != true) {
                    return;
                  }
                  await AuthService().logout();
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // ========================================================
        // NEW ADMIN DASHBOARD
        // ========================================================
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .snapshots(),
          builder: (context,usersSnapshot,) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("products")
                  .snapshots(),
              builder: (
                context,
                productsSnapshot,
              ) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("sales")
                      .snapshots(),
                  builder: (context,salesSnapshot,) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("subscriptions")
                          .snapshots(),
                      builder: (context,subscriptionsSnapshot,) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("reservations")
                              .snapshots(),
                          builder: (context,reservationsSnapshot,) {
                            return _buildDashboard(
                              usersSnapshot:
                                  usersSnapshot,
                              productsSnapshot:
                                  productsSnapshot,
                              salesSnapshot:
                                  salesSnapshot,
                              subscriptionsSnapshot:
                                  subscriptionsSnapshot,
                              reservationsSnapshot:
                                  reservationsSnapshot,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
  // ============================================================
  // MAIN DASHBOARD
  // ============================================================
  Widget _buildDashboard({
    required AsyncSnapshot<QuerySnapshot> usersSnapshot,
    required AsyncSnapshot<QuerySnapshot> productsSnapshot,
    required AsyncSnapshot<QuerySnapshot> salesSnapshot,
    required AsyncSnapshot<QuerySnapshot>
        subscriptionsSnapshot,
    required AsyncSnapshot<QuerySnapshot>
        reservationsSnapshot,
  }) {
    // ==========================================================
    // USERS
    // ==========================================================
    int totalUsers = 0;
    int totalStoreOwners = 0;
    int pendingStores = 0;
    int approvedStores = 0;
    int rejectedStores = 0;
    if (usersSnapshot.hasData) {
      for (final doc in usersSnapshot.data!.docs) {
        final data =
            doc.data() as Map<String, dynamic>;
        final String role =
            data["role"]
                    ?.toString()
                    .trim()
                    .toLowerCase() ?? "";
        final String status = data["status"]
                    ?.toString()
                    .trim()
                    .toLowerCase() ?? "";
        if (role != "admin") {
          totalUsers++;
        }
        if (role == "store owner") {
          totalStoreOwners++;
          if (status == "pending") {
            pendingStores++;
          } else if (status == "approved") {
            approvedStores++;
          } else if (status == "rejected") {
            rejectedStores++;
          }
        }
      }
    }
    // ==========================================================
    // PRODUCTS
    // ==========================================================
    int totalProducts = 0;
    if (productsSnapshot.hasData) {
      totalProducts =
          productsSnapshot.data!.docs.length;
    }
    // ==========================================================
    // SALES
    // ==========================================================
    double totalSales = 0;
    if (salesSnapshot.hasData) {
      for (final doc in salesSnapshot.data!.docs) {
        final data =
            doc.data() as Map<String, dynamic>;
        totalSales += _readNumber(
          data,
          [
            "totalAmount",
            "total",
            "amount",
            "totalPrice",
          ],
        );
      }
    }
    // ==========================================================
    // SUBSCRIPTIONS
    // ==========================================================
    int pendingSubscriptions = 0;
    int activeSubscriptions = 0;
    int expiredSubscriptions = 0;
    if (subscriptionsSnapshot.hasData) {
      for (final doc
          in subscriptionsSnapshot.data!.docs) {
        final data =
            doc.data() as Map<String, dynamic>;
        String status =
            data["status"]
                    ?.toString()
                    .trim()
                    .toLowerCase() ?? "";
        if (status == "pending") {
          pendingSubscriptions++;
        } else if (status == "approved" ||
            status == "active") {
          activeSubscriptions++;
        } else if (status == "expired") {
          expiredSubscriptions++;
        }
      }
    }
    // ==========================================================
    // RESERVATIONS
    // ==========================================================
    int pendingReservations = 0;
    int activeReservations = 0;
    int completedReservations = 0;
    int cancelledReservations = 0;
    if (reservationsSnapshot.hasData) {
      for (final doc
          in reservationsSnapshot.data!.docs) {
        final data =
            doc.data() as Map<String, dynamic>;
        final String status =
            _getReservationStatus(data);
        if (status == "pending") {
          pendingReservations++;
        } else if (status == "active" ||
            status == "confirmed" ||
            status == "approved") {
          activeReservations++;
        } else if (status == "completed" ||
            status == "complete" ||
            status == "picked up" ||
            status == "pickedup") {
          completedReservations++;
        } else if (status == "cancelled" ||
            status == "canceled" ||
            status == "expired") {
          cancelledReservations++;
        }
      }
    }
    // ==========================================================
    // LOADING / ERROR
    // ==========================================================
    final bool isLoading =
        usersSnapshot.connectionState ==
                ConnectionState.waiting ||
            productsSnapshot.connectionState ==
                ConnectionState.waiting ||
            salesSnapshot.connectionState ==
                ConnectionState.waiting ||
            subscriptionsSnapshot.connectionState ==
                ConnectionState.waiting ||
            reservationsSnapshot.connectionState ==
                ConnectionState.waiting;
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
return LayoutBuilder(
  builder: (context, screenConstraints) {
    final bool isDesktop =
        screenConstraints.maxWidth >= 900;
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 12 : 4),
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: screenConstraints.maxWidth -
                (isDesktop ? 24 : 8),
            height: screenConstraints.maxHeight -
                (isDesktop ? 24 : 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double height = constraints.maxHeight;
                final bool desktop = width >= 600;
                final double summaryGap = desktop ? 8 : 5;
                final double summaryWidth = desktop
                    ? (width - summaryGap * 3) / 4
                    : (width - summaryGap) / 2;
                final double sectionGap = 8;
                final double sectionWidth =
                    (width - sectionGap) / 2;
                final List<Widget> sections = [
                  adminSectionCard(
                    title: "Store Applications",
                    icon: Icons.store_mall_directory,
                    child: Row(
                      children: [
                        Expanded(
                          child: statusSummary(
                            icon: Icons.pending_actions,
                            label: "Pending",
                            value: pendingStores.toString(),
                            color: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: statusSummary(
                            icon: Icons.check_circle,
                            label: "Approved",
                            value: approvedStores.toString(),
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: statusSummary(
                            icon: Icons.cancel,
                            label: "Rejected",
                            value: rejectedStores.toString(),
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  adminSectionCard(
                    title: "Subscriptions",
                    icon: Icons.credit_card,
                    child: Row(
                      children: [
                        Expanded(
                          child: statusSummary(
                            icon: Icons.pending,
                            label: "Pending",
                            value:
                                pendingSubscriptions.toString(),
                            color: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: statusSummary(
                            icon: Icons.verified,
                            label: "Active",
                            value:
                                activeSubscriptions.toString(),
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: statusSummary(
                            icon: Icons.timer_off,
                            label: "Expired",
                            value:
                                expiredSubscriptions.toString(),
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  adminSectionCard(
                    title: "Reservations Overview",
                    icon: Icons.receipt_long,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        reservationProgress(
                          "Pending",
                          pendingReservations,
                          Colors.orange,
                        ),
                        const SizedBox(height: 6),
                        reservationProgress(
                          "Active",
                          activeReservations,
                          Colors.blue,
                        ),
                        const SizedBox(height: 6),
                        reservationProgress(
                          "Completed",
                          completedReservations,
                          Colors.green,
                        ),
                        const SizedBox(height: 6),
                        reservationProgress(
                          "Cancelled",
                          cancelledReservations,
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                  adminSectionCard(
                    title: "System Overview",
                    icon: Icons.analytics,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        systemProgress(
                          label: "Users",
                          value: totalUsers,
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 7),
                        systemProgress(
                          label: "Stores",
                          value: totalStoreOwners,
                          icon: Icons.store,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 7),
                        systemProgress(
                          label: "Products",
                          value: totalProducts,
                          icon: Icons.inventory_2,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 7),
                        systemProgress(
                          label: "Reservations",
                          value: pendingReservations +
                              activeReservations +
                              completedReservations +
                              cancelledReservations,
                          icon: Icons.receipt_long,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                  adminSectionCard(
                    title: "Quick Actions",
                    icon: Icons.dashboard_customize,
child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    quickActionTile(
      icon: Icons.fact_check,
      title: "Store Applications",
      subtitle: "$pendingStores pending",
      color: Colors.orange,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const StoreApprovalScreen(),
          ),
        );
      },
    ),
    const Divider(height: 2),
    quickActionTile(
      icon: Icons.payment,
      title: "Manage Subscriptions",
      subtitle: "$pendingSubscriptions pending",
      color: Colors.blue,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ManageSubscriptions(),
          ),
        );
      },
    ),
    const Divider(height: 2),
    quickActionTile(
      icon: Icons.people,
      title: "Manage Users",
      subtitle: "$totalUsers registered",
      color: Colors.green,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ManageUsers(),
          ),
        );
      },
    ),
  ],
),
                  ),
                ];

                return SizedBox(
                  height: height,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                    
                      const SizedBox(height: 2),
                      SizedBox(height: desktop ? 8 : 5),

                      Wrap(
                        spacing: summaryGap,
                        runSpacing: summaryGap,
                        children: [
                          SizedBox(
                            width: summaryWidth,
                            child: adminSummaryCard(
                              title: "Total Users",
                              value: totalUsers.toString(),
                              icon: Icons.people,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(
                            width: summaryWidth,
                            child: adminSummaryCard(
                              title: "Total Stores",
                              value:
                                  totalStoreOwners.toString(),
                              icon: Icons.store,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(
                            width: summaryWidth,
                            child: adminSummaryCard(
                              title: "Total Products",
                              value: totalProducts.toString(),
                              icon: Icons.inventory_2,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(
                            width: summaryWidth,
                            child: adminSummaryCard(
                              title: "Total Sales",
                              value: NumberFormat.currency(
                                locale: "en_PH",
                                symbol: "₱",
                                decimalDigits: 2,
                              ).format(totalSales),
                              icon: Icons.payments,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: desktop ? 8 : 5),

                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Wrap(
                            spacing: sectionGap,
                            runSpacing: 4,
                            crossAxisAlignment:
                                WrapCrossAlignment.start,
                            children: [
                              for (int i = 0;
                                  i < sections.length;
                                  i++)
                                SizedBox(
                                  width: i == 4 && !desktop
                                      ? width
                                      : sectionWidth,
                                  child: sections[i],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  },
);
}
// ============================================================
// ADMIN SUMMARY CARD
// ============================================================
Widget adminSummaryCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Container(
    constraints: const BoxConstraints(minHeight: 78),
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 10,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF142642),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: const Color(0xFF263D5C),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.16),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: color,
            size: 19,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFB7C4D9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  // ============================================================
  // SECTION CARD - COMPACT UI
  // ============================================================
  Widget adminSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 17),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
  // ============================================================
  // STATUS SUMMARY - COMPACT UI
  // ============================================================
  Widget statusSummary({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 17,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  // ============================================================
  // RESERVATION PROGRESS
  // ============================================================
  Widget reservationProgress(
    String label,
    int value,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value > 0
                  ? (value / _reservationScale(value))
                      .clamp(0.08, 1.0)
                  : 0,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 30,
          child: Text(
            value.toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  // ============================================================
  // SYSTEM PROGRESS
  // ============================================================
  Widget systemProgress({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius:
                BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  alignment:
                      Alignment.centerLeft,
                  widthFactor:
                      value > 0 ? 1.0 : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  // ============================================================
  // QUICK ACTION
  // ============================================================
  Widget quickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
return ListTile(
  dense: true,
  visualDensity: const VisualDensity(
    horizontal: -3,
    vertical: -4,
  ),
  minVerticalPadding: 0,
  minLeadingWidth: 28,
  contentPadding: EdgeInsets.zero,
  leading: Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Icon(
      icon,
      color: color,
      size: 18,
    ),
  ),
  title: Text(
    title,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    ),
  ),
  subtitle: Text(
    subtitle,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(fontSize: 10),
  ),
  trailing: const Icon(
    Icons.arrow_forward_ios,
    size: 12,
  ),
  onTap: onTap,
  );
  }
  // ============================================================
  // NUMBER READER
  // ============================================================
  double _readNumber(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final dynamic value = data[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value != null) {
        final parsed =
            double.tryParse(
          value.toString(),
        );
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0;
  }
  // ============================================================
  // RESERVATION STATUS READER
  // ============================================================
  String _getReservationStatus(
    Map<String, dynamic> data,
  ) {
    final dynamic rawStatus =
        data["status"] ??
        data["reservationStatus"] ??
        data["state"] ?? "";
    return rawStatus
        .toString()
        .trim()
        .toLowerCase();
    }
  // ============================================================
  // RESERVATION BAR SCALE
  // ============================================================
  double _reservationScale(
    int currentValue,
  ) {
    if (currentValue <= 0) {
      return 1;
    }
    return currentValue.toDouble();
  }
void _showNotifications(BuildContext context) {
  final pageNavigator = Navigator.of(context);
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        alignment: Alignment.center,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(
          width: 450,
          height: 450,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .where("role", isEqualTo: "Store Owner")
                .snapshots(),
            builder: (builderContext, usersSnapshot) {
              if (usersSnapshot.hasError) {
                return Center(
                  child: Text("Error: ${usersSnapshot.error}"),
                );
              }

              if (usersSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("subscriptions")
                    .snapshots(),
                builder: (subscriptionContext, subscriptionsSnapshot) {
                  if (subscriptionsSnapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error: ${subscriptionsSnapshot.error}",
                      ),
                    );
                  }

                  if (subscriptionsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final notifications =
                      <Map<String, dynamic>>[];

                  // =========================================
                  // STORE APPLICATIONS AND RENEWALS
                  // =========================================

                  for (final doc in usersSnapshot.data!.docs) {
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final status = (data["status"] ?? "")
                        .toString()
                        .trim()
                        .toLowerCase();

                    final renewalStatus =
                        (data["renewalStatus"] ?? "")
                            .toString()
                            .trim()
                            .toLowerCase();

                    final storeName =
                        (data["storeName"] ?? "Unknown Store")
                            .toString();

                    if (status == "pending") {
                      notifications.add({
                        "type": "new",
                        "title": "New Store Application",
                        "message": "$storeName needs approval.",
                        "icon": Icons.store,
                        "color": Colors.deepOrange,
                        "data": {
                          ...data,
                          "uid": doc.id,
                        },
                      });
                    }

                    if (renewalStatus == "pending") {
                      notifications.add({
                        "type": "renewal",
                        "title": "Renewal Payment",
                        "message":
                            "$storeName submitted a renewal.",
                        "icon": Icons.autorenew,
                        "color": Colors.orange,
                        "data": {
                          ...data,
                          "uid": doc.id,
                        },
                      });
                    }
                  }

                  // =========================================
                  // SUBSCRIPTION PAYMENTS
                  // =========================================

                  for (final doc
                      in subscriptionsSnapshot.data!.docs) {
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final status = (data["status"] ?? "")
                        .toString()
                        .trim()
                        .toLowerCase();

                    if (status != "pending") continue;

                    final storeName =
                        (data["storeName"] ??
                                data["ownerName"] ??
                                "Unknown Store")
                            .toString();

                    final plan = (data["plan"] ?? "")
                        .toString()
                        .trim();

                    notifications.add({
                      "type": "subscription",
                      "title": "New Subscription Payment",
                      "message": plan.isEmpty
                          ? "$storeName submitted a subscription for approval."
                          : "$storeName submitted a $plan subscription for approval.",
                      "icon": Icons.credit_card,
                      "color": Colors.blue,
                      "data": {
                        ...data,
                        "subscriptionId": doc.id,
                      },
                    });
                  }

                  // SHOW EMPTY STATE OR NOTIFICATION LIST
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications,
                              color: Colors.orange,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "Notifications",
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (notifications.isNotEmpty)
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  notifications.length.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: notifications.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.notifications_none,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 12),
                                    Text("No new notifications"),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: notifications.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final notification =
                                      notifications[index];

                                  final type =
                                      notification["type"].toString();

                                  final data =
                                      notification["data"]
                                          as Map<String, dynamic>;

                                  final color =
                                      notification["color"] as Color;

                                  return ListTile(
                                    tileColor: type == "new"
                                        ? Colors.orange
                                            .withOpacity(0.10)
                                        : null,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          color.withOpacity(0.15),
                                      child: Icon(
                                        notification["icon"] as IconData,
                                        color: color,
                                      ),
                                    ),
                                    title: Text(
                                      notification["title"].toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding:
                                          const EdgeInsets.only(top: 4),
                                      child: Text(
                                        notification["message"]
                                            .toString(),
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onTap: () {
                                      // Close the notification dialog.
                                      Navigator.pop(dialogContext);

                                      // Navigate to the correct page.
                                      if (type == "new") {
                                        pageNavigator.push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const StoreApprovalScreen(),
                                          ),
                                        );
                                      } else if (type == "renewal") {
                                        pageNavigator.push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                StoreDetailsScreen(
                                              data: data,
                                            ),
                                          ),
                                        );
                                      } else if (type == "subscription") {
                                        pageNavigator.push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ManageSubscriptions(),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            child: const Text("Close"),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      );
    },
  );
}
  }