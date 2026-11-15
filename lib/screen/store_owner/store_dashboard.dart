import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'inventory_screen.dart';
import 'reserved_orders_screen.dart';
import 'sales_screen.dart';
import 'store_profile.dart';
import 'add_product.dart';
import 'subscription_screen.dart';

import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class StoreDashboard extends StatefulWidget {
  const StoreDashboard({super.key});

  @override
  State<StoreDashboard> createState() => _StoreDashboardState();
}

class _StoreDashboardState extends State<StoreDashboard> {
  final FirestoreService firestoreService = FirestoreService();
  final GlobalKey<ScaffoldState> _scaffoldKey =
    GlobalKey<ScaffoldState>();
    bool _isSidebarExpanded = false;

  final AuthService authService = AuthService();
  
  // MotoFind theme colors
  static const Color motoNavy = Color(0xFF0B1730);
  static const Color motoDarkBlue = Color(0xFF142642);
  static const Color motoBackground = Color(0xFFF0F3F8);


  // ============================================================
  // OWNER / STORE INFORMATION
  // ============================================================

  String ownerName = 'Store Owner';
  String storeName = 'MotoFind Store';

  String? storeId;
  String? ownerId;

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController searchController =
      TextEditingController();

  String searchText = '';

  // ============================================================
  // SALES OVERVIEW FILTER
  // ============================================================

  String selectedSalesPeriod = 'Week';

  // ============================================================
  // CURRENCY
  // ============================================================

  final NumberFormat peso = NumberFormat.currency(
    locale: 'en_US',
    symbol: '₱',
    decimalDigits: 2,
  );

  // ============================================================
  // GET OWNER INFO
  // ============================================================

  Future<void> getOwnerInfo() async {
    final user = authService.currentUser;

    if (user == null) {
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists || !mounted) {
        return;
      }

      final data = doc.data();

      setState(() {
        ownerName =
            data?['fullName']?.toString().trim().isNotEmpty == true
                ? data!['fullName'].toString().trim()
                : 'Store Owner';

        storeName =
            data?['storeName']?.toString().trim().isNotEmpty == true
                ? data!['storeName'].toString().trim()
                : 'MotoFind Store';
      });

      debugPrint('OWNER NAME: $ownerName');
      debugPrint('STORE NAME: $storeName');
    } catch (e) {
      debugPrint('Error getting owner info: $e');
    }
  }

  // ============================================================
  // GET STORE ID
  // ============================================================

  Future<void> getStoreId() async {
    final user = authService.currentUser;

    if (user == null) {
      return;
    }

    ownerId = user.uid;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) {
        return;
      }

      if (!doc.exists) {
        return;
      }

      final data = doc.data();

      setState(() {
        storeId = data?['storeId']?.toString();
        ownerId = user.uid;
      });

      debugPrint('STORE ID: $storeId');
      debugPrint('OWNER ID: $ownerId');
    } catch (e) {
      debugPrint('Error getting store ID: $e');
    }
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    getStoreId();
    getOwnerInfo();

   
Future.microtask(() async {
  try {
    final user = authService.currentUser;

    if (user != null) {
      await firestoreService.checkSubscriptionExpiration(
        user.uid,
      );
    }
  } catch (e) {
    debugPrint(
      'Dashboard initialization error: $e',
    );
  }
});
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
  // FORMAT DATE
  // ============================================================

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Not set';
    }

    return DateFormat(
      'MMM dd, yyyy',
    ).format(timestamp.toDate());
  }

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

    final Duration difference = endDate.difference(now);

    return (difference.inHours / 24).ceil();
  }

  // ============================================================
  // GET SUBSCRIPTION END DATE
  // ============================================================

  Timestamp? getSubscriptionEndDate(
    Map<String, dynamic> data,
  ) {
    final dynamic subscriptionEnd =
        data['subscriptionEnd'];

    if (subscriptionEnd is Timestamp) {
      return subscriptionEnd;
    }

    final dynamic subscriptionEndDate =
        data['subscriptionEndDate'];

    if (subscriptionEndDate is Timestamp) {
      return subscriptionEndDate;
    }

    return null;
  }

  // ============================================================
  // GET SALE DATE
  // Supports:
  // createdAt
  // saleDate
  // date
  // ============================================================

  DateTime? getSaleDate(
    Map<String, dynamic> data,
  ) {
    final dynamic createdAt = data['createdAt'];

    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }

    final dynamic saleDate = data['saleDate'];

    if (saleDate is Timestamp) {
      return saleDate.toDate();
    }

    final dynamic date = data['date'];

    if (date is Timestamp) {
      return date.toDate();
    }

    return null;
  }

  // ============================================================
  // GET PRODUCT NAME FROM SALE
  // ============================================================

  String getSaleProductName(
    Map<String, dynamic> data,
  ) {
    final String productName =
        data['productName']?.toString().trim() ?? '';

    if (productName.isNotEmpty) {
      return productName;
    }

    final String name =
        data['name']?.toString().trim() ?? '';

    if (name.isNotEmpty) {
      return name;
    }

    return 'Unknown Product';
  }

  // ============================================================
  // GET SALE QUANTITY
  // ============================================================

  int getSaleQuantity(
    Map<String, dynamic> data,
  ) {
    final dynamic quantity = data['quantity'];

    if (quantity is num) {
      return quantity.toInt();
    }

    return 1;
  }

  // ============================================================
  // GET SALE TOTAL
  // ============================================================

  double getSaleTotal(
    Map<String, dynamic> data,
  ) {
    final dynamic total = data['total'];

    if (total is num) {
      return total.toDouble();
    }

    final dynamic amount = data['amount'];

    if (amount is num) {
      return amount.toDouble();
    }

    final dynamic totalAmount = data['totalAmount'];

    if (totalAmount is num) {
      return totalAmount.toDouble();
    }

    return 0;
  }

  // ============================================================
  // NOTIFICATION DIALOG
  // LOW STOCK ONLY
  // ============================================================
