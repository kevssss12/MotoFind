import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/product_model.dart';
import 'product_details_screen.dart';

// ============================================================
// CART SCREEN
// ============================================================

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
  });

  @override
  State<FavoritesScreen> createState() =>
      _FavoritesScreenState();
}

class _FavoritesScreenState
    extends State<FavoritesScreen> {
  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // REMOVE CART ITEM
  // ============================================================

  Future<void> removeFavorite(
    String productId,
  ) async {
    final User? user =
        auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await firestore
          .collection("users")
          .doc(user.uid)
          .collection("favorites")
          .doc(productId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Removed from Cart.",
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        "REMOVE FAVORITE ERROR: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Failed to remove cart item:\n$e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // OPEN PRODUCT DETAILS
  // ============================================================

  void openProduct(
    Map<String, dynamic> data,
  ) {
    try {
      final String productId =
          data["productId"]?.toString() ?? "";

      if (productId.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Product ID is missing.",
            ),
          ),
        );

        return;
      }

      final ProductModel product =
          ProductModel.fromFirestore(
        productId,
        data,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductDetailsScreen(
            product: product,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        "OPEN FAVORITE PRODUCT ERROR: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Unable to open product:\n$e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // CART ITEM
  // ============================================================

  Widget buildFavoriteCard(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data =
        doc.data() ?? {};

    final String name =
        data["name"]?.toString() ??
            "Unknown Product";

    final String productId =
        data["productId"]?.toString() ??
            doc.id;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          openProduct(data);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              // ==================================================
// PRODUCT IMAGE
// ==================================================

ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: (data["imageUrl"]?.toString().trim().isNotEmpty ?? false)
      ? Image.network(
          data["imageUrl"].toString(),
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              width: 70,
              height: 70,
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 30,
              ),
            );
          },
        )
      : Container(
          width: 70,
          height: 70,
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.motorcycle,
            color: Colors.grey,
            size: 30,
          ),
        ),
),

              const SizedBox(
                width: 14,
              ),

              // ==================================================
              // PRODUCT NAME
              // ==================================================

              Expanded(
                child: Text(
                  name,
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

              // ==================================================
              // REMOVE CART ITEM
              // ==================================================

              IconButton(
                tooltip:
                    "Remove from Cart",
                onPressed: () {
                  removeFavorite(
                    productId,
                  );
                },
                icon: const Icon(
                  Icons.remove_shopping_cart,
                  color: Colors.red,
                  size: 25,
                ),
              ),

              // ==================================================
              // OPEN PRODUCT DETAILS
              // ==================================================

              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
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
    final User? user =
        auth.currentUser;

    // ==========================================================
    // NO USER
    // ==========================================================

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text("Cart"),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            "Please login first.",
          ),
        ),
      );
    }

    // ==========================================================
    // CART STREAM
    // ==========================================================

    final Stream<
            QuerySnapshot<
                Map<String, dynamic>>>
        stream = firestore
            .collection("users")
            .doc(user.uid)
            .collection("favorites")
            .orderBy(
              "createdAt",
              descending: true,
            )
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Cart",
        ),
        centerTitle: true,
      ),

      // ========================================================
      // CART BODY
      // ========================================================

      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: stream,
        builder: (
          context,
          snapshot,
        ) {
          // ====================================================
          // LOADING
          // ====================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          // ====================================================
          // ERROR
          // ====================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      "Unable to load Cart.",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      "${snapshot.error}",
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ====================================================
          // EMPTY CART
          // ====================================================

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      size: 90,
                      color: Colors.grey,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      "Your Cart is Empty",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      "Products you add to Cart will appear here.",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ====================================================
          // CART DOCUMENTS
          // ====================================================

          final List<
                  DocumentSnapshot<
                      Map<String, dynamic>>>
              docs =
              snapshot.data!.docs;

          // ====================================================
          // CART LIST
          // ====================================================

          return ListView.separated(
            padding:
                const EdgeInsets.all(16),

            itemCount:
                docs.length,

            separatorBuilder: (
              context,
              index,
            ) {
              return const SizedBox(
                height: 10,
              );
            },

            itemBuilder: (
              context,
              index,
            ) {
              return buildFavoriteCard(
                docs[index],
              );
            },
          );
        },
      ),
    );
  }
}