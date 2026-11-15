import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() =>
      _ReportsScreenState();
}
class _ReportsScreenState extends State<ReportsScreen> {
@override
Widget build(BuildContext context) {
  final reports = [
    {
      "title": "User Report",
      "subtitle": "View user statistics",
      "icon": Icons.people,
      "page": const UserReportScreen(),
    },
    {
      "title": "Sales Report",
      "subtitle": "View sales and transactions",
      "icon": Icons.attach_money,
      "page": const SalesReportScreen(),
    },
    {
      "title": "Inventory Report",
      "subtitle": "View products and stock",
      "icon": Icons.inventory_2,
      "page": const InventoryReportScreen(),
    },
    {
      "title": "Store Report",
      "subtitle": "View store statistics",
      "icon": Icons.store,
      "page": const StoreReportScreen(),
    },
    {
      "title": "Subscription Report",
      "subtitle": "View subscription statistics",
      "icon": Icons.payment,
      "page": const SubscriptionReportScreen(),
    },
    {
      "title": "Renewal Report",
      "subtitle": "View renewal statistics",
      "icon": Icons.autorenew,
      "page": const RenewalReportScreen(),
    },
  ];
  return Scaffold(
    appBar: AppBar(
      title: const Text("Reports"),
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),

                child: Column(
                  children: [
                    // REPORT LIST
                   Expanded(
                  child: ListView.builder(
                   padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                  final report = reports[index];
                 return _reportTile(
               context,
            title: report["title"].toString(),
          subtitle: report["subtitle"].toString(),
         icon: report["icon"] as IconData,
        page: report["page"] as Widget,
      );
    },
  ),
),    ],
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
  // REPORT TILE
  // ============================================================
  Widget _reportTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget page,
  }) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 3,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize: 17,
          ),
        ),
        subtitle: Text(
          subtitle,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => page,
            ),
          );
        },
      ),
    );
  }
}
// ============================================================
// USER REPORT
// ============================================================
class UserReportScreen extends StatelessWidget {
  const UserReportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Report"),
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
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .snapshots(),
                    builder: (context, snapshot) {
                      // ==========================================
                      // LOADING
                      // ==========================================
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      // ==========================================
                      // ERROR
                      // ==========================================
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error: ${snapshot.error}",
                          ),
                        );
                      }
                      // ==========================================
                      // NO DATA
                      // ==========================================
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text(
                            "No user data found.",
                          ),
                        );
                      }
                      // ==========================================
                      // USER DATA
                      // ==========================================
                      final users = snapshot.data!.docs;
                      int customers = 0;
                      int storeOwners = 0;
                      int activeUsers = 0;
                      int disabledUsers = 0;
                      for (final doc in users) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final role =
                            data["role"]?.toString() ?? "";
                        final status =
                            data["status"]?.toString() ?? "";
                        // Count Customers
                        if (role == "Customer") {
                          customers++;
                        }
                        // Count Store Owners
                        if (role == "Store Owner") {
                          storeOwners++;
                        }
                        // Count Active and Disabled Users
                        if (status.toLowerCase() ==
                            "disabled") {
                          disabledUsers++;
                        } else {
                          activeUsers++;
                        }
                      }
                      // ==========================================
                      // REPORT CONTENT
                      // ==========================================
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _statCard(
                            title: "Total Users",
                            value: users.length.toString(),
                            icon: Icons.people,
                          ),
                          _statCard(
                            title: "Customers",
                            value: customers.toString(),
                            icon: Icons.person,
                          ),
                          _statCard(
                            title: "Store Owners",
                            value: storeOwners.toString(),
                            icon: Icons.store,
                          ),
                          _statCard(
                            title: "Active Users",
                            value: activeUsers.toString(),
                            icon: Icons.check_circle,
                          ),
                          _statCard(
                            title: "Disabled Users",
                            value: disabledUsers.toString(),
                            icon: Icons.block,
                          ),
                        ],
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
  // ============================================================
  // STAT CARD
  // ============================================================
  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
