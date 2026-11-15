import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/cloudinary_service.dart';
import 'store_location_picker.dart';

class StoreProfile extends StatefulWidget {
  const StoreProfile({super.key});

  @override
  State<StoreProfile> createState() => _StoreProfileState();
}

class _StoreProfileState extends State<StoreProfile> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // VARIABLES
  // ============================================================

  bool isEditing = false;
  bool isUpdatingLocation = false;

  String? imageUrl;
  String? gcashQrUrl;
  bool isUploadingGcashQr = false;

  String? email;
  String? permitNumber;
  String? status;
  String? subscriptionPlan;
  String? subscriptionStatus;

  Timestamp? subscriptionStart;
  Timestamp? subscriptionEnd;

  double? latitude;
  double? longitude;

  String? storeId;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController storeNameController =
      TextEditingController();

  final TextEditingController ownerNameController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadStoreProfile();

    storeNameController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    storeNameController.dispose();
    ownerNameController.dispose();
    addressController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  // ============================================================
  // GET USER STORE ID
  // ============================================================

  Future<String?> getUserStoreId() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      return null;
    }

    final data = userDoc.data();

    final id = data?["storeId"];

    if (id == null || id.toString().trim().isEmpty) {
      return null;
    }

    return id.toString();
  }

  // ============================================================
  // SAVE PROFILE CHANGES
  // ============================================================

  Future<void> saveChanges() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final correctStoreId = await getUserStoreId();

      if (correctStoreId == null) {
        throw Exception(
          "Store ID not found in users collection.",
        );
      }

      storeId = correctStoreId;

      // ========================================================
      // UPDATE USERS
      // ========================================================

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set(
        {
          "storeId": correctStoreId,
          "storeName": storeNameController.text.trim(),
          "fullName": ownerNameController.text.trim(),
          "storeAddress": addressController.text.trim(),
          "phone": phoneController.text.trim(),
          "storeImage": imageUrl,

          if (latitude != null) "latitude": latitude,
          if (longitude != null) "longitude": longitude,
        },
        SetOptions(merge: true),
      );

      // ========================================================
      // UPDATE STORES
      // ========================================================

      await FirebaseFirestore.instance
          .collection("stores")
          .doc(correctStoreId)
          .set(
        {
          "storeId": correctStoreId,
          "ownerId": user.uid,
          "storeName": storeNameController.text.trim(),
          "ownerName": ownerNameController.text.trim(),
          "address": addressController.text.trim(),
          "phone": phoneController.text.trim(),
          "storeImage": imageUrl,

          if (latitude != null) "latitude": latitude,
          if (longitude != null) "longitude": longitude,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Profile updated successfully!",
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        "SAVE PROFILE ERROR: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error saving profile: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // SELECT STORE LOCATION
  // ============================================================

  Future<void> selectStoreLocation() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    if (isUpdatingLocation) {
      return;
    }

    try {
      setState(() {
        isUpdatingLocation = true;
      });

      // ========================================================
      // GET STORE ID
      // ========================================================

      final correctStoreId = await getUserStoreId();

      if (correctStoreId == null) {
        throw Exception(
          "Store ID not found in users collection.",
        );
      }

      storeId = correctStoreId;

      // ========================================================
      // OPEN LOCATION PICKER
      // ========================================================

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return StoreLocationPicker(
              initialLatitude: latitude,
              initialLongitude: longitude,
            );
          },
        ),
      );

      // ========================================================
      // USER CANCELLED
      // ========================================================

      if (result == null) {
        if (!mounted) return;

        setState(() {
          isUpdatingLocation = false;
        });

        return;
      }

      // ========================================================
      // GET LOCATION RESULT
      // ========================================================

      double? selectedLatitude;
      double? selectedLongitude;

      if (result is Map) {
        final lat = result["latitude"];
        final lng = result["longitude"];

        if (lat is num) {
          selectedLatitude = lat.toDouble();
        }

        if (lng is num) {
          selectedLongitude = lng.toDouble();
        }
      }

      // ========================================================
      // VALIDATE LOCATION
      // ========================================================

      if (selectedLatitude == null ||
          selectedLongitude == null) {
        throw Exception(
          "Invalid location returned from map.",
        );
      }

      debugPrint(
        "=================================",
      );

      debugPrint(
        "STORE LOCATION SELECTED",
      );

      debugPrint(
        "STORE ID: $correctStoreId",
      );

      debugPrint(
        "LATITUDE: $selectedLatitude",
      );

      debugPrint(
        "LONGITUDE: $selectedLongitude",
      );

      debugPrint(
        "=================================",
      );

      // ========================================================
      // SAVE LOCATION
      // ========================================================

      await saveStoreLocation(
        selectedLatitude,
        selectedLongitude,
        correctStoreId,
        user.uid,
      );

      // ========================================================
      // UPDATE UI
      // ========================================================

      if (!mounted) return;

      setState(() {
        latitude = selectedLatitude;
        longitude = selectedLongitude;
        isUpdatingLocation = false;
      });

      // ========================================================
      // SUCCESS
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Store location saved successfully!\n\n"
            "Latitude: "
            "${selectedLatitude.toStringAsFixed(8)}\n"
            "Longitude: "
            "${selectedLongitude.toStringAsFixed(8)}",
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint(
        "LOCATION PICKER ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        isUpdatingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Could not save store location.\n\n$e",
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  // ============================================================
  // SAVE STORE LOCATION
  // ============================================================

  Future<void> saveStoreLocation(
    double newLatitude,
    double newLongitude,
    String correctStoreId,
    String ownerId,
  ) async {
    // ==========================================================
    // SAVE TO STORES
    // ==========================================================

    await FirebaseFirestore.instance
        .collection("stores")
        .doc(correctStoreId)
        .set(
      {
        "storeId": correctStoreId,
        "ownerId": ownerId,
        "storeName": storeNameController.text.trim(),
        "ownerName": ownerNameController.text.trim(),
        "address": addressController.text.trim(),
        "phone": phoneController.text.trim(),
        "storeImage": imageUrl,
        "latitude": newLatitude,
        "longitude": newLongitude,
        "locationUpdatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // ==========================================================
    // SAVE TO USERS
    // ==========================================================

    await FirebaseFirestore.instance
        .collection("users")
        .doc(ownerId)
        .set(
      {
        "storeId": correctStoreId,
        "latitude": newLatitude,
        "longitude": newLongitude,
      },
      SetOptions(merge: true),
    );

    debugPrint(
      "STORE LOCATION SAVED",
    );

    debugPrint(
      "stores/$correctStoreId",
    );
  }

  // ============================================================
  // LOAD STORE PROFILE
  // ============================================================

  Future<void> loadStoreProfile() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return;
      }

      // ========================================================
      // LOAD USER
      // ========================================================

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint(
          "USER DOCUMENT NOT FOUND",
        );

        return;
      }

      final userData =
          userDoc.data() ?? <String, dynamic>{};

      // ========================================================
      // GET STORE ID
      // ========================================================

      final userStoreId =
          userData["storeId"]?.toString();

      if (userStoreId != null &&
          userStoreId.isNotEmpty) {
        storeId = userStoreId;

        debugPrint(
          "USER STORE ID: $storeId",
        );
      }

      // ========================================================
      // LOAD STORE
      // ========================================================

      Map<String, dynamic> storeData =
          <String, dynamic>{};

      if (storeId != null) {
        final storeDoc =
            await FirebaseFirestore.instance
                .collection("stores")
                .doc(storeId)
                .get();

        if (storeDoc.exists) {
          storeData =
              storeDoc.data() ??
                  <String, dynamic>{};

          debugPrint(
            "STORE DATA: $storeData",
          );
        } else {
          debugPrint(
            "STORE NOT FOUND: stores/$storeId",
          );
        }
      }

      // ========================================================
      // STORE DATA FIRST
      // USER DATA SECOND
      // ========================================================

      final storeName =
          storeData["storeName"] ??
          userData["storeName"] ??
          "";

      final ownerName =
          storeData["ownerName"] ??
          userData["fullName"] ??
          "";

      final address =
          storeData["address"] ??
          userData["storeAddress"] ??
          "";

      final phone =
          storeData["phone"] ??
          userData["phone"] ??
          "";

      final storeImage =
          storeData["storeImage"] ??
          userData["storeImage"];

      final storeLatitude =
          storeData["latitude"] ??
          userData["latitude"];

      final storeLongitude =
          storeData["longitude"] ??
          userData["longitude"];

      // ========================================================
      // UPDATE UI
      // ========================================================

      if (!mounted) return;

      setState(() {
        storeNameController.text =
            storeName.toString();

        ownerNameController.text =
            ownerName.toString();

        addressController.text =
            address.toString();

        phoneController.text =
            phone.toString();

        email =
            userData["email"]?.toString();

        permitNumber =
            userData["permitNumber"]?.toString();

        status =
            userData["status"]?.toString();

        subscriptionPlan =
            userData["subscriptionPlan"]?.toString();

        subscriptionStatus =
            userData["subscriptionStatus"]?.toString();

        // ======================================================
        // SUBSCRIPTION START
        // ======================================================

        final start =
            userData["subscriptionStart"];

        if (start is Timestamp) {
          subscriptionStart = start;
        }

        // ======================================================
        // SUBSCRIPTION END
        // ======================================================

        final end =
            userData["subscriptionEnd"];

        if (end is Timestamp) {
          subscriptionEnd = end;
        }

        // ======================================================
        // IMAGE
        // ======================================================

        imageUrl =
            storeImage?.toString();

        // ======================================================
        // LATITUDE
        // ======================================================

        if (storeLatitude is num) {
          latitude =
              storeLatitude.toDouble();
        }

        // ======================================================
        // LONGITUDE
        // ======================================================

        if (storeLongitude is num) {
          longitude =
              storeLongitude.toDouble();
        }
      });
    } catch (e) {
      debugPrint(
        "LOAD PROFILE ERROR: $e",
      );
    }
  }

  // ============================================================
  // PICK STORE LOGO
  // ============================================================

  Future<void> pickStoreLogo() async {
    try {
      final XFile? image =
          await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) {
        return;
      }

      // ========================================================
      // UPLOAD
      // ========================================================

      final url =
          await CloudinaryService.uploadImage(
        image,
      );

      if (url == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Upload failed",
            ),
          ),
        );

        return;
      }

      final user = _auth.currentUser;

      if (user == null) {
        return;
      }

      final correctStoreId =
          await getUserStoreId();

      if (correctStoreId == null) {
        throw Exception(
          "Store ID not found.",
        );
      }

      // ========================================================
      // UPDATE UI
      // ========================================================

      if (!mounted) return;

      setState(() {
        imageUrl = url;
      });

      // ========================================================
      // USERS
      // ========================================================

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set(
        {
          "storeId": correctStoreId,
          "storeImage": url,
        },
        SetOptions(merge: true),
      );

      // ========================================================
      // STORES
      // ========================================================

      await FirebaseFirestore.instance
          .collection("stores")
          .doc(correctStoreId)
          .set(
        {
          "storeId": correctStoreId,
          "ownerId": user.uid,
          "storeImage": url,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Store logo uploaded",
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        "LOGO ERROR: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error uploading logo: $e",
          ),
        ),
      );
    }
  }
  
  // ============================================================
  // UPLOAD GCASH QR CODE
  // ============================================================

  Future<void> pickGcashQr() async {
    if (isUploadingGcashQr) return;

    try {
      final user = _auth.currentUser;

      if (user == null) return;

      final correctStoreId = await getUserStoreId();

      if (correctStoreId == null) {
        throw Exception("Store ID not found.");
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null) return;

      if (!mounted) return;

      setState(() {
        isUploadingGcashQr = true;
      });

      final url = await CloudinaryService.uploadImage(image);

      if (url == null || url.isEmpty) {
        throw Exception("Failed to upload GCash QR code.");
      }

      await FirebaseFirestore.instance
          .collection("stores")
          .doc(correctStoreId)
          .set(
        {
          "storeId": correctStoreId,
          "ownerId": user.uid,
          "gcashQrUrl": url,
          "gcashQrUpdatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        gcashQrUrl = url;
        storeId = correctStoreId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("GCash QR code uploaded successfully!"),
        ),
      );
    } catch (e) {
      debugPrint("GCASH QR UPLOAD ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading GCash QR: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploadingGcashQr = false;
        });
      }
    }
  }

  // ============================================================
  // GCASH QR CODE SECTION
  // ============================================================

  Widget buildGcashQrSection() {
    const primaryBlue = Color(0xFF0D47A1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE1E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.qr_code_2,
                color: primaryBlue,
                size: 23,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  "GCash Payment QR Code",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF062B63),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Upload your store's GCash QR code so customers "
            "can scan it when reserving motorcycle parts.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 230,
              height: 230,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFE1E8F0),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: gcashQrUrl != null &&
                      gcashQrUrl!.isNotEmpty
                  ? Image.network(
                      gcashQrUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            "Unable to display QR code.",
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 70,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "No GCash QR uploaded",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        SizedBox(
  width: double.infinity,
  height: 48,
  child: ElevatedButton.icon(
    onPressed: !isEditing || isUploadingGcashQr
        ? null
        : pickGcashQr,
    style: ElevatedButton.styleFrom(
      backgroundColor:
          isEditing ? primaryBlue : Colors.grey,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.grey.shade400,
      disabledForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    icon: isUploadingGcashQr
        ? const SizedBox(
            width: 19,
            height: 19,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.upload_file),
    label: Text(
      isUploadingGcashQr
          ? "UPLOADING QR CODE..."
          : gcashQrUrl != null &&
                  gcashQrUrl!.isNotEmpty
              ? "CHANGE GCASH QR CODE"
              : "UPLOAD GCASH QR CODE",
    ),
  ),
), ],
      ),
    );
  }


  // ============================================================
  // BUILD
  // ============================================================

 

