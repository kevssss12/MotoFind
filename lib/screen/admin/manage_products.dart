
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManageProducts extends StatefulWidget {
  const ManageProducts({super.key});
  @override
  State<ManageProducts> createState() => _ManageProductsState();
}
class _ManageProductsState extends State<ManageProducts> {
  // ================================================================
  // SEARCH CONTROLLER
  // ================================================================
  final TextEditingController searchController =
      TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final ValueNotifier<String> searchNotifier =
      ValueNotifier<String>("");
  late final Stream<QuerySnapshot<Map<String, dynamic>>>
      productsStream;
  final Map<String, Future<DocumentSnapshot<Map<String, dynamic>>>>
      storeFutures = {};
  @override
  void initState() {
    super.initState();
    productsStream = FirebaseFirestore.instance
        .collection("products")
        .snapshots();
    searchController.addListener(_onSearchChanged);
  }
  // ================================================================
  // SEARCH CHANGE
  // ================================================================
  void _onSearchChanged() {
    final searchText =
        searchController.text.trim().toLowerCase();
    if (searchNotifier.value != searchText) {
      searchNotifier.value = searchText;
    }
  }
  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    searchFocusNode.dispose();
    searchNotifier.dispose();
    super.dispose();
  }
  // ================================================================
  // BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Manage Products"),
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
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      // ============================================
                      // STABLE SEARCH BAR
                      // ============================================
                      _buildSearchBar(),
                      // ============================================
                      // FIRESTORE PRODUCTS
                      // ============================================
                      Expanded(
                        child: StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: productsStream,
                          builder: (context, snapshot) {
                            // ====================================
                            // LOADING
                            // ====================================
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            // ====================================
                            // ERROR
                            // ====================================
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
                            // ====================================
                            // PRODUCTS
                            // ====================================
                            final products =
                                snapshot.data?.docs ?? [];
                            // ====================================
                            // SEARCH RESULTS
                            // ====================================
                            return ValueListenableBuilder<String>(
                              valueListenable: searchNotifier,
                              builder: (
                                context,
                                searchText,
                                child,
                              ) {
                                // ==================================
                                // FILTER PRODUCTS
                                // ==================================
                                final filteredProducts =
                                    products.where((doc) {
                                  final data = doc.data();
                                  final String name =
                                      data["name"]
                                              ?.toString()
                                              .trim()
                                              .toLowerCase() ?? "";
                                  final String category =
                                      data["category"]
                                              ?.toString()
                                              .trim()
                                              .toLowerCase() ?? "";
                                  final String storeId =
                                      data["storeId"]
                                              ?.toString()
                                              .trim()
                                              .toLowerCase() ?? "";
                                  return name.contains(searchText) ||
                                      category.contains(searchText) ||
                                      storeId.contains(searchText);
                                }).toList();
                                // ==================================
                                // NO PRODUCTS
                                // ==================================
                                if (products.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      "No products found.",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  );
                                }
                                // ==================================
                                // NO SEARCH RESULT
                                // ==================================
                                if (filteredProducts.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 60,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 15),
                                        Text(
                                          'No products match "$searchText".',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                // ==================================
                                // PRODUCT LIST
                                // ==================================
                                return ListView.builder(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior
                                          .manual,
                                  padding: const EdgeInsets.fromLTRB(
                                    15,
                                    5,
                                    15,
                                    15,
                                  ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final doc =
                                        filteredProducts[index];
                                    final data = doc.data();
                                    // ================================
                                    // PRODUCT NAME
                                    // ================================
                                    final String name =
                                        data["name"]
                                                    ?.toString()
                                                    .trim()
                                                    .isNotEmpty ==
                                                true
                                            ? data["name"]
                                                .toString()
                                                .trim()
                                            : "No Product Name";
                                    // ================================
                                    // IMAGE
                                    // ================================
                                    final String imageUrl =
                                        data["imageUrl"]
                                                ?.toString()
                                                .trim() ??
                                            "";
                                    // ================================
                                    // STORE ID
                                    // ================================
                                    final String storeId =
                                        data["storeId"]
                                                ?.toString()
                                                .trim() ?? "";
                                    // ================================
                                    // PRODUCT CARD
                                    // ================================
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
                                        // PRODUCT IMAGE
                                        leading: imageUrl.isNotEmpty
                                            ? CircleAvatar(
                                                radius: 28,
                                                backgroundImage:
                                                    NetworkImage(imageUrl),
                                              )
                                            : const CircleAvatar(
                                                radius: 28,
                                                child: Icon(
                                                  Icons.inventory_2,
                                                  size: 28,
                                                ),
                                              ),
                                        // PRODUCT NAME
                                        title: Text(
                                          name,
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                        ),
                                        // STORE NAME
                                        subtitle: FutureBuilder<
                                            DocumentSnapshot<
                                                Map<String, dynamic>>>(
                                          future: _getCachedStore(storeId),
                                          builder: (
                                            context,
                                            storeSnapshot,
                                          ) {
                                            if (storeSnapshot
                                                    .connectionState ==
                                                ConnectionState.waiting) {
                                              return const Text(
                                                "Loading store...",
                                              );
                                            }
                                            if (storeSnapshot.hasError ||
                                                !storeSnapshot.hasData ||
                                                !storeSnapshot.data!.exists) {
                                              return const Text(
                                                "Store not found",
                                              );
                                            }
                                            final storeData =
                                                storeSnapshot.data!.data();
                                            if (storeData == null) {
                                              return const Text(
                                                "Store not found",
                                              );
                                            }
                                            final String storeName =
                                                storeData["storeName"]
                                                            ?.toString()
                                                            .trim()
                                                            .isNotEmpty ==
                                                        true
                                                    ? storeData["storeName"]
                                                        .toString()
                                                        .trim()
                                                    : "Unknown Store";
                                            return Text(
                                              storeName,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                        // ARROW
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 18,
                                        ),
                                        // OPEN PRODUCT DETAILS
                                        onTap: () {
                                          searchFocusNode.unfocus();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductDetailsScreen(
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
  // ================================================================
  // SEARCH BAR
  // ================================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        5,
      ),
      child: TextField(
        key: const ValueKey("manage_products_search"),
        controller: searchController,
        focusNode: searchFocusNode,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        autofocus: false,
        enableInteractiveSelection: true,
        // Do not unfocus during search updates.
        decoration: InputDecoration(
          hintText: "Search product...",
          prefixIcon: const Icon(
            Icons.search,
          ),
          // ======================================================
          // CLEAR BUTTON
          // ======================================================
          suffixIcon: ValueListenableBuilder<String>(
            valueListenable: searchNotifier,
            builder: (context, searchText, child) {
              if (searchText.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: "Clear",
                icon: const Icon(
                  Icons.clear,
                ),
                onPressed: () {
                  searchController.clear();
                  // Keep keyboard focus.
                  if (!searchFocusNode.hasFocus) {
                    searchFocusNode.requestFocus();
                  }
                },
              );
            },
          ),
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
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
  // ================================================================
  // CACHED STORE LOOKUP
  // ================================================================
  Future<DocumentSnapshot<Map<String, dynamic>>> _getCachedStore(
    String storeId,
  ) {
    return storeFutures.putIfAbsent(
      storeId,
      () => _getStore(storeId),
    );
  }
  // ================================================================
  // GET STORE
  // ================================================================
  Future<DocumentSnapshot<Map<String, dynamic>>> _getStore(
    String storeId,
  ) async {
    if (storeId.isEmpty) {
      throw Exception("Store ID is empty.");
    }
    // ==============================================================
    // 1. DIRECT STORES DOCUMENT ID
    // ==============================================================
    final direct = await FirebaseFirestore.instance
        .collection("stores")
        .doc(storeId)
        .get();
    if (direct.exists) {
      return direct;
    }
    // ==============================================================
    // 2. SEARCH storeId FIELD IN STORES
    // ==============================================================
    final storeQuery = await FirebaseFirestore.instance
        .collection("stores")
        .where("storeId", isEqualTo: storeId)
        .limit(1)
        .get();
    if (storeQuery.docs.isNotEmpty) {
      return storeQuery.docs.first;
    }
    // ==============================================================
    // 3. SEARCH USERS USING storeId
    // ==============================================================
    final userQuery = await FirebaseFirestore.instance
        .collection("users")
        .where("storeId", isEqualTo: storeId)
        .limit(1)
        .get();
    if (userQuery.docs.isNotEmpty) {
      final String ownerUid = userQuery.docs.first.id;
      // TRY stores/{ownerUid}
      final ownerStore = await FirebaseFirestore.instance
          .collection("stores")
          .doc(ownerUid)
          .get();
      if (ownerStore.exists) {
        return ownerStore;
      }
      // FALLBACK USERS DOCUMENT
      return userQuery.docs.first;
    }
    throw Exception("Store not found.");
  }
}
// ==================================================================
// PRODUCT DETAILS SCREEN
// ==================================================================
class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const ProductDetailsScreen({
    super.key,
    required this.data,
  });
  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}
class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {
  late final String storeId;

  late final Future<DocumentSnapshot<Map<String, dynamic>>>
      storeFuture;
  @override
  void initState() {
    super.initState();
    storeId = widget.data["storeId"]?.toString().trim() ?? "";
    storeFuture = _getStore(storeId);
  }
  // ================================================================
  // DATE FORMAT
  // ================================================================
  String formatDate(dynamic value) {
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
  // ================================================================
  // INFO
  // ================================================================
  Widget info(String title, dynamic value) {
    final String text =
        value == null || value.toString().trim().isEmpty
            ? "None"
            : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              "$title:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
  // ================================================================
  // BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final String name =
        data["name"]?.toString() ?? "Product Details";
    final String imageUrl =
        data["imageUrl"]?.toString().trim() ?? "";
    final int stock =
        (num.tryParse(data["stock"]?.toString() ?? "") ?? 0)
            .toInt();
    final int alertStock =
        (num.tryParse(data["alertStock"]?.toString() ?? "") ?? 0)
            .toInt();
    final double price =
        (num.tryParse(data["price"]?.toString() ?? "") ?? 0)
            .toDouble();
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
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),

                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ========================================
                        // PRODUCT IMAGE
                        // ========================================
                        Center(
                          child: imageUrl.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (dialogContext) {
                                        return Dialog(
                                          backgroundColor: Colors.black,
                                          insetPadding:
                                              const EdgeInsets.all(12),
                                          child: Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              InteractiveViewer(
                                                minScale: 0.5,
                                                maxScale: 4,
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  height: MediaQuery.of(
                                                        dialogContext,
                                                      ).size.height *
                                                      0.75,
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return const Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.white,
                                                          size: 70,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  Navigator.pop(
                                                    dialogContext,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(15),
                                    child: Image.network(
                                      imageUrl,
                                      height: 220,
                                      width: 220,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return _imagePlaceholder();
                                      },
                                    ),
                                  ),
                                )
                              : _imagePlaceholder(),
                        ),
                        const SizedBox(height: 20),
                        // ========================================
                        // PRODUCT NAME
                        // ========================================
                        Center(
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // ========================================
                        // PRODUCT INFORMATION
                        // ========================================
                        const Text(
                          "Product Information",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        info("Product Name", data["name"]),
                        info("Category", data["category"]),
                        info(
                          "Price",
                          "₱${price.toStringAsFixed(2)}",
                        ),
                        info("Stock", stock),
                        info("Alert Stock", alertStock),
                        info("Store ID", storeId),
                        info(
                          "Created At",
                          formatDate(data["createdAt"]),
                        ),
                        const Divider(),
                        const SizedBox(height: 10),
                        // ========================================
                        // STOCK STATUS
                        // ========================================
                        const Text(
                          "Stock Status",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _stockStatus(stock, alertStock),
                        const SizedBox(height: 25),
                        // ========================================
                        // STORE INFORMATION
                        // ========================================
                        const Text(
                          "Store Information",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        FutureBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          future: storeFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Store information not available.",
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Error: ${snapshot.error}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            }
                            if (!snapshot.hasData ||
                                !snapshot.data!.exists) {
                              return const Text(
                                "Store information not available.",
                              );
                            }
                            final storeData = snapshot.data!.data();

                            if (storeData == null) {
                              return const Text(
                                "Store information not available.",
                              );
                            }
                            final String storeName =
                                storeData["storeName"]
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? storeData["storeName"]
                                        .toString()
                                        .trim()
                                    : "Unknown Store";
                            final String owner =
                                storeData["ownerName"]
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? storeData["ownerName"]
                                        .toString()
                                        .trim()
                                    : storeData["fullName"]
                                                ?.toString()
                                                .trim()
                                                .isNotEmpty ==
                                            true
                                        ? storeData["fullName"]
                                            .toString()
                                            .trim()
                                        : "None";
                            final String address =
                                storeData["storeAddress"]
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? storeData["storeAddress"]
                                        .toString()
                                        .trim()
                                    : storeData["address"]
                                                ?.toString()
                                                .trim()
                                                .isNotEmpty ==
                                            true
                                        ? storeData["address"]
                                            .toString()
                                            .trim()
                                        : "None";
                            final String phone =
                                storeData["phone"]
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? storeData["phone"]
                                        .toString()
                                        .trim()
                                    : "None";
                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                info("Store Name", storeName),
                                info("Owner", owner),
                                info("Address", address),
                                info("Phone", phone),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 30),
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
  // IMAGE PLACEHOLDER
  // ================================================================
  Widget _imagePlaceholder() {
    return Container(
      height: 220,
      width: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade200,
      ),
      child: const Icon(
        Icons.inventory_2,
        size: 80,
      ),
    );
  }
  // ================================================================
  // STOCK STATUS
  // ================================================================
  Widget _stockStatus(int stock, int alertStock) {
    // ==============================================================
    // OUT OF STOCK
    // ==============================================================
    if (stock <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
            ),
            SizedBox(width: 10),
            Text(
              "Out of Stock",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    // ==============================================================
    // LOW STOCK
    // ==============================================================
    if (stock <= alertStock) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange,
            ),
            SizedBox(width: 10),
            Text(
              "Low Stock",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    // ==============================================================
    // IN STOCK
    // ==============================================================
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
          ),
          SizedBox(width: 10),
          Text(
            "In Stock",
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  // ================================================================
  // STORE LOOKUP
  // ================================================================
  Future<DocumentSnapshot<Map<String, dynamic>>> _getStore(
    String storeId,
  ) async {
    if (storeId.isEmpty) {
      throw Exception("Store ID is empty.");
    }
    // ==============================================================
    // 1. DIRECT STORES DOCUMENT ID
    // ==============================================================
    final direct = await FirebaseFirestore.instance
        .collection("stores")
        .doc(storeId)
        .get();
    if (direct.exists) {
      return direct;
    }
    // ==============================================================
    // 2. SEARCH storeId FIELD IN STORES
    // ==============================================================
    final storeQuery = await FirebaseFirestore.instance
        .collection("stores")
        .where("storeId", isEqualTo: storeId)
        .limit(1)
        .get();
    if (storeQuery.docs.isNotEmpty) {
      return storeQuery.docs.first;
    }
    // ==============================================================
    // 3. SEARCH USERS USING storeId
    // ==============================================================
    final userQuery = await FirebaseFirestore.instance
        .collection("users")
        .where("storeId", isEqualTo: storeId)
        .limit(1)
        .get();
    if (userQuery.docs.isNotEmpty) {
      final String ownerUid = userQuery.docs.first.id;
      // TRY stores/{ownerUid}
      final ownerStore = await FirebaseFirestore.instance
          .collection("stores")
          .doc(ownerUid)
          .get();
      if (ownerStore.exists) {
        return ownerStore;
      }
      // FALLBACK USERS DOCUMENT
      return userQuery.docs.first;
    }
    throw Exception("Store not found.");
  }
}