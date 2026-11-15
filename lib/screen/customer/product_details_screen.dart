
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'dart:convert';

import '../../models/product_model.dart';
import '../../services/firestore_service.dart';
import 'store_location_screen.dart';

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// ============================================================
// PRODUCT DETAILS SCREEN
// ============================================================

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        centerTitle: true,
      ),
      body: ProductDetailsContent(
        product: widget.product,
      ),
    );
  }
}

// ============================================================
// PRODUCT DETAILS CONTENT
// ============================================================

class ProductDetailsContent extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsContent({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsContent> createState() =>
      _ProductDetailsContentState();
}

class _ProductDetailsContentState
    extends State<ProductDetailsContent> {
  Map<String, dynamic>? storeData;

  bool isLoading = true;

  final FirebaseAuth auth = FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirestoreService firestoreService =
      FirestoreService();

  @override
  void initState() {
    super.initState();
    loadStore();
  }

  // ============================================================
  // UPLOAD PAYMENT PROOF TO CLOUDINARY
  // ============================================================

  Future<String> uploadPaymentProof(XFile imageFile) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/z1swumqg/image/upload',
    );

    final imageBytes = await imageFile.readAsBytes();

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = 'motofind_upload'
      ..fields['folder'] = 'motofind/payments'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: imageFile.name,
        ),
      );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    final Map<String, dynamic> result =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 ||
        result['secure_url'] == null) {
      throw Exception(
        'Payment screenshot upload failed. Please try again.',
      );
    }

    return result['secure_url'].toString();
  }

  // ============================================================
  // LOAD STORE
  // ============================================================

  Future<void> loadStore() async {
    try {
      final String storeId =
          widget.product.storeId.trim();

      debugPrint("PRODUCT STORE ID: $storeId");

      if (storeId.isEmpty) {
        if (!mounted) return;

        setState(() {
          storeData = null;
          isLoading = false;
        });

        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> doc =
          await firestore
              .collection("stores")
              .doc(storeId)
              .get();

      if (!mounted) return;

      if (doc.exists) {
        setState(() {
          storeData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          storeData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("LOAD STORE ERROR: $e");

      if (!mounted) return;

      setState(() {
        storeData = null;
        isLoading = false;
      });
    }
  }

  // ============================================================
  // RESERVATION DIALOG
  // ============================================================

  Future<void> reserveDialog(
    BuildContext context,
    int availableStock,
  ) async {
    final User? user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first.'),
        ),
      );
      return;
    }

    if (availableStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is out of stock.'),
        ),
      );
      return;
    }

    int quantity = 1;

    // ==========================================================
    // STEP 1: SELECT QUANTITY
    // ==========================================================

    final int? selectedQuantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reserve Product'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Price: ₱${widget.product.price.toStringAsFixed(2)}',
                  ),
                  Text(
                    'Available stock: $availableStock',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () {
                                setDialogState(() {
                                  quantity--;
                                });
                              }
                            : null,
                        icon: const Icon(
                          Icons.remove_circle_outline,
                        ),
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: quantity < availableStock
                            ? () {
                                setDialogState(() {
                                  quantity++;
                                });
                              }
                            : null,
                        icon: const Icon(
                          Icons.add_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    'Total: ₱${(widget.product.price * quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      quantity,
                    );
                  },
                  child: const Text('CONTINUE'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedQuantity == null) return;

    if (!mounted) return;

    // ==========================================================
    // STEP 2: GCASH PAYMENT, NOTE, AND SCREENSHOT
    // ==========================================================

   String reservationNote = '';

final double totalAmount =
    widget.product.price * selectedQuantity;

final double refundCharge = totalAmount * 0.15;

final double estimatedRefund =
    totalAmount - refundCharge;