// ============================================================
// SALES REPORT
// ============================================================
class SalesReportScreen extends StatelessWidget {
  const SalesReportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Report"),
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
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("sales")
                        .snapshots(),
                    builder: (context, snapshot) {
                      // ==========================================
                      // LOADING
                      // ==========================================
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      // ==========================================
                      // ERROR
                      // ==========================================
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error: ${snapshot.error}",
                          ),
                        );
                      }
                      // ==========================================
                      // SALES DATA
                      // ==========================================
                      final sales =
                          snapshot.data?.docs ?? [];
                      double totalSales = 0;
                      for (final doc in sales) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        totalSales += _getAmount(data);
                      }
                      // ==========================================
                      // REPORT CONTENT
                      // ==========================================
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _statCard(
                            title: "Total Sales",
                            value:
                                "₱${totalSales.toStringAsFixed(2)}",
                            icon: Icons.attach_money,
                          ),
                          _statCard(
                            title: "Total Transactions",
                            value: sales.length.toString(),
                            icon: Icons.receipt_long,
                          ),
                        ],
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
  // ============================================================
  // GET SALES AMOUNT
  // ============================================================
  double _getAmount(
    Map<String, dynamic> data,
  ) {
    final fields = [
      "totalAmount",
      "total",
      "amount",
      "grandTotal",
      "price",
    ];
    for (final field in fields) {
      final value = data[field];
      if (value is num) {
        return value.toDouble();
      }
      if (value != null) {
        final parsed =
            double.tryParse(value.toString());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0;
  }
  // ============================================================
  // STAT CARD
  // ============================================================
  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
// ============================================================
// INVENTORY REPORT
// ============================================================
class InventoryReportScreen extends StatelessWidget {
  const InventoryReportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Report"),
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
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),

                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("products")
                        .snapshots(),
                    builder: (context, snapshot) {
                      // ==========================================
                      // LOADING
                      // ==========================================
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      // ==========================================
                      // ERROR
                      // ==========================================
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error: ${snapshot.error}",
                          ),
                        );
                      }
                      // ==========================================
                      // PRODUCT DATA
                      // ==========================================
                      final products =
                          snapshot.data?.docs ?? [];
                      int totalStocks = 0;
                      int lowStock = 0;
                      int outOfStock = 0;
                      for (final doc in products) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final stock =
                            (data["stock"] as num?)
                                    ?.toInt() ??
                                0;
                        final alertStock =
                            (data["alertStock"] as num?)
                                    ?.toInt() ??
                                0;
                        totalStocks += stock;
                        if (stock <= 0) {
                          outOfStock++;
                        } else if (stock <= alertStock) {
                          lowStock++;
                        }
                      }
                      // ==========================================
                      // REPORT CONTENT
                      // ==========================================
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _statCard(
                            "Total Products",
                            products.length.toString(),
                            Icons.inventory_2,
                          ),
                          _statCard(
                            "Total Stocks",
                            totalStocks.toString(),
                            Icons.inventory,
                          ),
                          _statCard(
                            "Low Stock",
                            lowStock.toString(),
                            Icons.warning,
                          ),
                          _statCard(
                            "Out of Stock",
                            outOfStock.toString(),
                            Icons.remove_shopping_cart,
                          ),
                        ],
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
  // ============================================================
  // STAT CARD
  // ============================================================
  Widget _statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
// ============================================================
// STORE REPORT
// ============================================================
class StoreReportScreen extends StatelessWidget {
  const StoreReportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Store Report"),
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
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .where(
                          "role",
                          isEqualTo: "Store Owner",
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      // ==========================================
                      // LOADING
                      // ==========================================
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      // ==========================================
                      // ERROR
                      // ==========================================
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error: ${snapshot.error}",
                          ),
                        );
                      }
                      // ==========================================
                      // STORE DATA
                      // ==========================================
                      final stores =
                          snapshot.data?.docs ?? [];
                      int approved = 0;
                      int pending = 0;
                      int disabled = 0;
                      for (final doc in stores) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final status =
                            data["status"]?.toString() ?? "";
                        if (status == "Approved") {
                          approved++;
                        } else if (status == "Pending") {
                          pending++;
                        } else if (status == "Disabled") {
                          disabled++;
                        }
                      }
                      // ==========================================
                      // REPORT CONTENT
                      // ==========================================
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _statCard(
                            "Total Stores",
                            stores.length.toString(),
                            Icons.store,
                          ),
                          _statCard(
                            "Approved Stores",
                            approved.toString(),
                            Icons.check_circle,
                          ),
                          _statCard(
                            "Pending Stores",
                            pending.toString(),
                            Icons.pending,
                          ),
                          _statCard(
                            "Disabled Stores",
                            disabled.toString(),
                            Icons.block,
                          ),
                        ],
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
  // ============================================================
  // STAT CARD
  // ============================================================
  Widget _statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
