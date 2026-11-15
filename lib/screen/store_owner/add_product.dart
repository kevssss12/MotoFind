
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController priceController =
      TextEditingController();

  final TextEditingController stockController =
      TextEditingController();

  final TextEditingController alertStockController =
      TextEditingController();

  final TextEditingController imageUrlController =
      TextEditingController();

  // ============================================================
  // SERVICES
  // ============================================================

  final FirestoreService _firestoreService =
      FirestoreService();

  final ImagePicker _imagePicker = ImagePicker();

  // ============================================================
  // VARIABLES
  // ============================================================

  XFile? selectedImage;

  bool isSaving = false;
  bool isUploadingImage = false;

  // ============================================================
  // PICK PRODUCT IMAGE
  // ============================================================

  Future<void> pickProductImage() async {
    if (isSaving || isUploadingImage) {
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        selectedImage = image;
        isUploadingImage = true;
      });

      final String imageUrl =
          await CloudinaryService.uploadImage(image) ?? "";

      if (imageUrl.trim().isEmpty) {
        throw Exception("Image upload failed.");
      }

      if (!mounted) {
        return;
      }

      setState(() {
        imageUrlController.text = imageUrl.trim();
        isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Image uploaded successfully.",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("IMAGE UPLOAD ERROR: $e");

      if (!mounted) {
        return;
      }

      setState(() {
        isUploadingImage = false;
        selectedImage = null;
      });

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

  // ============================================================
  // SHOW IMAGE FROM URL
  // ============================================================

  void showImagePreview() {
    final String url = imageUrlController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No image URL available.",
          ),
        ),
      );

      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
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
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
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
                            child: CircularProgressIndicator(),
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
                                  MainAxisAlignment.center,
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

              // CLOSE IMAGE PREVIEW
              Positioned(
                top: 5,
                right: 5,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
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
  // SAVE PRODUCT
  // ============================================================

  Future<void> saveProduct() async {
    if (isSaving || isUploadingImage) {
      return;
    }

    try {
      // ========================================================
      // VALIDATE NAME
      // ========================================================

      final String name = nameController.text.trim();

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please enter the product name.",
            ),
          ),
        );

        return;
      }

      // ========================================================
      // GET IMAGE URL
      // ========================================================

      final String imageUrl =
          imageUrlController.text.trim();

      if (imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please upload a product image first.",
            ),
          ),
        );

        return;
      }

      // ========================================================
      // VALIDATE PRICE
      // ========================================================

      final double? price = double.tryParse(
        priceController.text.trim(),
      );

      if (price == null || price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please enter a valid price.",
            ),
          ),
        );

        return;
      }

      // ========================================================
      // VALIDATE STOCK
      // ========================================================

      final int? stock = int.tryParse(
        stockController.text.trim(),
      );

      if (stock == null || stock < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please enter a valid stock quantity.",
            ),
          ),
        );

        return;
      }

      // ========================================================
      // VALIDATE ALERT STOCK
      // ========================================================

      final int? alertStock = int.tryParse(
        alertStockController.text.trim(),
      );

      if (alertStock == null || alertStock < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please enter a valid low stock alert.",
            ),
          ),
        );

        return;
      }

      // ========================================================
      // START SAVING
      // ========================================================

      setState(() {
        isSaving = true;
      });

      debugPrint("======================================");
      debugPrint("START ADD PRODUCT");

      // ========================================================
      // CURRENT USER
      // ========================================================

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in.");
      }

      debugPrint("OWNER UID: ${user.uid}");

      // ========================================================
      // GET USER DOCUMENT
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

      if (!userDoc.exists) {
        throw Exception(
          "User document not found.",
        );
      }

      final Map<String, dynamic> userData =
          userDoc.data() ?? {};

      debugPrint("USER DATA: $userData");

      // ========================================================
      // GET STORE ID
      // ========================================================

      final dynamic storeIdValue =
          userData["storeId"];

      if (storeIdValue == null ||
          storeIdValue.toString().trim().isEmpty) {
        throw Exception(
          "Store ID not found. Please make sure your store is properly registered.",
        );
      }

      final String storeId =
          storeIdValue.toString().trim();

      debugPrint("STORE ID: $storeId");

      // ========================================================
      // SAVE PRODUCT
      // ========================================================

      debugPrint(
        "SAVING PRODUCT TO FIRESTORE...",
      );

      await _firestoreService.addProduct(
        name: name,
        price: price,
        stock: stock,
        alertStock: alertStock,
        storeId: storeId,
        imageUrl: imageUrl,
      );

      debugPrint(
        "PRODUCT SAVED SUCCESSFULLY",
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Product Added Successfully!",
          ),
          backgroundColor: Colors.green,
        ),
      );

      // ========================================================
      // CLEAR FORM
      // ========================================================

      nameController.clear();
      priceController.clear();
      stockController.clear();
      alertStockController.clear();
      imageUrlController.clear();

      setState(() {
        selectedImage = null;
        isSaving = false;
      });
    } catch (e) {
      debugPrint(
        "ERROR ADDING PRODUCT: $e",
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error adding product:\n$e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    alertStockController.dispose();
    imageUrlController.dispose();

    super.dispose();
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
          "Add Motorcycle Part",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          color: pageBackground,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1100,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PAGE HEADER
                      const Row(
                        children: [
                          Icon(
                            Icons.add_box_outlined,
                            color: primaryBlue,
                            size: 30,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Add Motorcycle Part",
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: darkBlue,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Enter the product details below.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Divider(
                        color: Color(0xFFE1E8F0),
                      ),

                      const SizedBox(height: 18),

                      // PRODUCT IMAGE SECTION
                      const Text(
                        "Product Image",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE1E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (imageUrlController.text
                                .trim()
                                .isNotEmpty) ...[
                              InkWell(
                                onTap: showImagePreview,
                                borderRadius:
                                    BorderRadius.circular(12),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrlController.text.trim(),
                                    height: 190,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return const SizedBox(
                                        height: 130,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image_outlined,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                "Image preview unavailable",
                                                style: TextStyle(
                                                  color: Colors.grey,
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
                              const SizedBox(height: 12),
                            ] else
                              Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F8FC),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE1E8F0),
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: primaryBlue,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "No product image selected",
                                      style: TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: isSaving ||
                                        isUploadingImage
                                    ? null
                                    : pickProductImage,
                                icon: isUploadingImage
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.cloud_upload_outlined,
                                      ),
                                label: Text(
                                  isUploadingImage
                                      ? "UPLOADING IMAGE..."
                                      : imageUrlController.text
                                              .trim()
                                              .isEmpty
                                          ? "UPLOAD PRODUCT IMAGE"
                                          : "CHANGE PRODUCT IMAGE",
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryBlue,
                                  side: const BorderSide(
                                    color: primaryBlue,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),

                            if (imageUrlController.text
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Image uploaded. Tap the preview to enlarge.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // PRODUCT DETAILS
                      const Text(
                        "Product Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // WHITE FORM CONTAINER
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE1E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: nameController,
                              enabled: !isSaving,
                              textInputAction:
                                  TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: "Part Name",
                                hintText:
                                    "Enter motorcycle part name",
                                prefixIcon: const Icon(
                                  Icons.build_outlined,
                                  color: primaryBlue,
                                ),
                                filled: true,
                                fillColor:
                                    const Color(0xFFF8FAFD),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE1E8F0),
                                  ),
                                ),
                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: primaryBlue,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextField(
                              controller: priceController,
                              enabled: !isSaving,
                              keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                decimal: true,
                              ),
                              textInputAction:
                                  TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: "Price",
                                hintText: "Enter price in pesos",
                                prefixIcon: const Icon(
                                  Icons.payments_outlined,
                                  color: primaryBlue,
                                ),
                                prefixText: "₱ ",
                                filled: true,
                                fillColor:
                                    const Color(0xFFF8FAFD),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE1E8F0),
                                  ),
                                ),
                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: primaryBlue,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextField(
                              controller: stockController,
                              enabled: !isSaving,
                              keyboardType:
                                  TextInputType.number,
                              textInputAction:
                                  TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: "Stock Quantity",
                                hintText:
                                    "Enter available quantity",
                                prefixIcon: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: primaryBlue,
                                ),
                                filled: true,
                                fillColor:
                                    const Color(0xFFF8FAFD),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE1E8F0),
                                  ),
                                ),
                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: primaryBlue,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextField(
                              controller: alertStockController,
                              enabled: !isSaving,
                              keyboardType:
                                  TextInputType.number,
                              textInputAction:
                                  TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: "Low Stock Alert",
                                hintText: "Example: 5",
                                prefixIcon: const Icon(
                                  Icons.warning_amber_outlined,
                                  color: primaryBlue,
                                ),
                                helperText:
                                    "You will use this quantity as the low-stock threshold.",
                                filled: true,
                                fillColor:
                                    const Color(0xFFF8FAFD),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE1E8F0),
                                  ),
                                ),
                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: primaryBlue,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // SAVE PRODUCT
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: isSaving ||
                                  isUploadingImage
                              ? null
                              : saveProduct,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 21,
                                  height: 21,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.save_outlined,
                                ),
                          label: Text(
                            isSaving
                                ? "SAVING PRODUCT..."
                                : "SAVE PRODUCT",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                Colors.blueGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            elevation: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
