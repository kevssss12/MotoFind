
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'store_details_screen.dart';

class ManageStoresScreen extends StatefulWidget {
  const ManageStoresScreen({
    super.key,
  });
  @override
  State<ManageStoresScreen> createState() =>
      _ManageStoresScreenState();
}
class _ManageStoresScreenState
    extends State<ManageStoresScreen> {
  // ==========================================================
  // SEARCH CONTROLLER
  // ==========================================================
  final TextEditingController _searchController =
      TextEditingController();

  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>("");
  final FocusNode _searchFocusNode = FocusNode();
  // ==========================================================
  // FIRESTORE STREAM
  // ==========================================================
  late final Stream<QuerySnapshot<Map<String, dynamic>>>
      _storesStream;
  // ==========================================================
  // INIT STATE
  // ==========================================================
  @override
  void initState() {
    super.initState();
    _storesStream = FirebaseFirestore.instance
        .collection("users")
        .where(
          "role",
          isEqualTo: "Store Owner",
        )
        .where(
          "status",
          isEqualTo: "Approved",
        )
        .snapshots();
    _searchController.addListener(() {
      _searchNotifier.value =
          _searchController.text.trim().toLowerCase();
    });
  }
  // ==========================================================
  // DISPOSE
  // ==========================================================
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchNotifier.dispose();
    super.dispose();
  }
  // ==========================================================
  // OPEN SEARCH KEYBOARD
  // ==========================================================
  void _openSearchKeyboard() {
    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }
  }
  // ==========================================================
  // SEARCH BAR
  // ==========================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        7,
        7,
        7,
        5,
      ),
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
        onTap: _openSearchKeyboard,
        onSubmitted: (value) {
          _searchFocusNode.unfocus();
        },
        decoration: InputDecoration(
          hintText: "Search store, owner, address...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ValueListenableBuilder<String>(
          valueListenable: _searchNotifier,
            builder: (context, value, child) {
              if (value.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: "Clear",
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _openSearchKeyboard();
                },
              );
            },
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
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
        title: const Text(
          "Manage Stores",
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
                  // ==========================================
                  // MAIN COLUMN
                  // ==========================================
                  child: Column(
                    children: [
                      // ======================================
                      // SEARCH BAR OUTSIDE STREAMBUILDER
                      // ======================================
                      _buildSearchBar(),
                      // ======================================
                      // FIRESTORE STORE LIST
                      // ======================================
                      Expanded(
                        child: StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: _storesStream,
                          builder: (context, snapshot) {
                            // ================================
                            // LOADING
                            // ================================
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            // ================================
                            // ERROR
                            // ================================
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
                            // ================================
                            // NO DATA
                            // ================================
                            if (!snapshot.hasData) {
                              return const Center(
                                child: Text(
                                  "No stores found.",
                                ),
                              );
                            }
                            final allStores =
                                snapshot.data!.docs;
                            // ================================
                            // SEARCH FILTER
                            // ================================
                            return ValueListenableBuilder<
                                TextEditingValue>(
                              valueListenable: _searchController,
                              builder: (
                                context,
                                value,
                                child,
                              ) {
                                final String searchText =
                                    value.text
                                        .trim()
                                        .toLowerCase();
                                final stores =
                                    allStores.where((doc) {
                                  final data = doc.data();
                                  final String storeName =
                                      data["storeName"]
                                              ?.toString()
                                              .trim()
                                              .toLowerCase() ?? "";
                                  final String storeAddress =
                                      data["storeAddress"]
                                              ?.toString()
                                              .trim()
                                              .toLowerCase() ?? "";
                                  final String ownerName =
                                      data["fullName"]
                                              ?.toString()
                                              .trim()
                                              .toLowerCase() ?? "";
                                  final String phone =
                                      data["phone"]
                                              ?.toString()
                                              .trim()
                                              .toLowerCase() ?? "";
                                  return storeName.contains(
                                          searchText,
                                        ) ||
                                      storeAddress.contains(
                                        searchText,
                                      ) ||
                                      ownerName.contains(
                                        searchText,
                                      ) ||
                                      phone.contains(
                                        searchText,
                                      );
                                }).toList();
                                return Column(
                                  children: [
                                    // ==========================
                                    // RESULT COUNT
                                    // ==========================
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      child: Align(
                                        alignment:
                                            Alignment.centerLeft,
                                        child: Text(
                                          searchText.isEmpty
                                              ? "Stores: ${allStores.length}"
                                              : "Results: ${stores.length}",
                                          style: TextStyle(
                                            color:
                                                Colors.grey.shade700,
                                            fontWeight:
                                                FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // ==========================
                                    // EMPTY RESULTS
                                    // ==========================
                                    if (stores.isEmpty)
                                      Expanded(
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .store_mall_directory_outlined,
                                                size: 65,
                                                color:
                                                    Colors.grey.shade400,
                                              ),
                                              const SizedBox(
                                                height: 15,
                                              ),
                                              Text(
                                                searchText.isEmpty
                                                    ? "No stores found."
                                                    : "No stores match \"$searchText\".",
                                                textAlign:
                                                    TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors
                                                      .grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    // ==========================
                                    // STORE LIST
                                    // ==========================
                                    else
                                      Expanded(
                                        child: ListView.builder(
                                          keyboardDismissBehavior:
                                              ScrollViewKeyboardDismissBehavior
                                                  .onDrag,
                                          padding:
                                              const EdgeInsets.fromLTRB(
                                            7,
                                            5,
                                            7,
                                            15,
                                          ),
                                          itemCount: stores.length,
                                          itemBuilder: (
                                            context,
                                            index,
                                          ) {
                                            final doc =
                                                stores[index];
                                            final data =
                                                doc.data();
                                            // ====================
                                            // STORE NAME
                                            // ====================
                                            final String storeName =
                                                data["storeName"]
                                                            ?.toString()
                                                            .trim()
                                                            .isNotEmpty ==
                                                        true
                                                    ? data["storeName"]
                                                        .toString()
                                                        .trim()
                                                    : "No Store Name";
                                            // ====================
                                            // STORE IMAGE
                                            // ====================
                                            final String storeImage =
                                                data["storeImage"]
                                                        ?.toString()
                                                        .trim() ??
                                                    "";
                                            // ====================
                                            // RENEWAL STATUS
                                            // ====================
                                            final String renewalStatus =
                                                data["renewalStatus"]
                                                        ?.toString()
                                                        .trim()
                                                        .toLowerCase() ??
                                                    "";
                                            final bool renewalPending =
                                                renewalStatus ==
                                                    "pending";
                                            // ====================
                                            // STORE ADDRESS
                                            // ====================
                                            final String storeAddress =
                                                data["storeAddress"]
                                                        ?.toString()
                                                        .trim() ??  "";
                                            // ====================
                                            // STORE CARD
                                            // ====================
                                            return Card(
                                              elevation: 3,
                                              margin:
                                                  const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 18,
                                                  vertical: 10,
                                                ),
                                                // ==================
                                                // IMAGE
                                                // ==================
                                                leading: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    50,
                                                  ),
                                                  child: storeImage.isNotEmpty
                                                      ? Image.network(
                                                          storeImage,
                                                          width: 55,
                                                          height: 55,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return _storeIcon();
                                                          },
                                                        )
                                                      : _storeIcon(),
                                                ),
                                                // ==================
                                                // STORE NAME
                                                // ==================
                                                title: Text(
                                                  storeName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                                // ==================
                                                // ADDRESS + RENEWAL
                                                // ==================
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (storeAddress.isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                        child: Text(
                                                          storeAddress,
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey.shade600,
                                                          ),
                                                        ),
                                                      ),
                                                    if (renewalPending)
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                          top: 5,
                                                        ),
                                                        child: Text(
                                                          "Renewal Payment Pending",
                                                          style: TextStyle(
                                                            color:
                                                                Colors.orange,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                // ==================
                                                // ARROW
                                                // ==================
                                                trailing: const Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 18,
                                                ),
                                                // ==================
                                                // OPEN DETAILS
                                                // ==================
                                                onTap: () {
                                                  _searchFocusNode
                                                      .unfocus();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          StoreDetailsScreen(
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
              ),
            );
          },
        ),
      ),
    );
  }
  // ==========================================================
  // STORE ICON
  // ==========================================================
  Widget _storeIcon() {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.store,
        size: 30,
        color: Colors.grey,
      ),
    );
  }
}