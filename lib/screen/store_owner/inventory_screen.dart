  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:firebase_auth/firebase_auth.dart';

  import '../../models/product_model.dart';
  import '../../services/firestore_service.dart';
  import '../../services/cloudinary_service.dart';

 class InventoryScreen extends StatefulWidget {
  final String? initialProductId;

  const InventoryScreen({
    super.key,
    this.initialProductId,
  });

    @override
    State<InventoryScreen> createState() => _InventoryScreenState();
  }

  class _InventoryScreenState extends State<InventoryScreen> {
    final FirebaseFirestore firestore =
        FirebaseFirestore.instance;

    final FirestoreService _firestoreService =
        FirestoreService();

    final FirebaseAuth auth =
        FirebaseAuth.instance;

    final ImagePicker _imagePicker =
        ImagePicker();

    final TextEditingController searchController =
        TextEditingController();

    String searchText = "";
    String? storeId;

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
      final user = auth.currentUser;

      if (user == null) return;

      final doc = await firestore
          .collection("users")
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        setState(() {
          storeId =
              doc.data()?["storeId"]?.toString();
        });
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
    // DELETE PRODUCT
    // ============================================================

    Future<void> deleteProduct(
      String id,
      BuildContext context,
    ) async {
      try {
        await firestore
            .collection('products')
            .doc(id)
            .delete();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product Deleted"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error deleting product:\n$e",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // ============================================================
    // IMAGE PREVIEW
    // ============================================================

    void showImagePreview(
      BuildContext context,
      String imageUrl,
    ) {
      final String url = imageUrl.trim();

      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No image available.",
            ),
          ),
        );

        return;
      }

      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxHeight: 600,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  padding:
                      const EdgeInsets.all(10),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),
                    child: InteractiveViewer(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (
                          context,
                          child,
                          loadingProgress,
                        ) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const SizedBox(
                            height: 300,
                            child: Center(
                              child:
                                  CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Unable to load image.",
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // CLOSE BUTTON
                Positioned(
                  top: 5,
                  right: 5,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder:
                          const CircleBorder(),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Padding(
                        padding:
                            EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // ============================================================
    // EDIT PRODUCT
    // ============================================================

    void editProduct(
      BuildContext context,
      ProductModel product,
    ) {
      final TextEditingController nameController =
          TextEditingController(
        text: product.name,
      );

      final TextEditingController priceController =
          TextEditingController(
        text: product.price.toString(),
      );

      final TextEditingController stockController =
          TextEditingController(
        text: product.stock.toString(),
      );

      // IMPORTANT:
      // Original product image.
      // If user does not change image,
      // this image will be kept.
      final String originalImageUrl =
          product.imageUrl.trim();

      final TextEditingController imageUrlController =
          TextEditingController(
        text: originalImageUrl,
      );

      bool isUploadingImage = false;
      bool isUpdating = false;

      // ==========================================================
      // CHANGE IMAGE
      // ==========================================================

      Future<void> changeImage(
        StateSetter setDialogState,
      ) async {
        if (isUploadingImage || isUpdating) {
          return;
        }

        try {
          final XFile? image =
              await _imagePicker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 80,
            maxWidth: 1200,
            maxHeight: 1200,
          );

          // User cancelled image picker
          if (image == null) {
            return;
          }

          setDialogState(() {
            isUploadingImage = true;
          });

          // ======================================================
          // UPLOAD NEW IMAGE TO CLOUDINARY
          // ======================================================

          final String imageUrl =
              await CloudinaryService.uploadImage(
                    image,
                  ) ??
                  "";

          if (imageUrl.trim().isEmpty) {
            throw Exception(
              "Image upload failed.",
            );
          }

          // Replace only if upload succeeded
          imageUrlController.text =
              imageUrl.trim();

          setDialogState(() {
            isUploadingImage = false;
          });

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "New image uploaded successfully.",
              ),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          debugPrint(
            "CHANGE IMAGE ERROR: $e",
          );

          setDialogState(() {
            isUploadingImage = false;
          });

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Unable to upload image:\n$e",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // ==========================================================
      // EDIT DIALOG
      // ==========================================================

      showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
              context,
              setDialogState,
            ) {
              return AlertDialog(
                title: const Text(
                  "Edit Product",
                ),

                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ==========================================
                      // PART NAME
                      // ==========================================

                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(
                          labelText: "Part Name",
                          prefixIcon:
                              Icon(Icons.build),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==========================================
                      // PRICE
                      // ==========================================

                      TextField(
                        controller: priceController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(
                          labelText: "Price",
                          prefixIcon:
                              Icon(Icons.payments),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==========================================
                      // STOCK
                      // ==========================================

                      TextField(
                        controller: stockController,
                        keyboardType:
                            TextInputType.number,
                        decoration:
                            const InputDecoration(
                          labelText: "Stock",
                          prefixIcon:
                              Icon(Icons.inventory),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==========================================
                      // CURRENT IMAGE
                      // ==========================================

                      if (imageUrlController.text
                          .trim()
                          .isNotEmpty)
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showImagePreview(
                                  context,
                                  imageUrlController
                                      .text,
                                );
                              },
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius
                                        .circular(10),
                                child: Image.network(
                                  imageUrlController
                                      .text,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors
                                          .grey
                                          .shade200,
                                      child:
                                          const Icon(
                                        Icons
                                            .broken_image,
                                        size: 40,
                                        color:
                                            Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            const Text(
                              "Current Product Image",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),
                          ],
                        ),

                      // ==========================================
                      // CHANGE IMAGE BUTTON
                      // ==========================================

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child:
                            OutlinedButton.icon(
                          onPressed:
                              isUploadingImage ||
                                      isUpdating
                                  ? null
                                  : () {
                                      changeImage(
                                        setDialogState,
                                      );
                                    },
                          icon: isUploadingImage
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.image,
                                ),
                          label: Text(
                            isUploadingImage
                                ? "UPLOADING..."
                                : "CHANGE IMAGE",
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ==========================================
                      // IMAGE STATUS
                      // ==========================================

                      Text(
                        imageUrlController.text
                                .trim()
                                .isEmpty
                            ? "No image selected"
                            : imageUrlController
                                        .text
                                        .trim() ==
                                    originalImageUrl
                                ? "Current image will be kept"
                                : "New image selected",
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              imageUrlController
                                          .text
                                          .trim() ==
                                      originalImageUrl
                                  ? Colors.grey
                                  : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                actions: [
                  // ==============================================
                  // CANCEL
                  // ==============================================

                  TextButton(
                    onPressed:
                        isUpdating ||
                                isUploadingImage
                            ? null
                            : () {
                                Navigator.pop(
                                  dialogContext,
                                );
                              },
                    child:
                        const Text("Cancel"),
                  ),

                  // ==============================================
                  // UPDATE
                  // ==============================================

                  ElevatedButton(
                    onPressed:
                        isUpdating ||
                                isUploadingImage
                            ? null
                            : () async {
                                // =================================
                                // VALIDATE NAME
                                // =================================

                                final String name =
                                    nameController
                                        .text
                                        .trim();

                                if (name.isEmpty) {
                                  ScaffoldMessenger
                                      .of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please enter the product name.",
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                // =================================
                                // VALIDATE PRICE
                                // =================================

                                final double? price =
                                    double.tryParse(
                                  priceController
                                      .text
                                      .trim(),
                                );

                                if (price == null ||
                                    price < 0) {
                                  ScaffoldMessenger
                                      .of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please enter a valid price.",
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                // =================================
                                // VALIDATE STOCK
                                // =================================

                                final int? stock =
                                    int.tryParse(
                                  stockController
                                      .text
                                      .trim(),
                                );

                                if (stock == null ||
                                    stock < 0) {
                                  ScaffoldMessenger
                                      .of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please enter a valid stock.",
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                // =================================
                                // IMAGE LOGIC
                                // =================================

                                String finalImageUrl =
                                    imageUrlController
                                        .text
                                        .trim();

                                if (finalImageUrl.isEmpty) {
                                  finalImageUrl =
                                      originalImageUrl;
                                }

                                // =================================
                                // START UPDATE
                                // =================================

                                setDialogState(() {
                                  isUpdating = true;
                                });

                                try {
                                  await firestore
                                      .collection(
                                        'products',
                                      )
                                      .doc(
                                        product.id,
                                      )
                                      .update({
                                    'name': name,
                                    'price': price,
                                    'stock': stock,
                                    'imageUrl':
                                        finalImageUrl,
                                  });

                                  if (!context.mounted) {
                                    return;
                                  }

                                  Navigator.pop(
                                    dialogContext,
                                  );

                                  ScaffoldMessenger
                                      .of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Product Updated Successfully",
                                      ),
                                      backgroundColor:
                                          Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  setDialogState(() {
                                    isUpdating = false;
                                  });

                                  if (!context.mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger
                                      .of(
                                    context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Error updating product:\n$e",
                                      ),
                                      backgroundColor:
                                          Colors.red,
                                    ),
                                  );
                                }
                              },
                    child: isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Save Changes",
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
    // SELL PRODUCT WITH CONFIRMATION
    // ============================================================
  void sellProductDialog(ProductModel product) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _SellProductDialog(
          product: product,
          firestoreService: _firestoreService,
          parentContext: context,
        );
      },
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

  return Scaffold(
    backgroundColor: pageBackground,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back to Menu',
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: const Text(
        'Inventory',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 209, 209, 238),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE1E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: darkBlue.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // INVENTORY HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20, 20, 20, 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: primaryBlue,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Inventory',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Manage your motorcycle parts and stock.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // SEARCH FIELD
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20, 4, 20, 16,
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchText = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search product name...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: primaryBlue,
                    ),
                    filled: true,
                    fillColor: pageBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE1E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(
                height: 1,
                color: Color(0xFFE8EDF4),
              ),

              // INVENTORY CONTENT
              Expanded(
                child: storeId == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: primaryBlue,
                        ),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: firestore
                            .collection('products')
                            .where(
                              'storeId',
                              isEqualTo: storeId,
                            )
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: primaryBlue,
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return _inventoryEmptyState(
                              Icons.inventory_2_outlined,
                              'No Inventory',
                              'Your products will appear here.',
                            );
                          }

                          final List<ProductModel> products =
                              snapshot.data!.docs
                                  .map(
                                    (doc) => ProductModel.fromFirestore(
                                      doc.id,
                                      doc.data()
                                          as Map<String, dynamic>,
                                    ),
                                  )
                                  .where(
                                    (product) => product.name
                                        .toLowerCase()
                                        .contains(searchText),
                                  )
                                  .toList();

                          if (products.isEmpty) {
                            return _inventoryEmptyState(
                              Icons.search_off_rounded,
                              'No matching products',
                              'Try searching with another product name.',
                            );
                          }

                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // RESULT COUNT
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20, 15, 20, 5,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Your Products',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: darkBlue,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryBlue.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${products.length} ${products.length == 1 ? 'product' : 'products'}',
                                        style: const TextStyle(
                                          color: primaryBlue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // PRODUCT LIST
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16, 10, 16, 20,
                                  ),
                                  itemCount: products.length,
                                  itemBuilder: (context, index) {
                                    final product = products[index];

                                    final bool outOfStock =
                                        product.stock <= 0;

                                    final bool lowStock =
                                        product.stock > 0 &&
                                        product.stock <= 5;

                                    final Color stockColor =
                                        outOfStock
                                            ? Colors.red.shade700
                                            : lowStock
                                                ? Colors.orange.shade800
                                                : Colors.green.shade700;

                                    final String stockLabel =
                                        outOfStock
                                            ? 'Out of stock'
                                            : lowStock
                                                ? 'Low stock'
                                                : 'In stock';

                                    // PRODUCT IMAGE
                                    Widget productImage =
                                        GestureDetector(
                                      onTap: product.imageUrl
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : () {
                                              showImagePreview(
                                                context,
                                                product.imageUrl,
                                              );
                                            },
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: product.imageUrl
                                                .trim()
                                                .isNotEmpty
                                            ? Image.network(
                                                product.imageUrl,
                                                width: 76,
                                                height: 76,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Container(
                                                    width: 76,
                                                    height: 76,
                                                    color: pageBackground,
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                      size: 30,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                width: 76,
                                                height: 76,
                                                color: pageBackground,
                                                child: const Icon(
                                                  Icons.motorcycle_rounded,
                                                  color: primaryBlue,
                                                  size: 35,
                                                ),
                                              ),
                                      ),
                                    );

                                    // PRODUCT INFORMATION
                                    Widget productInformation =
                                        Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            product.name,
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: darkBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          Text(
                                            '₱${product.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: primaryBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 5,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                'Stock: ${product.stock}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: stockColor
                                                      .withValues(
                                                    alpha: 0.09,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    20,
                                                  ),
                                                ),
                                                child: Text(
                                                  stockLabel,
                                                  style: TextStyle(
                                                    color: stockColor,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );

                                    // PRODUCT ACTIONS
                                    Widget productActions = Wrap(
                                      spacing: 2,
                                      runSpacing: 2,
                                      alignment: WrapAlignment.end,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit Product',
                                          onPressed: () {
                                            editProduct(
                                              context,
                                              product,
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: primaryBlue,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: outOfStock
                                              ? 'Out of Stock'
                                              : 'Sell Product',
                                          onPressed: outOfStock
                                              ? null
                                              : () {
                                                  sellProductDialog(
                                                    product,
                                                  );
                                                },
                                          icon: Icon(
                                            Icons.point_of_sale_outlined,
                                            color: outOfStock
                                                ? Colors.grey
                                                : Colors.green.shade700,
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          tooltip: 'More options',
                                          onSelected: (value) async {
                                            if (value == 'delete') {
                                              final bool? confirmed =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder:
                                                    (dialogContext) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                      'Delete Product?',
                                                    ),
                                                    content: Text(
                                                      'Are you sure you want to delete "${product.name}"?',
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
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        style:
                                                            ElevatedButton
                                                                .styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.pop(
                                                            dialogContext,
                                                            true,
                                                          );
                                                        },
                                                        child: const Text(
                                                          'Delete',
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                              if (confirmed == true) {
                                                await deleteProduct(
                                                  product.id,
                                                  context,
                                                );
                                              }
                                            }
                                          },
                                          itemBuilder: (context) =>
                                              const [
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.more_vert_rounded,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );

                                    return LayoutBuilder(
                                      builder: (context, constraints) {
                                        final bool compact =
                                            constraints.maxWidth < 520;

                                        return Card(
                                          elevation: 0,
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            side: const BorderSide(
                                              color: Color(0xFFE5EBF3),
                                            ),
                                          ),
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.all(12),
                                            child: compact
                                                ? Column(
                                                    children: [
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          productImage,
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          productInformation,
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 8,
                                                      ),
                                                      Align(
                                                        alignment:
                                                            Alignment
                                                                .centerRight,
                                                        child: productActions,
                                                      ),
                                                    ],
                                                  )
                                                : Row(
                                                    children: [
                                                      productImage,
                                                      const SizedBox(
                                                        width: 14,
                                                      ),
                                                      productInformation,
                                                      const SizedBox(
                                                        width: 8,
                                                      ),
                                                      productActions,
                                                    ],
                                                  ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
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
  );
}

// EMPTY STATE
Widget _inventoryEmptyState(
  IconData icon,
  String title,
  String message,
) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 58,
            color: Colors.blueGrey.shade200,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF062B63),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}

  }

  class _SellProductDialog extends StatefulWidget {
    final ProductModel product;
    final FirestoreService firestoreService;
    final BuildContext parentContext;

    const _SellProductDialog({
      required this.product,
      required this.firestoreService,
      required this.parentContext,
    });

    @override
    State<_SellProductDialog> createState() =>
        _SellProductDialogState();
  }

  class _SellProductDialogState
      extends State<_SellProductDialog> {
    late final TextEditingController quantityController;
    bool isProcessing = false;

    @override
    void initState() {
      super.initState();
      quantityController = TextEditingController();
    }

    @override
    void dispose() {
      quantityController.dispose();
      super.dispose();
    }

    Future<void> processSale() async {
      if (isProcessing) return;

      final product = widget.product;
      final quantity =
          int.tryParse(quantityController.text.trim()) ?? 0;

      if (quantity <= 0) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          const SnackBar(content: Text("Invalid quantity.")),
        );
        return;
      }

      if (quantity > product.stock) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          const SnackBar(content: Text("Not enough stock.")),
        );
        return;
      }

      setState(() => isProcessing = true);
      bool saleCompleted = false;

      try {
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (confirmationContext) => AlertDialog(
            title: const Text("Confirm Sale"),
            content: Text(
              "Are you sure you want to sell "
              "$quantity unit(s) of ${product.name}?\n\n"
              "Unit price: ₱${product.price.toStringAsFixed(2)}\n"
              "Total: ₱${(product.price * quantity).toStringAsFixed(2)}",
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(confirmationContext).pop(false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(confirmationContext).pop(true),
                child: const Text("Confirm Sale"),
              ),
            ],
          ),
        );

        if (!mounted) return;

        if (confirmed != true) {
          setState(() => isProcessing = false);
          return;
        }

        await widget.firestoreService.sellProduct(
          productId: product.id,
          productName: product.name,
          price: product.price,
          currentStock: product.stock,
          quantitySold: quantity,
          storeId: product.storeId,
        );

        if (!mounted) return;

        saleCompleted = true;
        Navigator.of(context).pop();

        if (widget.parentContext.mounted) {
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            const SnackBar(
              content: Text("Sale Recorded Successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (widget.parentContext.mounted) {
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted && !saleCompleted) {
          setState(() => isProcessing = false);
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      final product = widget.product;

      return AlertDialog(
        title: const Text("Sell Product"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text("Current Stock: ${product.stock}"),
              const SizedBox(height: 15),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                enabled: !isProcessing,
                decoration: const InputDecoration(
                  labelText: "Quantity Sold",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isProcessing
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: isProcessing ? null : processSale,
            child: isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Sell"),
          ),
        ],
      );
    }
  }