// ============================================================
// SUBSCRIPTION REPORT
// ============================================================
class SubscriptionReportScreen extends StatelessWidget {
  const SubscriptionReportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subscription Report"),
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
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),

                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("subscriptions")
                        .snapshots(),
                    builder: (context, snapshot) {
                      // ==========================================
                      // LOADING
                      // ==========================================
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      // ==========================================
                      // ERROR
                      // ==========================================
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error: ${snapshot.error}",
                          ),
                        );
                      }
                      // ==========================================
                      // SUBSCRIPTION DATA
                      // ==========================================
                      final subscriptions =
                          snapshot.data?.docs ?? [];
                      int approved = 0;
                      int pending = 0;
                      int rejected = 0;
                      double revenue = 0;
                      for (final doc in subscriptions) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final status =
                            data["status"]?.toString() ?? "";
                        if (status == "Approved") {
                          approved++;
                          revenue += _getAmount(data);
                        } else if (status == "Pending") {
                          pending++;
                        } else if (status == "Rejected") {
                          rejected++;
                        }
                      }
                      // ==========================================
                      // REPORT CONTENT
                      // ==========================================
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _statCard(
                            "Approved",
                            approved.toString(),
                            Icons.check_circle,
                          ),
                          _statCard(
                            "Pending",
                            pending.toString(),
                            Icons.pending,
                          ),
                          _statCard(
                            "Rejected",
                            rejected.toString(),
                            Icons.cancel,
                          ),
                          _statCard(
                            "Subscription Revenue",
                            "₱${revenue.toStringAsFixed(2)}",
                            Icons.payments,
                          ),
                        ],
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
  // ============================================================
  // GET SUBSCRIPTION AMOUNT
  // ============================================================
  double _getAmount(
    Map<String, dynamic> data,
  ) {
    final value = data["amount"];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(
          value?.toString() ?? "",
        ) ??
        0;
  }
  // ============================================================
  // STAT CARD
  // ============================================================
  Widget _statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
// ============================================================
// RENEWAL REPORT
// ============================================================
class RenewalReportScreen extends StatelessWidget {
  const RenewalReportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Renewal Report"),
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
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .where(
                          "role",
                          isEqualTo: "Store Owner",
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      // ==========================================
                      // LOADING
                      // ==========================================
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      // ==========================================
                      // ERROR
                      // ==========================================
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error: ${snapshot.error}",
                          ),
                        );
                      }
                      // ==========================================
                      // STORE DATA
                      // ==========================================
                      final stores =
                          snapshot.data?.docs ?? [];
                      int pendingRenewals = 0;
                      int advanceRenewals = 0;
                      int expiredRenewals = 0;
                      final now = DateTime.now();
                      for (final doc in stores) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final renewalStatus =
                            data["renewalStatus"]
                                ?.toString()
                                .toLowerCase();
                        if (renewalStatus == "pending") {
                          pendingRenewals++;
                          final endValue =
                              data["subscriptionEnd"];
                          if (endValue is Timestamp) {
                            final endDate =
                                endValue.toDate();
                            if (endDate.isAfter(now)) {
                              advanceRenewals++;
                            } else {
                              expiredRenewals++;
                            }
                          }
                        }
                      }
                      // ==========================================
                      // REPORT CONTENT
                      // ==========================================
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _statCard(
                            "Pending Renewals",
                            pendingRenewals.toString(),
                            Icons.autorenew,
                          ),
                          _statCard(
                            "Advance Renewals",
                            advanceRenewals.toString(),
                            Icons.update,
                          ),
                          _statCard(
                            "Expired Renewals",
                            expiredRenewals.toString(),
                            Icons.warning,
                          ),
                        ],
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
  // ============================================================
  // STAT CARD
  // ============================================================
  Widget _statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}