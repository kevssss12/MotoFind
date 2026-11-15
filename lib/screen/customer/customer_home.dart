
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'product_details_screen.dart';
import 'reservation_history_screen.dart';
import 'cart_screen.dart';
import 'customer_product_feed.dart';
import 'customer_profile_screen.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({
    super.key,
  });

  @override
  State<CustomerHome> createState() =>
      _CustomerHomeState();
}

class _CustomerHomeState
    extends State<CustomerHome> {
  final FirestoreService firestoreService =
      FirestoreService();

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final AuthService authService =
      AuthService();

  Map<String, String> storeNames = {};

  ProductModel? selectedProduct;

  int selectedBottomIndex = 0;

  final TextEditingController
      searchController =
      TextEditingController();

  String searchQuery = "";

  String customerName = "Customer";
  String customerEmail = "";
  String customerPhone = "";
  String customerImageUrl = "";

  bool loadingCustomer = true;

  // ============================================================
  // LOAD STORE NAMES
  // ============================================================

 
Future<void> loadStoreNames(
  List<ProductModel> products,
) async {
  try {
    final Set<String> storeIds = products
        .map((product) => product.storeId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (storeIds.isEmpty) return;

    final Map<String, String> names = {
      ...storeNames,
    };

    for (final storeId in storeIds) {
      if (names.containsKey(storeId) &&
          names[storeId] != "Unknown Store") {
        continue;
      }

      String resolvedName = "Unknown Store";

      // 1. Check stores/{storeId}
      final directStore = await FirebaseFirestore.instance
          .collection("stores")
          .doc(storeId)
          .get();

      if (directStore.exists) {
        final data = directStore.data() ?? {};

        final name =
            data["storeName"]?.toString().trim() ?? "";

        if (name.isNotEmpty) {
          resolvedName = name;
        }
      }

      // 2. Search stores by storeId field
      if (resolvedName == "Unknown Store") {
        final storeQuery = await FirebaseFirestore.instance
            .collection("stores")
            .where("storeId", isEqualTo: storeId)
            .limit(1)
            .get();

        if (storeQuery.docs.isNotEmpty) {
          final data = storeQuery.docs.first.data();

          final name =
              data["storeName"]?.toString().trim() ?? "";

          if (name.isNotEmpty) {
            resolvedName = name;
          }
        }
      }

      // 3. Search Store Owner in users
      if (resolvedName == "Unknown Store") {
        final ownerQuery = await FirebaseFirestore.instance
            .collection("users")
            .where("storeId", isEqualTo: storeId)
            .where("role", isEqualTo: "Store Owner")
            .limit(1)
            .get();

        if (ownerQuery.docs.isNotEmpty) {
          final ownerDoc = ownerQuery.docs.first;
          final ownerData = ownerDoc.data();

          // Check stores/{ownerUid}
          final ownerStore = await FirebaseFirestore.instance
              .collection("stores")
              .doc(ownerDoc.id)
              .get();

          if (ownerStore.exists) {
            final data = ownerStore.data() ?? {};

            final name =
                data["storeName"]?.toString().trim() ?? "";

            if (name.isNotEmpty) {
              resolvedName = name;
            }
          }

          // Fallback to users.storeName
          if (resolvedName == "Unknown Store") {
            final name =
                ownerData["storeName"]?.toString().trim() ?? "";

            if (name.isNotEmpty) {
              resolvedName = name;
            }
          }
        }
      }

      names[storeId] = resolvedName;
    }

    if (!mounted) return;

    bool changed = names.length != storeNames.length;

    if (!changed) {
      for (final entry in names.entries) {
        if (storeNames[entry.key] != entry.value) {
          changed = true;
          break;
        }
      }
    }

    if (changed) {
      setState(() {
        storeNames = names;
      });
    }
  } catch (e) {
    debugPrint("LOAD STORE NAMES ERROR: $e");
  }
}

  // ============================================================
  // CHECK ACTIVE STORE SUBSCRIPTIONS
  // ============================================================

  Future<Set<String>> getActiveStoreIds(
    List<ProductModel> products,
  ) async {
    final Set<String> activeStoreIds = {};

    try {
      final Set<String> storeIds =
          products
              .map(
                (product) =>
                    product.storeId.trim(),
              )
              .where(
                (id) => id.isNotEmpty,
              )
              .toSet();

      if (storeIds.isEmpty) {
        return activeStoreIds;
      }

      // ==========================================================
      // CHECK EACH STORE OWNER DIRECTLY FROM USERS COLLECTION
      // ==========================================================

      for (final storeId in storeIds) {
        try {
          final QuerySnapshot<
                  Map<String, dynamic>>
              userSnapshot =
              await FirebaseFirestore
                  .instance
                  .collection("users")
                  .where(
                    "storeId",
                    isEqualTo: storeId,
                  )
                  .where(
                    "role",
                    isEqualTo: "Store Owner",
                  )
                  .limit(1)
                  .get();

          // No Store Owner found for this store
          if (userSnapshot.docs.isEmpty) {
            debugPrint(
              "NO STORE OWNER FOUND FOR STORE: $storeId",
            );

            continue;
          }

          final Map<String, dynamic>
              ownerData =
              userSnapshot.docs.first.data();

          // ========================================================
          // USER ACCOUNT STATUS
          // ========================================================

          final String userStatus =
              ownerData["status"]
                      ?.toString()
                      .trim()
                      .toLowerCase() ??
                  "";

          // Only Approved Store Owners can appear
          if (userStatus != "approved") {
            debugPrint(
              "STORE HIDDEN - USER STATUS: $userStatus | STORE: $storeId",
            );

            continue;
          }

          // ========================================================
          // SUBSCRIPTION STATUS
          // ========================================================

          final String
              subscriptionStatus =
              ownerData[
                          "subscriptionStatus"]
                      ?.toString()
                      .trim()
                      .toLowerCase() ??
                  "";

          // Subscription must be Approved
          if (subscriptionStatus !=
              "approved") {
            debugPrint(
              "STORE HIDDEN - SUBSCRIPTION STATUS: $subscriptionStatus | STORE: $storeId",
            );

            continue;
          }

          // ========================================================
          // SUBSCRIPTION END DATE
          // ========================================================

          final dynamic
              subscriptionEnd =
              ownerData[
                  "subscriptionEnd"];

          DateTime? endDate;

          if (subscriptionEnd
              is Timestamp) {
            endDate =
                subscriptionEnd.toDate();
          } else if (subscriptionEnd
              is DateTime) {
            endDate =
                subscriptionEnd;
          }

          // No subscription end date
          // means inactive.
          if (endDate == null) {
            debugPrint(
              "STORE HIDDEN - NO SUBSCRIPTION END DATE | STORE: $storeId",
            );

            continue;
          }

          // ========================================================
          // CHECK IF EXPIRED
          // ========================================================

          if (!endDate.isAfter(
            DateTime.now(),
          )) {
            debugPrint(
              "STORE HIDDEN - SUBSCRIPTION EXPIRED | STORE: $storeId | END: $endDate",
            );

            continue;
          }

          // ========================================================
          // STORE IS ACTIVE
          // ========================================================

          activeStoreIds.add(
            storeId,
          );

          debugPrint(
            "ACTIVE STORE: $storeId | SUBSCRIPTION END: $endDate",
          );
        } catch (e) {
          debugPrint(
            "STORE SUBSCRIPTION CHECK ERROR [$storeId]: $e",
          );
        }
      }
    } catch (e) {
      debugPrint(
        "GET ACTIVE STORE IDS ERROR: $e",
      );
    }

    return activeStoreIds;
  }

  // ============================================================
  // OPEN PRODUCT DETAILS
  // ============================================================

  void openProductDetails(
    ProductModel product,
  ) {
    setState(() {
      selectedProduct = product;
    });
  }

  // ============================================================
  // GO HOME
  // ============================================================

  void goToHome() {
    setState(() {
      selectedBottomIndex = 0;
      selectedProduct = null;
    });
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void onBottomNavigationTap(
    int index,
  ) {
    // ==========================================================
    // HOME
    // ==========================================================

    if (index == 0) {
      setState(() {
        selectedBottomIndex = 0;
        selectedProduct = null;
      });

      return;
    }

    // ==========================================================
    // CART
    // ==========================================================

    if (index == 1) {
      setState(() {
        selectedBottomIndex = 1;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const FavoritesScreen(),
        ),
      ).then((_) {
        if (!mounted) return;

        setState(() {
          selectedBottomIndex = 0;
          selectedProduct = null;
        });
      });

      return;
    }

    // ==========================================================
    // RESERVATION HISTORY
    // ==========================================================

    if (index == 2) {
      setState(() {
        selectedBottomIndex = 2;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const ReservationHistoryScreen(),
        ),
      ).then((_) {
        if (!mounted) return;

        setState(() {
          selectedBottomIndex = 0;
          selectedProduct = null;
        });
      });

      return;
    }

    // ==========================================================
    // MORE
    // ==========================================================

    if (index == 3) {
      setState(() {
        selectedBottomIndex = 0;
      });

      showMoreMenu();

      return;
    }
  }

  // ============================================================
  // MORE MENU
  // ============================================================

  void showMoreMenu() {
    showModalBottomSheet(
      context: context,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              // ==================================================
              // MENU TITLE
              // ==================================================

              const Padding(
                padding:
                    EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.more_vert,
                      size: 25,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "More",
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // ==================================================
              // MY PROFILE
              // ==================================================

              ListTile(
                leading:
                    const Icon(
                  Icons.person_outline,
                ),
                title:
                    const Text(
                  "My Profile",
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                  );

                  openCustomerProfile();
                },
              ),

              // ==================================================
              // LOGOUT
              // ==================================================

              ListTile(
                leading:
                    const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title:
                    const Text(
                  "Logout",
                  style:
                      TextStyle(
                    color: Colors.red,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                  );

                  logout();
                },
              ),

              const SizedBox(
                height: 8,
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // PHONE CHECK
  // ============================================================

  bool isPhone(
    BuildContext context,
  ) {
    return MediaQuery.of(context)
            .size
            .width <
        600;
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget buildProductImage(
    ProductModel product, {
    double width = 55,
    double height = 55,
  }) {
    if (product.imageUrl
        .trim()
        .isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration:
            BoxDecoration(
          color:
              Colors.grey.shade200,
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
        child: const Icon(
          Icons.motorcycle,
          size: 30,
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(12),
      child: Image.network(
        product.imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress ==
              null) {
            return child;
          }

          return Container(
            width: width,
            height: height,
            color:
                Colors.grey.shade200,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        },
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            width: width,
            height: height,
            color:
                Colors.grey.shade200,
            child: const Icon(
              Icons.broken_image,
              size: 30,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadCustomerData();
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
  // LOAD CUSTOMER DATA
  // ============================================================

  Future<void> loadCustomerData() async {
    try {
      final User? user =
          auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            loadingCustomer = false;
          });
        }

        return;
      }

      final DocumentSnapshot<
              Map<String, dynamic>>
          userDoc =
          await FirebaseFirestore
              .instance
              .collection("users")
              .doc(user.uid)
              .get();

      if (!userDoc.exists) {
        if (mounted) {
          setState(() {
            loadingCustomer = false;
          });
        }

        return;
      }

      final Map<String, dynamic>
          data =
          userDoc.data() ?? {};

      if (!mounted) return;

      setState(() {
        final String fullName =
            data["fullName"]
                    ?.toString()
                    .trim() ??
                "";

        customerName =
            fullName.isNotEmpty
                ? fullName
                : "Customer";

        customerEmail =
            data["email"]
                    ?.toString() ??
                user.email ??
                "";

        customerPhone =
            data["phone"]
                    ?.toString() ??
                "";

        customerImageUrl =
            data["profileImageUrl"]
                    ?.toString() ??
                "";

        loadingCustomer = false;
      });
    } catch (e) {
      debugPrint(
        "CUSTOMER DATA ERROR: $e",
      );

      if (mounted) {
        setState(() {
          loadingCustomer = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN CUSTOMER PROFILE
  // ============================================================

  Future<void>
      openCustomerProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CustomerProfileScreen(),
      ),
    );

    if (mounted) {
      await loadCustomerData();
    }
  }

  // ============================================================
  // PROFILE AVATAR
  // ============================================================

  Widget buildProfileAvatar({
    double radius = 20,
  }) {
    if (customerImageUrl
        .trim()
        .isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor:
            Colors.grey.shade200,
        backgroundImage:
            NetworkImage(
          customerImageUrl,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor:
          Colors.grey.shade200,
      child: Icon(
        Icons.person,
        size: radius * 1.2,
        color:
            Colors.grey.shade700,
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget buildSearchBar() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        10,
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery =
                value.toLowerCase();
          });
        },
        style: const TextStyle(
          color: Color(0xFF202124),
          fontSize: 15,
        ),
        decoration:
            InputDecoration(
          hintText:
              'Search motorcycle parts...',
          hintStyle:
              const TextStyle(
            color:
                Color(0xFF6B7280),
            fontSize: 15,
          ),
          prefixIcon:
              const Icon(
            Icons.search,
            color:
                Color(0xFF202124),
            size: 25,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets
                  .symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              30,
            ),
            borderSide:
                const BorderSide(
              color:
                  Color(0xFFB0B0B0),
              width: 1.2,
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              30,
            ),
            borderSide:
                const BorderSide(
              color:
                  Color(0xFF202124),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
  
  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            "Logout",
          ),
          content:
              const Text(
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
              child:
                  const Text(
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
              child:
                  const Text(
                "Logout",
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await authService.logout();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // OPEN RESERVATION HISTORY
  // ============================================================

  void openReservationHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ReservationHistoryScreen(),
      ),
    ).then((_) {
      if (!mounted) return;

      setState(() {
        selectedBottomIndex = 0;
        selectedProduct = null;
      });
    });
  }

  // ============================================================
  // OPEN CART
  // ============================================================

  void openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const FavoritesScreen(),
      ),
    ).then((_) {
      if (!mounted) return;

      setState(() {
        selectedBottomIndex = 0;
        selectedProduct = null;
      });
    });
  }

  // ============================================================
  // CUSTOMER PROFILE HEADER
  // ============================================================

  Widget buildCustomerHeader() {
    return DrawerHeader(
      margin: EdgeInsets.zero,
      decoration:
          BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary,
      ),
      child: loadingCustomer
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                buildProfileAvatar(
                  radius: 28,
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  customerName,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                if (customerEmail
                    .isNotEmpty)
                  Text(
                    customerEmail,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                if (customerPhone
                    .isNotEmpty)
                  Text(
                    customerPhone,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            buildCustomerHeader(),

            // ==================================================
            // HOME
            // ==================================================

            ListTile(
              leading:
                  const Icon(
                Icons.home,
              ),
              title:
                  const Text(
                "Home",
              ),
              onTap: () {
                Navigator.pop(
                  context,
                );

                setState(() {
                  selectedBottomIndex =
                      0;
                  selectedProduct =
                      null;
                });
              },
            ),

            // ==================================================
            // CART
            // ==================================================

            ListTile(
              leading:
                  const Icon(
                Icons.shopping_cart,
                color: Colors.blue,
              ),
              title:
                  const Text(
                "Cart",
              ),
              onTap: () {
                Navigator.pop(
                  context,
                );

                openFavorites();
              },
            ),

            // ==================================================
            // RESERVATION HISTORY
            // ==================================================

            ListTile(
              leading:
                  const Icon(
                Icons.history,
              ),
              title:
                  const Text(
                "Reservation History",
              ),
              onTap:
                  openReservationHistory,
            ),

            // ==================================================
            // PROFILE
            // ==================================================

            ListTile(
              leading:
                  const Icon(
                Icons.person_outline,
              ),
              title:
                  const Text(
                "My Profile",
              ),
              onTap: () {
                Navigator.pop(
                  context,
                );

                openCustomerProfile();
              },
            ),

            const Spacer(),

            const Divider(),

            // ==================================================
            // LOGOUT
            // ==================================================

            ListTile(
              leading:
                  const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title:
                  const Text(
                "Logout",
                style:
                    TextStyle(
                  color:
                      Colors.red,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool phone =
        MediaQuery.of(context)
                .size
                .width <
            600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        bool didPop,
        dynamic result,
      ) async {
        if (didPop) {
          return;
        }

        if (selectedProduct != null) {
          if (!mounted) return;

          setState(() {
            selectedProduct = null;
            selectedBottomIndex = 0;
          });

          return;
        }

        final bool? shouldExit =
            await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (
            dialogContext,
          ) {
            return AlertDialog(
              title:
                  const Text(
                "Exit App?",
              ),
              content:
                  const Text(
                "Are you sure you want to leave the app?",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(false);
                  },
                  child:
                      const Text(
                    "Cancel",
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(true);
                  },
                  child:
                      const Text(
                    "Exit",
                  ),
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
        backgroundColor:
            const Color(0xFFF1F3F5),

        // ======================================================
        // DRAWER
        // ======================================================

        drawer: phone
            ? null
            : buildDrawer(),

        // ======================================================
        // APP BAR
        // ======================================================

        appBar: AppBar(
          automaticallyImplyLeading:
              true,

          title: Text(
            selectedProduct != null
                ? "Product Details"
                : "MotoFind",
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          centerTitle: true,

          leading:
              selectedProduct != null
                  ? IconButton(
                      tooltip: "Back",
                      icon:
                          const Icon(
                        Icons.arrow_back,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedProduct =
                              null;
                          selectedBottomIndex =
                              0;
                        });
                      },
                    )
                  : null,

          actions: [
            if (selectedProduct ==
                null)
              Padding(
                padding:
                    const EdgeInsets.only(
                  right: 8,
                ),
                child:
                    IconButton(
                  tooltip:
                      "My Profile",
                  onPressed:
                      openCustomerProfile,
                  icon:
                      buildProfileAvatar(
                    radius: 19,
                  ),
                ),
              ),

            if (!phone &&
                selectedProduct ==
                    null)
              IconButton(
                tooltip:
                    "Reservation History",
                icon:
                    const Icon(
                  Icons.history,
                ),
                onPressed:
                    openReservationHistory,
              ),
          ],
        ),

        // ======================================================
        // BODY
        // ======================================================

        body: selectedProduct !=
                null
            ? ProductDetailsContent(
                product:
                    selectedProduct!,
              )
            : Column(
                children: [
                  buildSearchBar(),

                  Expanded(
                    child:
                        StreamBuilder<
                            QuerySnapshot>(
                      stream:
                          firestoreService
                              .getProducts(),

                      builder: (
                        context,
                        snapshot,
                      ) {
                        if (snapshot
                                .connectionState ==
                            ConnectionState
                                .waiting) {
                          return const Center(
                            child:
                                CircularProgressIndicator(),
                          );
                        }

                        if (snapshot
                            .hasError) {
                          return Center(
                            child:
                                Padding(
                              padding:
                                  const EdgeInsets
                                      .all(
                                20,
                              ),
                              child:
                                  Text(
                                "Firestore Error:\n${snapshot.error}",
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.red,
                                  fontSize:
                                      16,
                                ),
                              ),
                            ),
                          );
                        }

                        if (!snapshot
                            .hasData) {
                          return const Center(
                            child:
                                Text(
                              "No data received",
                            ),
                          );
                        }

                        final docs =
                            snapshot
                                .data!
                                .docs;

                        if (docs.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Icon(
                                  Icons
                                      .inventory_2_outlined,
                                  size: 70,
                                  color:
                                      Colors.grey,
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                Text(
                                  "No products available",
                                  style:
                                      TextStyle(
                                    fontSize:
                                        18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final List<
                                ProductModel>
                            products =
                            [];

                        for (final doc
                            in docs) {
                          try {
                            final Map<
                                    String,
                                    dynamic>
                                data =
                                doc.data()
                                    as Map<
                                        String,
                                        dynamic>;

                            products.add(
                              ProductModel
                                  .fromFirestore(
                                doc.id,
                                data,
                              ),
                            );
                          } catch (e) {
                            debugPrint(
                              "PRODUCT PARSE ERROR: $e",
                            );
                          }
                        }

                        if (storeNames
                                .isEmpty &&
                            products
                                .isNotEmpty) {
                          Future
                              .microtask(
                            () {
                              loadStoreNames(
                                products,
                              );
                            },
                          );
                        }

                        // ==================================================
                        // CHECK ACTIVE STORE SUBSCRIPTIONS
                        // ==================================================

                        return FutureBuilder<
                            Set<String>>(
                          future:
                              getActiveStoreIds(
                            products,
                          ),

                          builder: (
                            context,
                            activeStoreSnapshot,
                          ) {
                            // ================================================
                            // CHECKING
                            // ================================================

                            if (activeStoreSnapshot
                                    .connectionState ==
                                ConnectionState
                                    .waiting) {
                              return const Center(
                                child:
                                    CircularProgressIndicator(),
                              );
                            }

                            // ================================================
                            // ERROR
                            // ================================================

                            if (activeStoreSnapshot
                                .hasError) {
                              return Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(
                                    20,
                                  ),
                                  child: Text(
                                    "Unable to check store subscription status.",
                                    textAlign:
                                        TextAlign.center,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.red,
                                      fontSize:
                                          16,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final Set<String>
                                activeStoreIds =
                                activeStoreSnapshot
                                        .data ??
                                    <String>{};

                            // ================================================
                            // FILTER PRODUCTS
                            // ================================================

                            final List<ProductModel>
                                filteredProducts =
                                products
                                    .where(
                              (product) {
                                // ==============================================
                                // HIDE OUT-OF-STOCK PRODUCTS
                                // ==============================================

                                if (product.stock <=
                                    0) {
                                  return false;
                                }

                                // ==============================================
                                // HIDE PRODUCTS FROM INACTIVE STORES
                                // ==============================================

                                if (!activeStoreIds
                                    .contains(
                                  product.storeId
                                      .trim(),
                                )) {
                                  return false;
                                }

                                // ==============================================
                                // SEARCH FILTER
                                // ==============================================

                                if (searchQuery
                                    .isEmpty) {
                                  return true;
                                }

                                final String
                                    productName =
                                    product.name
                                        .toLowerCase();

                                final String
                                    category =
                                    product.category
                                        .toLowerCase();

                                final String
                                    storeName =
                                    (storeNames[
                                                product
                                                    .storeId] ??
                                            "")
                                        .toLowerCase();

                                return productName
                                        .contains(
                                      searchQuery,
                                    ) ||
                                    category
                                        .contains(
                                      searchQuery,
                                    ) ||
                                    storeName
                                        .contains(
                                      searchQuery,
                                    );
                              },
                            ).toList();

                            // ================================================
                            // NO ACTIVE PRODUCTS
                            // ================================================

                            if (filteredProducts
                                .isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    const Icon(
                                      Icons
                                          .search_off,
                                      size: 70,
                                      color:
                                          Colors.grey,
                                    ),

                                    const SizedBox(
                                      height: 15,
                                    ),

                                    const Text(
                                      "No products found",
                                      style:
                                          TextStyle(
                                        fontSize:
                                            18,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      searchQuery
                                              .isEmpty
                                          ? "No active store products available."
                                          : 'No result for "$searchQuery"',
                                      textAlign:
                                          TextAlign
                                              .center,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // ================================================
                            // CUSTOMER PRODUCT FEED
                            // ================================================

                            return CustomerProductFeed(
                              products:
                                  filteredProducts,

                              onProductTap:
                                  (product) {
                                openProductDetails(
                                  product,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

        // ======================================================
        // BOTTOM NAVIGATION
        // ======================================================

        bottomNavigationBar: phone
            ? BottomNavigationBar(
                currentIndex:
                    selectedBottomIndex,

                onTap:
                    onBottomNavigationTap,

                type:
                    BottomNavigationBarType
                        .fixed,

                items: const [
                  // ==========================================
                  // HOME
                  // ==========================================

                  BottomNavigationBarItem(
                    icon:
                        Icon(
                      Icons.home,
                    ),
                    label:
                        "Home",
                  ),

                  // ==========================================
                  // CART
                  // ==========================================

                  BottomNavigationBarItem(
                    icon:
                        Icon(
                      Icons.shopping_cart,
                    ),
                    label:
                        "Cart",
                  ),

                  // ==========================================
                  // HISTORY
                  // ==========================================

                  BottomNavigationBarItem(
                    icon:
                        Icon(
                      Icons.history,
                    ),
                    label:
                        "History",
                  ),

                  // ==========================================
                  // MORE
                  // ==========================================

                  BottomNavigationBarItem(
                    icon:
                        Icon(
                      Icons.more_vert,
                    ),
                    label:
                        "More",
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
