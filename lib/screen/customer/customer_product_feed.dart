import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/product_model.dart';

class CustomerProductFeed extends StatefulWidget {
  final List<ProductModel> products;
  final void Function(ProductModel product) onProductTap;

  const CustomerProductFeed({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  State<CustomerProductFeed> createState() =>
      _CustomerProductFeedState();
}

class _CustomerProductFeedState
    extends State<CustomerProductFeed> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final Set<String> favoriteProductIds = {};

  bool loadingFavorites = true;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final User? user = auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            loadingFavorites = false;
          });
        }
        return;
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await firestore
              .collection("users")
              .doc(user.uid)
              .collection("favorites")
              .get();

      if (!mounted) return;

      setState(() {
        favoriteProductIds
          ..clear()
          ..addAll(
            snapshot.docs.map(
              (doc) => doc.id,
            ),
          );

        loadingFavorites = false;
      });
    } catch (e) {
      debugPrint("LOAD FAVORITES ERROR: $e");

      if (!mounted) return;

      setState(() {
        loadingFavorites = false;
      });
    }
  }

  Future<void> toggleFavorite(
    ProductModel product,
  ) async {
    final User? user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please login first.",
          ),
        ),
      );
      return;
    }

    final DocumentReference<Map<String, dynamic>>
        favoriteRef = firestore
            .collection("users")
            .doc(user.uid)
            .collection("favorites")
            .doc(product.id);

    final bool isFavorite =
        favoriteProductIds.contains(product.id);

    try {
      if (isFavorite) {
        await favoriteRef.delete();

        if (!mounted) return;

        setState(() {
          favoriteProductIds.remove(product.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Removed from Cart.",
            ),
          ),
        );
      } else {
        await favoriteRef.set({
          "productId": product.id,
          "name": product.name,
          "price": product.price,
          "stock": product.stock,
          "alertStock": product.alertStock,
          "category": product.category,
          "storeId": product.storeId,
          "imageUrl": product.imageUrl,
          "createdAt": FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        setState(() {
          favoriteProductIds.add(product.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Added to Cart.",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("TOGGLE FAVORITE ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Cart update failed:\n$e",
          ),
        ),
      );
    }
  }

  Future<String> getStoreName(
    String storeId,
  ) async {
    try {
      if (storeId.trim().isEmpty) {
        return "Unknown Store";
      }

      final DocumentSnapshot<Map<String, dynamic>>
          doc = await firestore
              .collection("stores")
              .doc(storeId)
              .get();

      if (!doc.exists) {
        return "Unknown Store";
      }

      final Map<String, dynamic> data =
          doc.data() ?? {};

      return data["storeName"]
              ?.toString()
              .trim() ??
          "Unknown Store";
    } catch (e) {
      debugPrint("GET STORE NAME ERROR: $e");
      return "Unknown Store";
    }
  }

  
Widget buildProductImage(
  ProductModel product, {
  required double imageHeight,
}) {
  if (product.imageUrl.trim().isEmpty) {
    return Container(
      width: double.infinity,
      height: imageHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: const Icon(
        Icons.motorcycle,
        size: 60,
        color: Colors.grey,
      ),
    );
  }

  return ClipRRect(
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(16),
    ),
    child: Image.network(
      product.imageUrl,
      width: double.infinity,
      height: imageHeight,
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
          height: imageHeight,
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
          height: imageHeight,
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.broken_image,
            size: 60,
            color: Colors.grey,
          ),
        );
      },
    ),
  );
}


  Widget buildProductCard(
    ProductModel product,
  ) {
    final bool isFavorite =
        favoriteProductIds.contains(product.id);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          widget.onProductTap(product);
        },
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
           buildProductImage(
  product,
  imageHeight:
      MediaQuery.of(context).size.width >= 900
          ? 230
          : 150,
),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  10,
                  12,
                  12,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "₱${product.price.toStringAsFixed(2)}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 17,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            "Stock: ${product.stock}",
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: product.stock <=
                                      product.alertStock
                                  ? Colors.orange
                                  : Colors.grey.shade700,
                              fontWeight:
                                  product.stock <=
                                          product.alertStock
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    FutureBuilder<String>(
                      future: getStoreName(
                        product.storeId,
                      ),
                      builder: (
                        context,
                        snapshot,
                      ) {
                        final String storeName =
                            snapshot.data ??
                                "Loading store...";

                        return Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.store_outlined,
                              size: 17,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                storeName,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: loadingFavorites
                            ? null
                            : () {
                                toggleFavorite(product);
                              },
                        icon: Icon(
                          isFavorite
                              ? Icons.shopping_cart
                              : Icons.add_shopping_cart,
                          size: 17,
                          color: isFavorite
                              ? Colors.blue
                              : null,
                        ),
                       label: FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    isFavorite
        ? "In Cart"
        : "Add to Cart",
    maxLines: 1,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: isFavorite
          ? Colors.blue
          : null,
    ),
  ),
),
                        style:
                            OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isFavorite
                                ? Colors.blue
                                : Colors.grey.shade400,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        int columns = 2;

        if (constraints.maxWidth >= 1200) {
          columns = 5;
        } else if (constraints.maxWidth >= 900) {
          columns = 4;
        } else if (constraints.maxWidth >= 600) {
          columns = 3;
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            8,
            8,
            8,
            20,
          ),
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 0.45,
          ),
          itemCount: widget.products.length,
          itemBuilder: (
            context,
            index,
          ) {
            final ProductModel product =
                widget.products[index];

            return buildProductCard(product);
          },
        );
      },
    );
  }
}