@override
Widget build(BuildContext context) {
  const primaryBlue = Color(0xFF0D47A1);
  const darkBlue = Color(0xFF062B63);
  const pageBackground = Color(0xFFF5F8FC);
  const containerColor = Color.fromARGB(255, 209, 209, 238);

  InputDecoration profileInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryBlue),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE1E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE1E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }

  Widget sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: primaryBlue, size: 23),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E8F0)),
      ),
      child: child,
    );
  }

  return PopScope(
    canPop: true,
    child: Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Store Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE1E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: darkBlue.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.store_outlined,
                          size: 29,
                          color: primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Store Profile",
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: darkBlue,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Manage your store details, account, and location.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isEditing)
                          const Icon(
                            Icons.edit_note,
                            color: primaryBlue,
                            size: 26,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFD6DDEC)),
                    const SizedBox(height: 20),

                    // STORE LOGO AND NAME
                    sectionCard(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: pickStoreLogo,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 52,
                                  backgroundColor: const Color(0xFFEAF1FC),
                                  backgroundImage:
                                      imageUrl != null &&
                                              imageUrl!.isNotEmpty
                                          ? NetworkImage(imageUrl!)
                                          : null,
                                  child: imageUrl == null ||
                                          imageUrl!.isEmpty
                                      ? const Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 36,
                                          color: primaryBlue,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            storeNameController.text.trim().isEmpty
                                ? "Store Profile"
                                : storeNameController.text.trim(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Tap the logo to upload or change your store image.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // STORE INFORMATION
                
                    // STORE INFORMATION
                    sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionTitle(
                            Icons.storefront_outlined,
                            "Store Information",
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: storeNameController,
                            readOnly: !isEditing,
                            decoration: profileInputDecoration(
                              label: "Store Name",
                              icon: Icons.store_outlined,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: ownerNameController,
                            readOnly: !isEditing,
                            decoration: profileInputDecoration(
                              label: "Owner Name",
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: addressController,
                            readOnly: !isEditing,
                            maxLines: 3,
                            decoration: profileInputDecoration(
                              label: "Store Address",
                              icon: Icons.location_on_outlined,
                              hint: "Enter your complete store address",
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: phoneController,
                            readOnly: !isEditing,
                            keyboardType: TextInputType.phone,
                            decoration: profileInputDecoration(
                              label: "Contact Number",
                              icon: Icons.phone_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // GCASH PAYMENT QR CODE
                    buildGcashQrSection(),

                    const SizedBox(height: 18),

                    // ACCOUNT INFORMATION
                    sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionTitle(
                            Icons.verified_user_outlined,
                            "Account Information",
                          ),
                          const SizedBox(height: 16),
                          _profileInfoCard(
                            icon: Icons.email_outlined,
                            label: "Email",
                            value: email ?? "N/A",
                          ),
                          const SizedBox(height: 10),
                          _profileInfoCard(
                            icon: Icons.badge_outlined,
                            label: "Permit Number",
                            value: permitNumber ?? "N/A",
                          ),
                          const SizedBox(height: 10),
                          _profileInfoCard(
                            icon: Icons.check_circle_outline,
                            label: "Account Status",
                            value: status ?? "N/A",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // SUBSCRIPTION INFORMATION
                    sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionTitle(
                            Icons.card_membership_outlined,
                            "Subscription Information",
                          ),
                          const SizedBox(height: 16),
                          _profileInfoCard(
                            icon: Icons.workspace_premium_outlined,
                            label: "Subscription Plan",
                            value: subscriptionPlan ?? "N/A",
                          ),
                          const SizedBox(height: 10),
                          _profileInfoCard(
                            icon: Icons.info_outline,
                            label: "Subscription Status",
                            value: subscriptionStatus ?? "N/A",
                          ),
                          const SizedBox(height: 10),
                          _profileInfoCard(
                            icon: Icons.calendar_today_outlined,
                            label: "Start Date",
                            value: subscriptionStart != null
                                ? DateFormat("MMMM dd, yyyy")
                                    .format(subscriptionStart!.toDate())
                                : "N/A",
                          ),
                          const SizedBox(height: 10),
                          _profileInfoCard(
                            icon: Icons.event_outlined,
                            label: "End Date",
                            value: subscriptionEnd != null
                                ? DateFormat("MMMM dd, yyyy")
                                    .format(subscriptionEnd!.toDate())
                                : "N/A",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // STORE LOCATION
                    sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionTitle(
                            Icons.location_on_outlined,
                            "Store Location",
                          ),
                          const SizedBox(height: 16),
                          if (storeId != null)
                            _profileInfoCard(
                              icon: Icons.tag,
                              label: "Store ID",
                              value: storeId!,
                            ),
                          if (storeId != null) const SizedBox(height: 10),
                          if (latitude != null && longitude != null) ...[
                            _profileInfoCard(
                              icon: Icons.map_outlined,
                              label: "Latitude",
                              value: latitude!.toStringAsFixed(8),
                            ),
                            const SizedBox(height: 10),
                            _profileInfoCard(
                              icon: Icons.explore_outlined,
                              label: "Longitude",
                              value: longitude!.toStringAsFixed(8),
                            ),
                          ] else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Store location has not been set.",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: isUpdatingLocation
                                  ? null
                                  : selectStoreLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: isUpdatingLocation
                                  ? const SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.map_outlined),
                              label: Text(
                                isUpdatingLocation
                                    ? "SAVING LOCATION..."
                                    : latitude != null && longitude != null
                                        ? "CHANGE STORE LOCATION"
                                        : "SELECT STORE LOCATION",
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Select the exact location of your store on the map.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // EDIT / SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (isEditing) {
                            saveChanges();
                          } else {
                            setState(() {
                              isEditing = true;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEditing ? primaryBlue : darkBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          isEditing
                              ? Icons.save_outlined
                              : Icons.edit_outlined,
                        ),
                        label: Text(
                          isEditing ? "SAVE CHANGES" : "EDIT PROFILE",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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
Widget _profileInfoCard({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 11,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(
        color: Colors.grey.shade200,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF0D47A1),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}