void showNotificationBill(
  List<QueryDocumentSnapshot> lowStocks, {
  List<QueryDocumentSnapshot> reservations = const [],
  Map<String, dynamic>? subscriptionData,
}) {
  final Timestamp? endDate = subscriptionData == null
      ? null
      : getSubscriptionEndDate(subscriptionData);

  final String subscriptionStatus =
      subscriptionData?['subscriptionStatus']?.toString() ?? '';

  final int daysRemaining = getDaysRemaining(endDate);

  final bool subscriptionAlert =
      subscriptionStatus.toLowerCase() == 'approved' &&
      endDate != null &&
      DateTime.now().isBefore(endDate.toDate()) &&
      daysRemaining <= 5;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: Colors.orange,
            ),
            SizedBox(width: 8),
            Expanded(child: Text('Notifications')),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // RESERVATION ALERTS
                if (reservations.isNotEmpty) ...[
                  const Text(
                    'New Reservation Alerts',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...reservations.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final productName =
                        data['productName']?.toString() ??
                        data['partName']?.toString() ??
                        data['name']?.toString() ??
                        'Motorcycle Part';

                    final customerName =
                        data['customerName']?.toString() ??
                        data['userName']?.toString() ??
                        data['fullName']?.toString() ??
                        'Customer';

                    final status =
                        data['status']?.toString() ?? 'Pending';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.blue,
                          size: 28,
                        ),
                        title: Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Customer: $customerName\nStatus: $status',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ReservedOrdersScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  const Divider(height: 24),
                ],

                // LOW STOCK ALERTS
                if (lowStocks.isNotEmpty) ...[
                  const Text(
                    'Low Stock Alerts',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...lowStocks.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final productName =
                        data['name']?.toString() ??
                        'Unknown Product';

                    final stock =
                        (data['stock'] as num?)?.toInt() ?? 0;

                    final alertStock =
                        (data['alertStock'] as num?)?.toInt() ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.orange,
                          size: 28,
                        ),
                        title: Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Stock: $stock\nAlert level: $alertStock',
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InventoryScreen(
                                initialProductId: doc.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  const Divider(height: 24),
                ],

                // SUBSCRIPTION EXPIRATION ALERT
                if (subscriptionAlert) ...[
                  const Text(
                    'Subscription Alert',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(
                        Icons.card_membership,
                        color: Colors.deepOrange,
                        size: 28,
                      ),
                      title: const Text(
                        'Subscription Expiring Soon',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        daysRemaining == 0
                            ? 'Your subscription expires today.'
                            : 'Your subscription expires in '
                                '$daysRemaining day(s).',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                if (lowStocks.isEmpty &&
                    reservations.isEmpty &&
                    !subscriptionAlert)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No notifications.'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

// ============================================================
// NOTIFICATION BELL
// ============================================================

Widget buildNotificationBell() {
  final user = authService.currentUser;

  if (user == null) {
    return const IconButton(
      onPressed: null,
      icon: Icon(Icons.notifications_none),
    );
  }

  if (storeId == null || storeId!.isEmpty) {
    return const IconButton(
      onPressed: null,
      icon: Icon(Icons.notifications_none),
    );
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('reservations')
        .where('storeId', isEqualTo: storeId)
        .snapshots(),
    builder: (context, reservationSnapshot) {
      final List<QueryDocumentSnapshot> activeReservations = [];

      if (reservationSnapshot.hasData) {
        for (final doc in reservationSnapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status =
              data['status']?.toString().toLowerCase() ?? '';

          if (status == 'pending' ||
              status == 'active' ||
              status == 'reserved') {
            activeReservations.add(doc);
          }
        }
      }

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('storeId', isEqualTo: storeId)
            .snapshots(),
        builder: (context, productSnapshot) {
          final List<QueryDocumentSnapshot> lowStocks = [];

          if (productSnapshot.hasData) {
            for (final doc in productSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;

              final int stock =
                  (data['stock'] as num?)?.toInt() ?? 0;

              final int alertStock =
                  (data['alertStock'] as num?)?.toInt() ?? 0;

              if (stock <= alertStock) {
                lowStocks.add(doc);
              }
            }
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              final Map<String, dynamic>? subscriptionData =
                  userSnapshot.data?.data();

              final Timestamp? endDate = subscriptionData == null
                  ? null
                  : getSubscriptionEndDate(subscriptionData);

              final String status =
                  subscriptionData?['subscriptionStatus']
                          ?.toString() ??
                      '';

              final int daysRemaining = getDaysRemaining(endDate);

              final bool subscriptionAlert =
                  status.toLowerCase() == 'approved' &&
                  endDate != null &&
                  DateTime.now().isBefore(endDate.toDate()) &&
                  daysRemaining <= 5;

              final int notificationCount =
                  activeReservations.length +
                  lowStocks.length +
                  (subscriptionAlert ? 1 : 0);

              return IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  showNotificationBill(
                    lowStocks,
                    reservations: activeReservations,
                    subscriptionData: subscriptionData,
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      notificationCount > 0
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      size: 28,
                      color: notificationCount > 0
                          ? Colors.orange
                          : null,
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context)
                                  .scaffoldBackgroundColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$notificationCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
  // ============================================================
  // BILL BUTTON
  // ============================================================

  Widget buildBillButton() {
    final user = authService.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    return IconButton(
      tooltip: 'Bill',
      icon: const Icon(
        Icons.receipt_long,
        size: 28,
      ),
      onPressed: showBillDialog,
    );
  }

  // ============================================================
  // SHOW BILL
  // ============================================================

  void showBillDialog() {
    final user = authService.currentUser;

    if (user == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StreamBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Bill'),
                content: Text(
                  'Error loading subscription:\n${snapshot.error}',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child: const Text(
                      'Close',
                    ),
                  ),
                ],
              );
            }

            if (!snapshot.hasData ||
                !snapshot.data!.exists) {
              return AlertDialog(
                title: const Text('Bill'),
                content: const Text(
                  'User information not found.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child: const Text(
                      'Close',
                    ),
                  ),
                ],
              );
            }

            final Map<String, dynamic> data =
                snapshot.data!.data() ??
                    <String, dynamic>{};

            final String status =
                data['subscriptionStatus']?.toString() ??
                    'Not Active';

            final String plan =
                data['subscriptionPlan']?.toString() ??
                    'No Plan';

            final Timestamp? startDate =
                data['subscriptionStart'] is Timestamp
                    ? data['subscriptionStart'] as Timestamp
                    : data['subscriptionStartDate']
                            is Timestamp
                        ? data['subscriptionStartDate']
                            as Timestamp
                        : null;

            final Timestamp? endDate =
                getSubscriptionEndDate(
              data,
            );

            final int daysRemaining =
                getDaysRemaining(
              endDate,
            );

            final bool isExpired =
                status.toLowerCase() == 'expired' ||
                    (endDate != null &&
                        !DateTime.now().isBefore(
                          endDate.toDate(),
                        ));

            final bool isWarning =
                !isExpired &&
                    endDate != null &&
                    daysRemaining <= 7;

            final bool showRenewButton =
                isWarning || isExpired;

            final Color statusColor =
                isExpired
                    ? Colors.red
                    : isWarning
                        ? Colors.orange
                        : Colors.green;

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 10),
                  Text('Bill'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.all(
                                    10,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: statusColor
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(
                                      10,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.workspace_premium,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                const Expanded(
                                  child: Text(
                                    'Subscription',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: statusColor,
                                      borderRadius:
                                          BorderRadius.circular(
                                        20,
                                      ),
                                    ),
                                    child: Text(
                                      isExpired
                                          ? 'EXPIRED'
                                          : status.toUpperCase(),
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style:
                                          const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                            _billingRow(
                              label: 'Plan',
                              value: plan,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            _billingRow(
                              label: 'Start Date',
                              value:
                                  formatDate(startDate),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            _billingRow(
                              label: 'Due / End Date',
                              value:
                                  formatDate(endDate),
                              valueColor: statusColor,
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.all(
                                12,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: statusColor
                                    .withOpacity(0.08),
                                borderRadius:
                                    BorderRadius.circular(
                                  10,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isExpired
                                        ? Icons.error
                                        : isWarning
                                            ? Icons.warning
                                            : Icons
                                                .calendar_today,
                                    color: statusColor,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      isExpired
                                          ? 'Subscription expired'
                                          : daysRemaining == 0
                                              ? 'Expires today'
                                              : '$daysRemaining day(s) remaining',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isWarning) ...[
                        const SizedBox(
                          height: 15,
                        ),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(
                            14,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.orange,
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.notification_important,
                                color: Colors.orange,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'Your subscription is near its expiration date. You can renew in advance to continue using MotoFind without interruption.',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isExpired) ...[
                        const SizedBox(
                          height: 15,
                        ),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(
                            14,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red,
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'Your subscription has expired. Please renew your plan to continue using the store features.',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text('Close'),
                ),
                if (showRenewButton)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SubscriptionScreen(
                            isRenewal: true,
                            isExpiredRenewal:
                                isExpired,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label: const Text(
                      'Renew',
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BILLING ROW
  // ============================================================

  Widget _billingRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(
          width: 15,
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }


// ============================================================
// SUMMARY CARD
// ============================================================

Widget buildSummaryCard({
  required String title,
  required String value,
  required IconData icon,
  required Color iconColor,
}) {
  final bool compact =
      MediaQuery.of(context).size.width < 700;

  return Container(
    padding: EdgeInsets.all(compact ? 7 : 12),
    decoration: BoxDecoration(
      color: motoDarkBlue,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(
        color: const Color(0xFF263D5C),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: compact ? 28 : 40,
          height: compact ? 28 : 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: compact ? 17 : 22,
          ),
        ),
        SizedBox(width: compact ? 6 : 10),
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
                style: TextStyle(
                  color: const Color(0xFFB7C4D9),
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 15 : 19,
                    fontWeight: FontWeight.bold,
                  ),
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
  // DASHBOARD SUMMARY
  // ============================================================

  Widget buildDashboardSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: storeId == null
          ? const Stream<QuerySnapshot>.empty()
          : FirebaseFirestore.instance
              .collection('products')
              .where(
                'storeId',
                isEqualTo: storeId,
              )
              .snapshots(),
      builder: (context, productSnapshot) {
        int totalProducts = 0;

        if (productSnapshot.hasData) {
          totalProducts =
              productSnapshot.data!.docs.length;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: storeId == null
              ? const Stream<QuerySnapshot>.empty()
              : FirebaseFirestore.instance
                  .collection('reservations')
                  .where(
                    'storeId',
                    isEqualTo: storeId,
                  )
                  .snapshots(),
          builder: (context, reservationSnapshot) {
            int activeReservations = 0;

            if (reservationSnapshot.hasData) {
              for (final doc
                  in reservationSnapshot.data!.docs) {
                final data =
                    doc.data()
                        as Map<String, dynamic>;

                final String status =
                    data['status']
                            ?.toString()
                            .toLowerCase() ??
                        '';

                if (status == 'active' ||
                    status == 'pending' ||
                    status == 'reserved') {
                  activeReservations++;
                }
              }
            }

            return StreamBuilder<QuerySnapshot>(
              stream: storeId == null
                  ? const Stream<QuerySnapshot>.empty()
                  : FirebaseFirestore.instance
                      .collection('sales')
                      .where(
                        'storeId',
                        isEqualTo: storeId,
                      )
                      .snapshots(),
              builder: (context, salesSnapshot) {
                double totalSales = 0;
                int productsSold = 0;

                if (salesSnapshot.hasData) {
                  for (final sale
                      in salesSnapshot.data!.docs) {
                    final data =
                        sale.data()
                            as Map<String, dynamic>;

                    totalSales +=
                        getSaleTotal(data);

                    productsSold +=
                        getSaleQuantity(data);
                  }
                }

                return LayoutBuilder(
                  builder:
                      (context, constraints) {
                   
final bool isWebLayout = constraints.maxWidth >= 800;
final bool compact =
    MediaQuery.of(context).size.width < 700;

final int columns = isWebLayout ? 4 : 2;

return Padding(
  padding: EdgeInsets.symmetric(
    horizontal: compact ? 4 : 18,
    vertical: compact ? 2 : 6,
  ),
  child: GridView.count(
    crossAxisCount: columns,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: compact ? 5 : 12,
    crossAxisSpacing: compact ? 5 : 12,
    childAspectRatio: compact
        ? 2.2
        : (isWebLayout ? 2.6 : 1.9),
    children: [
      buildSummaryCard(
        title: 'Total Sales',
        value: peso.format(totalSales),
        icon: Icons.payments_outlined,
        iconColor: Colors.green,
      ),
      buildSummaryCard(
        title: 'Products Sold',
        value: '$productsSold',
        icon: Icons.shopping_cart_outlined,
        iconColor: Colors.blue,
      ),
      buildSummaryCard(
        title: 'Active Reservations',
        value: '$activeReservations',
        icon: Icons.assignment_outlined,
        iconColor: Colors.purple,
      ),
      buildSummaryCard(
        title: 'Total Products',
        value: '$totalProducts',
        icon: Icons.inventory_2_outlined,
        iconColor: Colors.orange,
      ),
    ],
  ),
);

                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SALES OVERVIEW
  // ============================================================

 
Widget buildSalesOverview() {
  if (storeId == null || storeId!.isEmpty) {
    return const SizedBox();
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('sales')
        .where('storeId', isEqualTo: storeId)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (snapshot.hasError) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading sales: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          ),
        );
      }

      final docs = snapshot.data?.docs ?? [];

      DateTime? getSaleDate(Map<String, dynamic> data) {
        final value = data['soldAt'];

        if (value is Timestamp) {
          return value.toDate().toLocal();
        }

        if (value is DateTime) {
          return value.toLocal();
        }

        return null;
      }

      double getSaleTotal(Map<String, dynamic> data) {
        final value = data['total'];

        if (value is num) {
          return value.toDouble();
        }

        if (value is String) {
          return double.tryParse(value) ?? 0;
        }

        return 0;
      }

      final now = DateTime.now();

      DateTime currentStart;
      DateTime currentEnd;
      DateTime previousStart;
      DateTime previousEnd;

      if (selectedSalesPeriod == 'Today') {
        currentStart = DateTime(now.year, now.month, now.day);
        currentEnd = currentStart.add(const Duration(days: 1));
        previousStart = currentStart.subtract(const Duration(days: 1));
        previousEnd = currentStart;
      } else if (selectedSalesPeriod == 'Week') {
        final monday =
            now.subtract(Duration(days: now.weekday - DateTime.monday));

        currentStart = DateTime(monday.year, monday.month, monday.day);
        currentEnd = currentStart.add(const Duration(days: 7));
        previousStart = currentStart.subtract(const Duration(days: 7));
        previousEnd = currentStart;
      } else {
        currentStart = DateTime(now.year, now.month, 1);
        currentEnd = DateTime(now.year, now.month + 1, 1);
        previousStart = DateTime(now.year, now.month - 1, 1);
        previousEnd = currentStart;
      }

      final currentSales = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final date = getSaleDate(data);

        if (date == null) return false;

        return !date.isBefore(currentStart) &&
            date.isBefore(currentEnd);
      }).toList();

      final previousSales = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final date = getSaleDate(data);

        if (date == null) return false;

        return !date.isBefore(previousStart) &&
            date.isBefore(previousEnd);
      }).toList();

      double currentTotal = 0;
      double previousTotal = 0;

      for (final doc in currentSales) {
        final data = doc.data() as Map<String, dynamic>;
        currentTotal += getSaleTotal(data);
      }

      for (final doc in previousSales) {
        final data = doc.data() as Map<String, dynamic>;
        previousTotal += getSaleTotal(data);
      }

      double percentageChange = 0;

      if (previousTotal == 0) {
        if (currentTotal > 0) {
          percentageChange = 100;
        }
      } else {
        percentageChange =
            ((currentTotal - previousTotal) / previousTotal) * 100;
      }

      final bool isIncrease = percentageChange >= 0;

      List<double> graphValues = [];
      List<String> graphLabels = [];

      if (selectedSalesPeriod == 'Today') {
        graphValues = List<double>.filled(24, 0);

        for (final doc in currentSales) {
          final data = doc.data() as Map<String, dynamic>;
          final date = getSaleDate(data);

          if (date == null) continue;

          final hour = date.hour;

          if (hour >= 0 && hour < 24) {
            graphValues[hour] += getSaleTotal(data);
          }
        }

        graphLabels = List.generate(24, (index) {
          if (index == 0) return '12A';
          if (index == 3) return '3A';
          if (index == 6) return '6A';
          if (index == 9) return '9A';
          if (index == 12) return '12P';
          if (index == 15) return '3P';
          if (index == 18) return '6P';
          if (index == 21) return '9P';
          return '';
        });
      } else if (selectedSalesPeriod == 'Week') {
        graphValues = List<double>.filled(7, 0);

        for (final doc in currentSales) {
          final data = doc.data() as Map<String, dynamic>;
          final date = getSaleDate(data);

          if (date == null) continue;

          final index = date.weekday - 1;

          if (index >= 0 && index < 7) {
            graphValues[index] += getSaleTotal(data);
          }
        }

        graphLabels = const [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ];
      } else {
        final daysInMonth = DateTime(
          now.year,
          now.month + 1,
          0,
        ).day;

        graphValues = List<double>.filled(daysInMonth, 0);

        for (final doc in currentSales) {
          final data = doc.data() as Map<String, dynamic>;
          final date = getSaleDate(data);

          if (date == null) continue;

          final dayIndex = date.day - 1;

          if (dayIndex >= 0 && dayIndex < daysInMonth) {
            graphValues[dayIndex] += getSaleTotal(data);
          }
        }

        graphLabels = List.generate(daysInMonth, (index) {
          final day = index + 1;

          if (day == 1 ||
              day == 5 ||
              day == 10 ||
              day == 15 ||
              day == 20 ||
              day == 25 ||
              day == 30) {
            return '$day';
          }

          return '';
        });
      }

      double maxValue = 0;

      if (graphValues.isNotEmpty) {
        maxValue = graphValues.reduce((a, b) => a > b ? a : b);
      }

      if (maxValue == 0) {
        maxValue = 100;
      }

      const secondaryTextColor = Color(0xFFB7C4D9);

final bool compact =
    MediaQuery.of(context).size.width < 700;
      return Container(
        margin: EdgeInsets.only(top: compact ? 2 : 16),
padding: EdgeInsets.all(compact ? 6 : 16),
        decoration: BoxDecoration(
          color: motoDarkBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sales Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF52627A),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSalesPeriod,
                      dropdownColor: motoNavy,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      iconEnabledColor: Colors.white,
                      items: const [
                        DropdownMenuItem(
                          value: 'Today',
                          child: Text(
                            'Today',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Week',
                          child: Text(
                            'Week',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Month',
                          child: Text(
                            'Month',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          selectedSalesPeriod = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              peso.format(currentTotal),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              selectedSalesPeriod == 'Today'
                  ? 'Total Sales Today'
                  : selectedSalesPeriod == 'Week'
                      ? 'Total Sales This Week'
                      : 'Total Sales This Month',
              style: const TextStyle(
                fontSize: 13,
                color: secondaryTextColor,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Icon(
                  isIncrease
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 20,
                  color: isIncrease ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 5),
                Text(
                  '${percentageChange.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isIncrease ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  selectedSalesPeriod == 'Today'
                      ? 'vs Yesterday'
                      : selectedSalesPeriod == 'Week'
                          ? 'vs Last Week'
                          : 'vs Last Month',
                  style: const TextStyle(
                    fontSize: 13,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
  height: compact ? 45 : 110,
  width: double.infinity,
  child: CustomPaint(
    painter: SalesGraphPainter(
      values: graphValues,
      maxValue: maxValue,
    ),
  ),
),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                graphLabels.length,
                (index) {
                  final label = graphLabels[index];

                  if (label.isEmpty) {
                    return const SizedBox();
                  }

                  return Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: secondaryTextColor,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

  // ============================================================
  // TOP SELLING PARTS
  // ============================================================

 
Widget buildTopSellingParts() {
  const Color titleColor = Colors.white;
  const Color secondaryTextColor = Color(0xFFB7C4D9);

  return StreamBuilder<QuerySnapshot>(
    stream: storeId == null
        ? const Stream<QuerySnapshot>.empty()
        : FirebaseFirestore.instance
            .collection('sales')
            .where(
              'storeId',
              isEqualTo: storeId,
            )
            .snapshots(),
    builder: (context, snapshot) {
      final Map<String, int> productSales = {};

      if (snapshot.hasData) {
        for (final doc in snapshot.data!.docs) {
          final data =
              doc.data() as Map<String, dynamic>;

          final String productName =
              getSaleProductName(data);

          final int quantity = getSaleQuantity(data);

          productSales[productName] =
              (productSales[productName] ?? 0) +
                  quantity;
        }
      }

      final List<MapEntry<String, int>> sortedProducts =
          productSales.entries.toList()
            ..sort(
              (a, b) => b.value.compareTo(a.value),
            );

      final List<MapEntry<String, int>> topProducts =
          sortedProducts.take(5).toList();

return Container(
  margin: const EdgeInsets.fromLTRB(3, 0, 3, 3),
  padding: const EdgeInsets.all(6),
  decoration: BoxDecoration(
    color: motoDarkBlue,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(
            Icons.bar_chart,
            color: Color(0xFFCB93FF),
            size: 16,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              'Top Selling Parts',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 2),
      const Text(
        'Best-selling motorcycle parts',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: secondaryTextColor,
          fontSize: 8,
        ),
      ),
      const SizedBox(height: 4),
      if (topProducts.isEmpty)
        const Expanded(
          child: Center(
            child: Text(
              'No sales data available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 9,
              ),
            ),
          ),
        )
      else
        ...topProducts.map((entry) {
          final int maxQuantity = topProducts.first.value;

          final double percentage = maxQuantity == 0
              ? 0
              : entry.value / maxQuantity;

          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value} sold',
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF34445D),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF8A00),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
    ],
  ),
);
},
  );
}

  // ============================================================
  // INVENTORY STATUS
  // ============================================================

 
Widget buildInventoryStatus() {
  return StreamBuilder<QuerySnapshot>(
    stream: storeId == null
        ? const Stream<QuerySnapshot>.empty()
        : FirebaseFirestore.instance
            .collection('products')
            .where(
              'storeId',
              isEqualTo: storeId,
            )
            .snapshots(),
    builder: (context, snapshot) {
      int inStock = 0;
      int lowStock = 0;
      int outOfStock = 0;

      if (snapshot.hasData) {
        for (final doc in snapshot.data!.docs) {
          final data =
              doc.data() as Map<String, dynamic>;

          final int stock =
              (data['stock'] as num?)?.toInt() ?? 0;

          final int alertStock =
              (data['alertStock'] as num?)?.toInt() ?? 0;

          if (stock <= 0) {
            outOfStock++;
          } else if (stock <= alertStock) {
            lowStock++;
          } else {
            inStock++;
          }
        }
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(3, 0, 3, 3),
padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: motoDarkBlue,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
      
const Row(
  children: [
    Icon(
      Icons.inventory_2_outlined,
      color: Colors.orange,
      size: 16,
    ),
    SizedBox(width: 4),
    Expanded(
      child: Text(
        'Inventory Status',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  ],
),
 const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _inventoryStatusItem(
                    icon: Icons.check_circle,
                    label: 'In Stock',
                    value: inStock,
                    iconColor: Colors.green,
                  ),
                ),
                Expanded(
                  child: _inventoryStatusItem(
                    icon: Icons.warning,
                    label: 'Low Stock',
                    value: lowStock,
                    iconColor: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _inventoryStatusItem(
                    icon: Icons.cancel,
                    label: 'Out of Stock',
                    value: outOfStock,
                    iconColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

  // ============================================================
  // INVENTORY STATUS ITEM
  // ============================================================

 
Widget _inventoryStatusItem({
  required IconData icon,
  required String label,
  required int value,
  required Color iconColor,
}) {
  return Column(
    children: [
      Icon(
        icon,
        color: iconColor,
        size: 25,
      ),
      const SizedBox(height: 5),
      Text(
        '$value',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFB7C4D9),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}


  
  // ============================================================
  // DASHBOARD - RESPONSIVE WINDOWS AND ANDROID
  // ============================================================

 


Widget buildDashboard() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final double width = constraints.maxWidth;
      final double height = constraints.maxHeight;
      final bool isWideScreen = width >= 700;

if (!isWideScreen) {
  return SizedBox(
    width: width,
    height: height,
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
            Expanded(
              flex: 2,
              child: buildDashboardSummary(),
            ),
            const SizedBox(height: 2),
          Expanded(
            flex: 3,
            child: buildSalesOverview(),
          ),
          const SizedBox(height: 2),
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: buildTopSellingParts(),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: buildInventoryStatus(),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


      return SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: buildDashboardSummary(),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 3,
                      child: buildSalesOverview(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: buildTopSellingParts(),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: buildInventoryStatus(),
                    ),
                  ],
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
  // OPEN MENU PAGE
  // ============================================================

 
Future<void> openMenuPage(
  BuildContext context,
  Widget page,
  String title, {
  bool reopenDrawerOnReturn = false,
}) async {
  final bool isDesktop =
      MediaQuery.of(context).size.width >= 900;

  // Close the overlay drawer on phones only.
  // Do not pop the Dashboard route on desktop.
  if (!isDesktop) {
    Navigator.pop(context);
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => page,
    ),
  );

  // Reopen the overlay drawer on phones only.
  if (reopenDrawerOnReturn && mounted && !isDesktop) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scaffoldKey.currentState?.openDrawer();
      }
    });
  }
}


  
  // ============================================================
  // DRAWER - RESPONSIVE MOTOFind STORE OWNER SIDEBAR
  // UI ONLY: Existing navigation and logout behavior preserved
  // ============================================================

  Widget buildDrawer() {
    const Color navy = Color(0xFF0B1730);
    const Color orange = Color(0xFFFF8A00);
    const Color mutedText = Color(0xFFB7C4D9);
    const Color dividerColor = Color(0xFF293B55);

    Widget menuItem({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool selected = false,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 3,
        ),
        child: ListTile(
          onTap: onTap,
          selected: selected,
          selectedTileColor: orange.withOpacity(0.13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: selected
                ? BorderSide(
                    color: orange.withOpacity(0.35),
                    width: 1,
                  )
                : BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 3,
          ),
          leading: Icon(
            icon,
            size: 21,
            color: selected ? orange : mutedText,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : mutedText,
            ),
          ),
          trailing: selected
              ? Container(
                  width: 6,
                  height: 24,
                  decoration: BoxDecoration(
                    color: orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              : null,
        ),
      );
    }

    return Drawer(
      width: 290,
      backgroundColor: navy,
      elevation: 12,
      child: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                22,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF19365D),
                    Color(0xFF0B1730),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: orange.withOpacity(0.45),
                          ),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: orange,
                          size: 29,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MotoFind',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'STORE OWNER PANEL',
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF263D5C),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ownerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                storeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: mutedText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // MENU LABEL
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 20, 22, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MAIN MENU',
                  style: TextStyle(
                    color: Color(0xFF8293AC),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
            ),

            // NAVIGATION ITEMS
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  menuItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    selected: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  menuItem(
                    icon: Icons.inventory_2_rounded,
                    title: 'Inventory',
                    onTap: () {
                     openMenuPage(
  context,
  const InventoryScreen(),
  'Inventory',
  reopenDrawerOnReturn: true,
);
                    },
                  ),

                 menuItem(
  icon: Icons.assignment_rounded,
  title: 'Reserve Orders',
  onTap: () {
    openMenuPage(
      context,
      const ReservedOrdersScreen(),
      'Reservations',
      reopenDrawerOnReturn: true,
    );
  },
),

                 menuItem(
  icon: Icons.bar_chart_rounded,
  title: 'Sales',
  onTap: () {
    openMenuPage(
      context,
      const SalesScreen(),
      'Sales',
      reopenDrawerOnReturn: true,
    );
  },
),

                menuItem(
  icon: Icons.add_box_rounded,
  title: 'Add Product',
  onTap: () {
    openMenuPage(
      context,
      const AddProduct(),
      'Add Product',
      reopenDrawerOnReturn: true,
    );
  },
),

                 menuItem(
  icon: Icons.store_rounded,
  title: 'Store Profile',
  onTap: () {
    openMenuPage(
      context,
      const StoreProfile(),
      'Store Profile',
      reopenDrawerOnReturn: true,
    );
  },
),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Divider(
                      color: dividerColor,
                      height: 1,
                    ),
                  ),

                  menuItem(
  icon: Icons.workspace_premium_rounded,
  title: 'Subscription',
  onTap: () {
    openMenuPage(
      context,
      const SubscriptionScreen(),
      'Subscription',
      reopenDrawerOnReturn: true,
    );
  },
),
                ],
              ),
            ),

            // LOGOUT SECTION
            Container(
              padding: const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                12,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                   
onTap: () async {
  final bool isDesktop =
      MediaQuery.of(context).size.width >= 900;

  // Close the drawer only on mobile.
  if (!isDesktop) {
    Navigator.pop(context);
  }

  final bool? confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Logout'),
          ),
        ],
      );
    },
  );

  if (confirm != true || !mounted) {
    return;
  }

  debugPrint('LOGOUT: Starting');

  try {
    // Navigate while StoreDashboard is still mounted.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );

    debugPrint('LOGOUT: Login navigation requested');

    await authService.logout();

    debugPrint('LOGOUT: Firebase sign-out successful');
  } catch (e, stackTrace) {
    debugPrint('LOGOUT ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
},
shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFFF7777),
                      size: 21,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Color(0xFFFF7777),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF8293AC),
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'MotoFind Store Management',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF8293AC),
                      fontSize: 10,
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
// BUILD
// RESPONSIVE PUSH SIDEBAR
// ============================================================

@override
Widget build(BuildContext context) {
  final bool isDesktop =
      MediaQuery.of(context).size.width >= 900;

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
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Exit App?'),
            content: const Text(
              'Are you sure you want to leave the app?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Exit'),
              ),
            ],
          );
        },
      );

      if (shouldExit == true) {
        SystemNavigator.pop();
      }
    },
    child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: motoBackground,

      // Drawer is used on phones only.
      drawer: isDesktop ? null : buildDrawer(),

      appBar: AppBar(
        backgroundColor: motoNavy,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black26,

        // Custom menu button:
        // Desktop = push sidebar.
        // Phone = open normal drawer.
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: _isSidebarExpanded && isDesktop
              ? 'Collapse sidebar'
              : 'Open menu',
          icon: Icon(
            _isSidebarExpanded && isDesktop
                ? Icons.menu_open_rounded
                : Icons.menu_rounded,
          ),
          onPressed: () {
            if (isDesktop) {
              setState(() {
                _isSidebarExpanded = !_isSidebarExpanded;
              });
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
        ),

        title: const Text(
          'MotoFind - Store Owner',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          buildBillButton(),
          const SizedBox(width: 2),
          buildNotificationBell(),
          const SizedBox(width: 5),
        ],
      ),

      // RESPONSIVE BODY
      body: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SIDEBAR: occupies its own space.
                // It no longer overlays the dashboard.
                if (_isSidebarExpanded)
                  SizedBox(
                    width: 290,
                    child: buildDrawer(),
                  ),

                // DASHBOARD: uses the remaining width.
                Expanded(
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.zero,
                    child: buildDashboard(),
                  ),
                ),
              ],
            )
          : buildDashboard(),
    ),
  );
}
}

// ================================================================
// SALES GRAPH PAINTER
// ================================================================

class SalesGraphPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;

  SalesGraphPainter({
    required this.values,
    required this.maxValue,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (values.isEmpty) {
      return;
    }

    final Paint gridPaint =
        Paint()
         ..color = const Color(0xFF34445D)
          ..strokeWidth = 1;

    final Paint linePaint =
        Paint()
          ..color = const Color(0xFFFF8A00)
          ..strokeWidth = 3
          ..style =
              PaintingStyle.stroke
          ..strokeCap =
              StrokeCap.round;

    final Paint pointPaint =
        Paint()
         ..color = const Color(0xFFFF8A00)
          ..style =
              PaintingStyle.fill;

    // ==========================================================
    // GRID
    // ==========================================================

    for (int i = 0; i <= 4; i++) {
      final double y =
          size.height * i / 4;

      canvas.drawLine(
        Offset(0, y),
        Offset(
          size.width,
          y,
        ),
        gridPaint,
      );
    }

    if (values.length == 1) {
      return;
    }

    // ==========================================================
    // POINTS
    // ==========================================================

    final double horizontalStep =
        size.width /
            (values.length - 1);

    final Path path =
        Path();

    final List<Offset> points =
        [];

    for (int i = 0;
        i < values.length;
        i++) {
      final double x =
          i * horizontalStep;

      final double normalized =
          maxValue <= 0
              ? 0
              : values[i] /
                  maxValue;

      final double y =
          size.height -
              (normalized *
                  size.height);

      final Offset point =
          Offset(
        x,
        y,
      );

      points.add(
        point,
      );

      if (i == 0) {
        path.moveTo(
          x,
          y,
        );
      } else {
        path.lineTo(
          x,
          y,
        );
      }
    }

    // ==========================================================
    // DRAW LINE
    // ==========================================================

    canvas.drawPath(
      path,
      linePaint,
    );

    // ==========================================================
    // DRAW POINTS
    // ==========================================================

    for (final point in points) {
      canvas.drawCircle(
        point,
        5,
        pointPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant SalesGraphPainter oldDelegate,
  ) {
    return true;
  }
}