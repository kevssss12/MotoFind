import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/cloudinary_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({
    super.key,
  });

  @override
  State<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState
    extends State<CustomerProfileScreen> {
  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final ImagePicker imagePicker =
      ImagePicker();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  // ============================================================
  // PROFILE DATA
  // ============================================================

  String profileImageUrl = "";

  // Temporary image selected by the user.
  XFile? selectedImage;

  bool loading = true;
  bool saving = false;
  bool uploadingImage = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadProfile();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> loadProfile() async {
    try {
      final User? user =
          auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }

        return;
      }

      final DocumentSnapshot<
              Map<String, dynamic>>
          doc = await firestore
              .collection("users")
              .doc(user.uid)
              .get();

      final Map<String, dynamic> data =
          doc.data() ?? {};

      if (!mounted) return;

      setState(() {
        nameController.text =
            data["fullName"]
                    ?.toString()
                    .trim() ??
                "Customer";

        emailController.text =
            data["email"]
                    ?.toString()
                    .trim() ??
                user.email ??
                "";

        phoneController.text =
            data["phone"]
                    ?.toString()
                    .trim() ??
                "";

        profileImageUrl =
            data["profileImageUrl"]
                    ?.toString()
                    .trim() ??
                "";

        selectedImage = null;

        loading = false;
      });
    } catch (e) {
      debugPrint(
        "LOAD CUSTOMER PROFILE ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load profile:\n$e",
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // PICK PROFILE IMAGE
  // ============================================================

  Future<void> pickProfileImage() async {
    try {
      final XFile? image =
          await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (image == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        selectedImage = image;
      });
    } catch (e) {
      debugPrint(
        "PICK PROFILE IMAGE ERROR: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Failed to select image:\n$e",
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> saveProfile() async {
    final User? user =
        auth.currentUser;

    if (user == null) {
      return;
    }

    final String name =
        nameController.text.trim();

    final String email =
        emailController.text.trim();

    final String phone =
        phoneController.text.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Full Name is required.",
          ),
          backgroundColor:
              Colors.red,
        ),
      );

      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Email is required.",
          ),
          backgroundColor:
              Colors.red,
        ),
      );

      return;
    }

    try {
      if (!mounted) return;

      setState(() {
        saving = true;
      });

      String finalImageUrl =
          profileImageUrl;

      // ========================================================
      // UPLOAD IMAGE ONLY IF USER SELECTED A NEW IMAGE
      // ========================================================

      if (selectedImage != null) {
        if (!mounted) return;

        setState(() {
          uploadingImage = true;
        });

        final String? uploadedUrl =
            await CloudinaryService
                .uploadImage(
          selectedImage!,
        );

        if (uploadedUrl == null ||
            uploadedUrl.trim().isEmpty) {
          throw Exception(
            "Failed to upload profile image.",
          );
        }

        finalImageUrl =
            uploadedUrl.trim();

        if (!mounted) return;

        setState(() {
          uploadingImage = false;
        });
      }

      // ========================================================
      // SAVE PROFILE DATA
      // ========================================================
      //
      // IMPORTANT:
      // If there is NO new image, the existing image URL is used.
      // Therefore the old image will NOT be removed.
      //
      // ========================================================

      await firestore
          .collection("users")
          .doc(user.uid)
          .update({
        "fullName": name,
        "email": email,
        "phone": phone,
        "profileImageUrl":
            finalImageUrl,
      });

      // ========================================================
      // UPDATE LOCAL DATA
      // ========================================================

      if (!mounted) return;

      setState(() {
        profileImageUrl =
            finalImageUrl;

        selectedImage = null;

        saving = false;
        uploadingImage = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Profile updated successfully!",
          ),
          backgroundColor:
              Colors.green,
        ),
      );
    } catch (e) {
      debugPrint(
        "SAVE CUSTOMER PROFILE ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        saving = false;
        uploadingImage = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Failed to save profile:\n$e",
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget buildProfileImage() {
    // ==========================================================
    // SHOW NEWLY SELECTED IMAGE
    // ==========================================================

    if (selectedImage != null) {
      return CircleAvatar(
        radius: 70,
        backgroundColor:
            Colors.grey.shade200,
        backgroundImage:
            NetworkImage(
          profileImageUrl,
        ),
        child: ClipOval(
          child: Image.network(
            profileImageUrl,
            width: 140,
            height: 140,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return const Icon(
                Icons.person,
                size: 75,
                color: Colors.grey,
              );
            },
          ),
        ),
      );
    }

    // ==========================================================
    // SHOW EXISTING NETWORK IMAGE
    // ==========================================================

    if (profileImageUrl
        .trim()
        .isNotEmpty) {
      return CircleAvatar(
        radius: 70,
        backgroundColor:
            Colors.grey.shade200,
        backgroundImage:
            NetworkImage(
          profileImageUrl,
        ),
      );
    }

    // ==========================================================
    // DEFAULT PROFILE ICON
    // ==========================================================

    return CircleAvatar(
      radius: 70,
      backgroundColor:
          Colors.grey.shade200,
      child: Icon(
        Icons.person,
        size: 75,
        color:
            Colors.grey.shade600,
      ),
    );
  }

  // ============================================================
  // INFORMATION FIELD
  // ============================================================

  Widget informationField({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextField(
        controller: controller,
        keyboardType:
            keyboardType,
        enabled: !saving,
        decoration:
            InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
          labelText: title,
          filled: true,
          fillColor:
              Colors.grey.shade50,
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            borderSide:
                BorderSide(
              color:
                  Colors.grey.shade300,
            ),
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            borderSide:
                BorderSide(
              color:
                  Colors.grey.shade300,
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            borderSide:
                BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .primary,
              width: 2,
            ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh:
                  loadProfile,
              child:
                  SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child: Column(
                  children: [
                    // ==========================================
                    // PROFILE IMAGE
                    // ==========================================

                    Stack(
                      alignment:
                          Alignment.bottomRight,
                      children: [
                        buildProfileImage(),

                        GestureDetector(
                          onTap: saving
                              ? null
                              : pickProfileImage,
                          child:
                              Container(
                            width: 44,
                            height: 44,
                            decoration:
                                BoxDecoration(
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .primary,
                              shape:
                                  BoxShape
                                      .circle,
                              border:
                                  Border.all(
                                color:
                                    Colors.white,
                                width: 3,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .camera_alt,
                              color:
                                  Colors.white,
                              size: 21,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==========================================
                    // IMAGE BUTTON
                    // ==========================================

                    TextButton.icon(
                      onPressed:
                          saving
                              ? null
                              : pickProfileImage,
                      icon:
                          const Icon(
                        Icons
                            .photo_camera,
                      ),
                      label:
                          Text(
                        selectedImage !=
                                null
                            ? "New Image Selected"
                            : profileImageUrl
                                    .trim()
                                    .isEmpty
                                ? "Add Profile Image"
                                : "Change Profile Image",
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    // ==========================================
                    // FULL NAME
                    // ==========================================

                    informationField(
                      icon:
                          Icons
                              .person_outline,
                      title:
                          "Full Name",
                      controller:
                          nameController,
                    ),

                    // ==========================================
                    // EMAIL
                    // ==========================================

                    informationField(
                      icon:
                          Icons
                              .email_outlined,
                      title:
                          "Email",
                      controller:
                          emailController,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                    ),

                    // ==========================================
                    // PHONE
                    // ==========================================

                    informationField(
                      icon:
                          Icons
                              .phone_outlined,
                      title:
                          "Phone Number",
                      controller:
                          phoneController,
                      keyboardType:
                          TextInputType
                              .phone,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==========================================
                    // SAVE BUTTON
                    // ==========================================

                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child:
                          ElevatedButton(
                        onPressed:
                            saving
                                ? null
                                : saveProfile,
                        style:
                            ElevatedButton
                                .styleFrom(
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                        child: saving
                            ? const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 12,
                                  ),
                                  Text(
                                    "Saving...",
                                    style:
                                        TextStyle(
                                      fontSize:
                                          16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                "SAVE CHANGES",
                                style:
                                    TextStyle(
                                  fontSize:
                                      16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    // ==========================================
                    // IMAGE INFO
                    // ==========================================

                    if (selectedImage != null)
                      const Text(
                        "A new image will be uploaded when you save.",
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color:
                              Colors.grey,
                          fontSize: 13,
                        ),
                      )
                    else
                      const Text(
                        "You can save your profile even without changing your image.",
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color:
                              Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}