bool agreeToReservationPolicy = false;

    final XFile? paymentScreenshot =
        await showDialog<XFile>(
      context: context,
      barrierDismissible: false,
      builder: (paymentContext) {
        XFile? selectedImage;
        Uint8List? selectedImageBytes;
        bool pickingImage = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> chooseScreenshot() async {
              if (pickingImage) return;

              setDialogState(() {
                pickingImage = true;
              });

              try {
                final XFile? pickedFile =
                    await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );

                if (pickedFile != null) {
                  final Uint8List bytes =
                      await pickedFile.readAsBytes();

                  if (!paymentContext.mounted) return;

                  setDialogState(() {
                    selectedImage = pickedFile;
                    selectedImageBytes = bytes;
                  });
                }
              } catch (e) {
                if (paymentContext.mounted) {
                  ScaffoldMessenger.of(
                    paymentContext,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to select image: $e',
                      ),
                    ),
                  );
                }
              } finally {
                if (paymentContext.mounted) {
                  setDialogState(() {
                    pickingImage = false;
                  });
                }
              }
            }

            final double dialogHeight =
                MediaQuery.of(paymentContext).size.height;

            return AlertDialog(
              title: const Text('Pay through GCash'),
              content: SizedBox(
                width: 420,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: dialogHeight * 0.55,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.product.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quantity: $selectedQuantity',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total payment: ₱${(widget.product.price * selectedQuantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                       
                        // STORE OWNER'S GCASH QR CODE
                        if (storeData?['gcashQrUrl'] != null &&
                            storeData!['gcashQrUrl']
                                .toString()
                                .trim()
                                .isNotEmpty)
                          Image.network(
                            storeData!['gcashQrUrl'].toString(),
                            height: 180,
                            width: 180,
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
                                height: 180,
                                width: 180,
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
                                height: 120,
                                child: Center(
                                  child: Text(
                                    'Unable to load the store GCash QR code.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'This store has not uploaded its GCash QR code yet. '
                              'Please contact the store owner.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        const Text(
                          'Pay the exact amount using the QR code. '
                          'Then upload a screenshot of your successful payment.',
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // OPTIONAL RESERVATION NOTE
                        TextField(
                          maxLines: 3,
                          maxLength: 250,
                          decoration: InputDecoration(
                            labelText:
                                'Reservation Note (Optional)',
                            hintText:
                                'Add a note for the store owner...',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            alignLabelWithHint: true,
                          ),
                          onChanged: (value) {
                            reservationNote = value;
                          },
                        ),

                        const SizedBox(height: 8),
                        
                        // RESERVATION AND REFUND POLICY
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            border: Border.all(
                              color: Colors.orange,
                            ),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Reservation and Refund Policy',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'If you do not claim your reserved '
                                'item, you must personally visit '
                                'the store to request a refund.',
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'A 15% charge of the total '
                                'reservation amount may be '
                                'deducted according to the '
                                'agreed refund policy.',
                              ),
                              const Divider(),
                              Text(
                                'Total Reservation: '
                                '₱${totalAmount.toStringAsFixed(2)}',
                              ),
                              Text(
                                '15% Charge: '
                                '₱${refundCharge.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Estimated Refund: '
                                '₱${estimatedRefund.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: agreeToReservationPolicy,
                                title: const Text(
                                  'I have read and agree to the '
                                  'Reservation and Refund Policy.',
                                  style: TextStyle(fontSize: 13),
                                ),
                                onChanged: (value) {
                                  setDialogState(() {
                                    agreeToReservationPolicy =
                                        value ?? false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),


                        // SELECT PAYMENT SCREENSHOT
                        OutlinedButton.icon(
                          onPressed: pickingImage
                              ? null
                              : chooseScreenshot,
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            selectedImage == null
                                ? 'SELECT PAYMENT SCREENSHOT'
                                : 'CHANGE SCREENSHOT',
                          ),
                        ),

                        if (pickingImage)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          ),

                        // SCREENSHOT PREVIEW
                        if (selectedImage != null &&
                            selectedImageBytes != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8),
                            child: Image.memory(
                              selectedImageBytes!,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const SizedBox(
                                  height: 140,
                                  child: Center(
                                    child: Text(
                                      'Unable to preview screenshot.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Screenshot selected',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: pickingImage
                      ? null
                      : () {
                          Navigator.pop(paymentContext);
                        },
                  child: const Text('CANCEL'),
                ),
              
ElevatedButton(
  onPressed: selectedImage == null ||
          pickingImage ||
          !agreeToReservationPolicy
      ? null
      : () {
          Navigator.pop(
            paymentContext,
            selectedImage,
          );
        },
  child: const Text('SUBMIT PAYMENT'),
),

              ],
            );
          },
        );
      },
    );

    if (paymentScreenshot == null) return;

    if (!mounted) return;

    // ==========================================================
    // STEP 3: UPLOAD PROOF AND CREATE RESERVATION
    // ==========================================================

    bool loadingShown = false;

    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      loadingShown = true;

      final String paymentProofUrl =
          await uploadPaymentProof(paymentScreenshot);

      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await firestore
              .collection('users')
              .doc(user.uid)
              .get();

      final Map<String, dynamic> userData =
          userDoc.data() ?? {};

      final String customerName =
          userData['fullName']?.toString().trim().isNotEmpty ==
                  true
              ? userData['fullName'].toString().trim()
              : 'Customer';

      // SAVE RESERVATION WITH PAYMENT PROOF AND NOTE
      // Firestore transaction validates the actual stock.
      await firestoreService.reserveProduct(
        customerId: user.uid,
        customerName: customerName,
        product: widget.product,
        quantity: selectedQuantity,
        paymentProofUrl: paymentProofUrl,
        reservationNote: reservationNote.trim(),
      );

      if (!mounted) return;

      if (loadingShown) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingShown = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reservation submitted. Payment is pending verification.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      if (loadingShown) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingShown = false;
      }

      debugPrint('RESERVE PRODUCT ERROR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reservation failed:\n$e'),
        ),
      );
    }
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget buildProductImage() {
    final String imageUrl =
        widget.product.imageUrl.trim();

    if (imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Icon(
            Icons.motorcycle,
            size: 100,
            color: Colors.grey,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) {
            return Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(12),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: SizedBox(
                      width: double.infinity,
                      height:
                          MediaQuery.of(dialogContext)
                                  .size
                                  .height *
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
                    tooltip: "Close image",
                    onPressed: () {
                      Navigator.pop(dialogContext);
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
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          loadingBuilder: (
            context,
            child,
            loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }

            return Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 70,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // REAL-TIME RESERVE BUTTON
  // ============================================================

  Widget buildReserveButton() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('products')
          .doc(widget.product.id)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final int currentStock = data?['stock'] is num
            ? (data!['stock'] as num).toInt()
            : widget.product.stock;

        final bool outOfStock =
            !snapshot.hasError &&
            snapshot.hasData &&
            !snapshot.data!.exists
                ? true
                : currentStock <= 0;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: outOfStock || snapshot.hasError
                ? null
                : () {
                    reserveDialog(context, currentStock);
                  },
            icon: const Icon(Icons.event_available),
            label: Text(
              outOfStock ? "OUT OF STOCK" : "RESERVE NOW",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD PRODUCT DETAILS AND STORE INFORMATION
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final ProductModel product = widget.product;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildProductImage(),

                  const SizedBox(height: 20),

                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "₱${product.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // REAL-TIME AVAILABLE STOCK AND LOW STOCK BADGE
                  // ==================================================

                  StreamBuilder<
                      DocumentSnapshot<Map<String, dynamic>>>(
                    stream: firestore
                        .collection('products')
                        .doc(product.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data();

                      final int currentStock =
                          data?['stock'] is num
                              ? (data!['stock'] as num).toInt()
                              : product.stock;

                      final bool isLowStock =
                          currentStock <= product.alertStock;

                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.inventory_2,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  snapshot.hasError
                                      ? "Available Stock: Unable to load"
                                      : "Available Stock: $currentStock",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isLowStock
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),

                          if (isLowStock) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "LOW STOCK",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),

                  if (product.category.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.category,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Category: ${product.category}",
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  buildReserveButton(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "Store Information",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (storeData == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.store,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Store information not available.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: loadStore,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            )
          else
            buildStoreCard(),
        ],
      ),
    );
  }

  // ============================================================
  // STORE CARD
  // ============================================================

  Widget buildStoreCard() {
    final Map<String, dynamic> data = storeData!;

    final String storeName =
        data["storeName"]?.toString() ?? "No Store Name";

    final String ownerName =
        data["ownerName"]?.toString() ?? "N/A";

    final String address =
        data["address"]?.toString() ?? "N/A";

    final String phone =
        data["phone"]?.toString() ?? "N/A";

    final String storeImage =
        data["storeImage"]?.toString() ?? "";

    final double? latitude = data["latitude"] is num
        ? (data["latitude"] as num).toDouble()
        : null;

    final double? longitude = data["longitude"] is num
        ? (data["longitude"] as num).toDouble()
        : null;

    debugPrint("================================");
    debugPrint("STORE NAME: $storeName");
    debugPrint("STORE LATITUDE: $latitude");
    debugPrint("STORE LONGITUDE: $longitude");
    debugPrint("================================");

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: storeImage.isNotEmpty
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          NetworkImage(storeImage),
                    )
                  : const CircleAvatar(
                      radius: 50,
                      child: Icon(
                        Icons.store,
                        size: 45,
                      ),
                    ),
            ),

            const SizedBox(height: 15),

            Text(
              storeName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("Owner: $ownerName"),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("Address: $address"),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.phone,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("Contact: $phone"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (latitude == null || longitude == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_off,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Store location is not available.",
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StoreLocationScreen(
                          storeLatitude: latitude,
                          storeLongitude: longitude,
                          storeName: storeName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text(
                    "VIEW STORE LOCATION",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
