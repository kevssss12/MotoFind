
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController searchController =
      TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  String? storeId;
  String searchText = "";
  String selectedPeriod = "All";

  // ============================================================
  // PESO FORMAT
  // ============================================================

  final NumberFormat peso = NumberFormat.currency(
    locale: 'en_US',
    symbol: '₱',
    decimalDigits: 2,
  );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    getStoreId();
  }

  // ============================================================
  // GET STORE ID
  // ============================================================

  Future<void> getStoreId() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!mounted) {
        return;
      }

      if (doc.exists) {
        setState(() {
          storeId = doc.data()?["storeId"]?.toString();
        });
      }
    } catch (e) {
      debugPrint("Error getting store ID: $e");
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // GET SALE DATE
  // ============================================================

  DateTime? getSaleDate(
    Map<String, dynamic> data,
  ) {
    if (data["soldAt"] is Timestamp) {
      return (data["soldAt"] as Timestamp).toDate();
    }

    return null;
  }

  // ============================================================
  // GET SALE STATUS
  // ============================================================

  String getSaleStatus(
    Map<String, dynamic> data,
  ) {
    final String saleType =
        data["saleType"]?.toString().toLowerCase() ?? "";

    if (saleType == "reservation" ||
        saleType == "reserve") {
      return "Reserve";
    }

    return "Walk-in";
  }

  // ============================================================
  // GET SOLD
  // ============================================================

  int getSold(
    Map<String, dynamic> data,
  ) {
    return (data["quantity"] as num?)?.toInt() ?? 0;
  }

  // ============================================================
  // GET PRICE
  // ============================================================

  double getPrice(
    Map<String, dynamic> data,
  ) {
    return (data["price"] as num?)?.toDouble() ?? 0;
  }

  // ============================================================
  // GET TOTAL
  // ============================================================

  double getTotal(
    Map<String, dynamic> data,
  ) {
    if (data["total"] is num) {
      return (data["total"] as num).toDouble();
    }

    return getSold(data) * getPrice(data);
  }

  // ============================================================
  // GET CUSTOMER
  // ============================================================

  String getCustomerName(
    Map<String, dynamic> data,
  ) {
    final String customer =
        data["customerName"]?.toString().trim() ?? "";

    if (customer.isEmpty) {
      return "Walk-in Customer";
    }

    return customer;
  }

  // ============================================================
  // CHECK PERIOD
  // ============================================================

  bool matchesPeriod(DateTime? saleDate) {
    if (saleDate == null) {
      return false;
    }

    final DateTime now = DateTime.now();

    switch (selectedPeriod) {
      case "All":
        return true;

      case "Today":
        return saleDate.year == now.year &&
            saleDate.month == now.month &&
            saleDate.day == now.day;

      case "Week":
        final DateTime startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(
          Duration(
            days: now.weekday - 1,
          ),
        );

        return !saleDate.isBefore(startOfWeek);

      case "Month":
        return saleDate.year == now.year &&
            saleDate.month == now.month;

      case "6 Months":
        final DateTime sixMonthsAgo = DateTime(
          now.year,
          now.month - 6,
          now.day,
        );

        return !saleDate.isBefore(sixMonthsAgo);

      case "1 Year":
        final DateTime oneYearAgo = DateTime(
          now.year - 1,
          now.month,
          now.day,
        );

        return !saleDate.isBefore(oneYearAgo);

      default:
        return true;
    }
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget buildStatusBadge(
    String status,
  ) {
    final bool isReserve = status == "Reserve";

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isReserve
            ? Colors.blue.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isReserve
              ? Colors.blue
              : Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // PERIOD FILTER
  // ============================================================

  Widget buildPeriodFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.date_range,
            size: 22,
          ),

          const SizedBox(width: 10),

          const Text(
            "View:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedPeriod,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: "All",
                  child: Text("All"),
                ),
                DropdownMenuItem(
                  value: "Today",
                  child: Text("Today"),
                ),
                DropdownMenuItem(
                  value: "Week",
                  child: Text("This Week"),
                ),
                DropdownMenuItem(
                  value: "Month",
                  child: Text("This Month"),
                ),
                DropdownMenuItem(
                  value: "6 Months",
                  child: Text("Last 6 Months"),
                ),
                DropdownMenuItem(
                  value: "1 Year",
                  child: Text("Last 1 Year"),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  selectedPeriod = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget buildSummaryCard(
    List<Map<String, dynamic>> transactions,
  ) {
    double overallRevenue = 0;
    int totalSold = 0;

    for (final data in transactions) {
      overallRevenue += getTotal(data);
      totalSold += getSold(data);
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 18,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 24,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Transactions",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${transactions.length}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 1,
              height: 55,
              color: Colors.grey.shade300,
            ),

            Expanded(
              child: Column(
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    size: 24,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Total Sold",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$totalSold",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 1,
              height: 55,
              color: Colors.grey.shade300,
            ),

            Expanded(
              child: Column(
                children: [
                  const Icon(
                    Icons.payments,
                    size: 24,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Revenue",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      peso.format(overallRevenue),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE SALE CARD
  // ============================================================

  Widget buildMobileSaleCard(
    Map<String, dynamic> data,
  ) {
    final String productName =
        data["productName"]?.toString() ??
            "Unknown Product";

    final int sold = getSold(data);

    final double price = getPrice(data);

    final double total = getTotal(data);

    final String status =
        getSaleStatus(data);

    final String customer =
        getCustomerName(data);

    final DateTime? saleDate =
        getSaleDate(data);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 6,
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // PRODUCT + STATUS
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    productName,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                buildStatusBadge(status),
              ],
            ),

            const SizedBox(height: 12),

            Divider(
              color: Colors.grey.shade300,
              height: 1,
            ),

            const SizedBox(height: 12),

            // ==================================================
            // CUSTOMER
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Customer",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // SALE DETAILS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: buildDetailItem(
                    icon: Icons.shopping_cart_outlined,
                    label: "Sold",
                    value: "$sold",
                  ),
                ),

                Expanded(
                  child: buildDetailItem(
                    icon: Icons.sell_outlined,
                    label: "Price",
                    value: peso.format(price),
                  ),
                ),

                Expanded(
                  child: buildDetailItem(
                    icon: Icons.payments_outlined,
                    label: "Total",
                    value: peso.format(total),
                    bold: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // DATE
            // ==================================================

            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    saleDate == null
                        ? "Date: N/A"
                        : DateFormat(
                            "MMM dd, yyyy • hh:mm a",
                          ).format(saleDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE DETAIL ITEM
  // ============================================================

  Widget buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool bold = false,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                alignment:
                    Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold
                        ? FontWeight.bold
                        : FontWeight.w600,
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
  // DESKTOP TABLE HEADER
  // ============================================================

  Widget buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      color: Colors.grey.shade200,
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "ITEM",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              "STATUS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 1,
            child: Text(
              "SOLD",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              "PRICE",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              "TOTAL",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              "DATE",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP SALE ROW
  // ============================================================

  Widget buildSaleRow(
    Map<String, dynamic> data,
  ) {
    final String productName =
        data["productName"]?.toString() ??
            "Unknown Product";

    final int sold = getSold(data);

    final double price = getPrice(data);

    final double total = getTotal(data);

    final String status =
        getSaleStatus(data);

    final DateTime? saleDate =
        getSaleDate(data);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              productName,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Align(
              alignment:
                  Alignment.centerLeft,
              child:
                  buildStatusBadge(status),
            ),
          ),

          Expanded(
            flex: 1,
            child: Text(
              "$sold",
              textAlign:
                  TextAlign.center,
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              peso.format(price),
              textAlign:
                  TextAlign.right,
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              peso.format(total),
              textAlign:
                  TextAlign.right,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              saleDate == null
                  ? "N/A"
                  : DateFormat(
                      "MMM dd, yyyy\nhh:mm a",
                    ).format(saleDate),
              textAlign:
                  TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESPONSIVE SALES LIST
  // ============================================================

  Widget buildSalesContent(
    List<Map<String, dynamic>> transactions,
  ) {
    return Expanded(
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          // ======================================================
          // MOBILE
          // ======================================================

          if (constraints.maxWidth < 700) {
            return ListView.builder(
              padding:
                  const EdgeInsets.only(
                top: 2,
                bottom: 20,
              ),
              itemCount:
                  transactions.length,
              itemBuilder:
                  (context, index) {
                return buildMobileSaleCard(
                  transactions[index],
                );
              },
            );
          }

          // ======================================================
          // DESKTOP / TABLET
          // ======================================================

          return Column(
            children: [
              buildTableHeader(),

              Expanded(
                child: ListView.builder(
                  padding:
                      EdgeInsets.zero,
                  itemCount:
                      transactions.length,
                  itemBuilder:
                      (context, index) {
                    return buildSaleRow(
                      transactions[index],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  
 
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0D47A1);
    const Color darkBlue = Color(0xFF062B63);
    const Color pageBackground = Color(0xFFF5F8FC);
    const Color containerColor =
        Color.fromARGB(255, 209, 209, 238);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Sales Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: true,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        color: pageBackground,
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE1E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: darkBlue.withOpacity(0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // HEADER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        color: containerColor,
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE1E8F0),
                          ),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.point_of_sale,
                            size: 30,
                            color: primaryBlue,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Sales Management",
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: darkBlue,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "View transactions and revenue",
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

                    // SEARCH
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        14,
                        12,
                        14,
                        4,
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText:
                              "Search product or customer...",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: primaryBlue,
                          ),
                          suffixIcon: searchText.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      searchText = "";
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.clear,
                                  ),
                                )
                              : null,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE1E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: primaryBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchText =
                                value.toLowerCase().trim();
                          });
                        },
                      ),
                    ),

                    // PERIOD FILTER
                    buildPeriodFilter(),

                    const SizedBox(height: 4),

                    // SALES STREAM
                    Expanded(
                      child: storeId == null
                          ? const Center(
                              child:
                                  CircularProgressIndicator(
                                color: primaryBlue,
                              ),
                            )
                          : StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("sales")
                                  .where(
                                    "storeId",
                                    isEqualTo: storeId,
                                  )
                                  .snapshots(),
                              builder: (
                                context,
                                snapshot,
                              ) {
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.all(20),
                                      child: Text(
                                        "Error loading sales:\n"
                                        "${snapshot.error}",
                                        textAlign:
                                            TextAlign.center,
                                      ),
                                    ),
                                  );
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child:
                                        CircularProgressIndicator(
                                      color: primaryBlue,
                                    ),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text(
                                        "No sales yet.",
                                      ),
                                    ),
                                  );
                                }

                                // GET SALES
                                final List<
                                    Map<String, dynamic>
                                > transactions = [];

                                for (final doc
                                    in snapshot.data!.docs) {
                                  final data =
                                      doc.data()
                                          as Map<String, dynamic>;

                                  transactions.add({
                                    ...data,
                                    "_docId": doc.id,
                                  });
                                }

                                // FILTER
                                final filteredTransactions =
                                    transactions.where((data) {
                                  final String productName =
                                      (data["productName"] ?? "")
                                          .toString()
                                          .toLowerCase();

                                  final String customerName =
                                      (data["customerName"] ??
                                              "walk-in customer")
                                          .toString()
                                          .toLowerCase();

                                  final DateTime? saleDate =
                                      getSaleDate(data);

                                  final bool matchesSearch =
                                      productName.contains(
                                            searchText,
                                          ) ||
                                          customerName.contains(
                                            searchText,
                                          );

                                  final bool matchesDate =
                                      matchesPeriod(saleDate);

                                  return matchesSearch &&
                                      matchesDate;
                                }).toList();

                                // SORT LATEST FIRST
                                filteredTransactions.sort(
                                  (a, b) {
                                    final DateTime? dateA =
                                        getSaleDate(a);

                                    final DateTime? dateB =
                                        getSaleDate(b);

                                    if (dateA == null &&
                                        dateB == null) {
                                      return 0;
                                    }

                                    if (dateA == null) {
                                      return 1;
                                    }

                                    if (dateB == null) {
                                      return -1;
                                    }

                                    return dateB.compareTo(dateA);
                                  },
                                );

                                // SUMMARY AND SALES
                                return Column(
                                  children: [
                                    buildSummaryCard(
                                      filteredTransactions,
                                    ),

                                    const SizedBox(height: 2),

                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 5,
                                      ),
                                      child: Align(
                                        alignment:
                                            Alignment.centerLeft,
                                        child: Text(
                                          "Showing: $selectedPeriod",
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 13,
                                            color: darkBlue,
                                          ),
                                        ),
                                      ),
                                    ),

                                    if (filteredTransactions.isEmpty)
                                      const Expanded(
                                        child: Center(
                                          child: Padding(
                                            padding:
                                                EdgeInsets.all(20),
                                            child: Text(
                                              "No sales found for this period.",
                                              textAlign:
                                                  TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      buildSalesContent(
                                        filteredTransactions,
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
        ),
      ),
    );
  }
}
