import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/auth_service.dart';
import '../../../services/cloudinary_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // =========================================================
  // MOTOFind COLORS
  // =========================================================

  static const Color motoBlue = Color(0xFF0D47A1);
  static const Color motoDarkBlue = Color(0xFF062B63);
  static const Color motoLightBlue = Color(0xFFEAF2FF);
  static const Color motoOrange = Color(0xFFFF8A00);
  static const Color backgroundColor = Color(0xFFF5F8FC);

  // =========================================================
  // SERVICES
  // =========================================================

  final ImagePicker picker = ImagePicker();
  final AuthService _authService = AuthService();

  // =========================================================
  // IMAGES
  // =========================================================

  XFile? permitImage;
  XFile? validIdImage;

  // =========================================================
  // TEXT CONTROLLERS
  // =========================================================

  final TextEditingController fullNameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController storeNameController =
      TextEditingController();

  final TextEditingController storeAddressController =
      TextEditingController();

  final TextEditingController permitController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  // =========================================================
  // VARIABLES
  // =========================================================

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String selectedRole = "Customer";

  bool isRegistering = false;

  // =========================================================
  // INPUT DECORATION
  // =========================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: motoBlue,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: motoBlue,
          width: 2,
        ),
      ),
      floatingLabelStyle: const TextStyle(
        color: motoBlue,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              error ? Colors.red.shade700 : motoBlue,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // =========================================================
  // PICK BUSINESS PERMIT
  // =========================================================

  Future<void> pickPermitImage() async {
    if (isRegistering) return;

    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          permitImage = image;
        });
      }
    } catch (e) {
      _showMessage(
        "Unable to select Business Permit.",
        error: true,
      );
    }
  }

  // =========================================================
  // PICK VALID ID
  // =========================================================

  Future<void> pickValidIdImage() async {
    if (isRegistering) return;

    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          validIdImage = image;
        });
      }
    } catch (e) {
      _showMessage(
        "Unable to select Valid ID.",
        error: true,
      );
    }
  }

  // =========================================================
  // IMAGE PREVIEW
  // =========================================================

  Widget _imagePreview(
    XFile image, {
    required String title,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              8,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: FutureBuilder<Uint8List>(
              future: image.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: motoBlue,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData) {
                  return Container(
                    height: 180,
                    alignment: Alignment.center,
                    child: const Text(
                      "Unable to preview image.",
                    ),
                  );
                }

                return Image.memory(
                  snapshot.data!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // UPLOAD CARD
  // =========================================================

  Widget _uploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required XFile? image,
    required VoidCallback onTap,
  }) {
    final bool hasImage = image != null;

    return Column(
      children: [
        InkWell(
          onTap: isRegistering ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasImage
                  ? Colors.green.withValues(alpha: 0.06)
                  : motoLightBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasImage
                    ? Colors.green.shade300
                    : motoBlue.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: hasImage
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    hasImage
                        ? Icons.check_circle_rounded
                        : icon,
                    color: hasImage
                        ? Colors.green.shade700
                        : motoBlue,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: motoDarkBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasImage
                            ? "Image selected. Tap to change."
                            : subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  hasImage
                      ? Icons.edit_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: hasImage
                      ? Colors.green.shade700
                      : motoBlue,
                ),
              ],
            ),
          ),
        ),
        if (image != null)
          _imagePreview(
            image,
            title: title,
            icon: icon,
          ),
      ],
    );
  }

  // =========================================================
  // ACCOUNT TYPE CARD
  // =========================================================

  Widget _roleCard({
    required String role,
    required String description,
    required IconData icon,
  }) {
    final bool isSelected = selectedRole == role;

    return Expanded(
      child: InkWell(
        onTap: isRegistering
            ? null
            : () {
                setState(() {
                  selectedRole = role;
                });
              },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? motoLightBlue
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? motoBlue
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? motoBlue
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                role,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? motoDarkBlue
                      : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.3,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 19,
                color: isSelected
                    ? motoBlue
                    : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // REGISTER ACCOUNT
  // =========================================================

  Future<void> registerAccount() async {
    if (isRegistering) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final String fullName =
        fullNameController.text.trim();

    final String email =
        emailController.text.trim();

    final String phone =
        phoneController.text.trim();

    final String password =
        passwordController.text;

    final String confirmPassword =
        confirmPasswordController.text;

    final String storeName =
        storeNameController.text.trim();

    final String storeAddress =
        storeAddressController.text.trim();

    final String permitNumber =
        permitController.text.trim();

    // =======================================================
    // BASIC VALIDATION
    // =======================================================

    if (fullName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage(
        "Please fill in all required fields.",
        error: true,
      );
      return;
    }

    // =======================================================
    // EMAIL VALIDATION
    // =======================================================

    final RegExp emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showMessage(
        "Please enter a valid email address.",
        error: true,
      );
      return;
    }

    // =======================================================
    // PASSWORD LENGTH
    // =======================================================

    if (password.length < 6) {
      _showMessage(
        "Password must be at least 6 characters.",
        error: true,
      );
      return;
    }

    // =======================================================
    // PASSWORD MATCH
    // =======================================================

    if (password != confirmPassword) {
      _showMessage(
        "Passwords do not match.",
        error: true,
      );
      return;
    }

    // =======================================================
    // STORE OWNER VALIDATION
    // =======================================================

    if (selectedRole == "Store Owner") {
      if (storeName.isEmpty ||
          storeAddress.isEmpty ||
          permitNumber.isEmpty) {
        _showMessage(
          "Please complete all store information.",
          error: true,
        );
        return;
      }

      if (permitImage == null) {
        _showMessage(
          "Please upload your Business Permit.",
          error: true,
        );
        return;
      }

      if (validIdImage == null) {
        _showMessage(
          "Please upload your Valid ID.",
          error: true,
        );
        return;
      }
    }

    // =======================================================
    // START REGISTERING
    // =======================================================

    setState(() {
      isRegistering = true;
    });

    try {
      String permitImageUrl = "";
      String validIdImageUrl = "";

      // =====================================================
      // STORE OWNER IMAGE UPLOAD
      // =====================================================

      if (selectedRole == "Store Owner") {
        _showMessage(
          "Uploading Business Permit...",
        );

        permitImageUrl =
            await CloudinaryService.uploadImage(
                  permitImage!,
                ) ??
                "";

        if (permitImageUrl.isEmpty) {
          throw Exception(
            "Business Permit upload failed.",
          );
        }

        if (!mounted) return;

        _showMessage(
          "Uploading Valid ID...",
        );

        validIdImageUrl =
            await CloudinaryService.uploadImage(
                  validIdImage!,
                ) ??
                "";

        if (validIdImageUrl.isEmpty) {
          throw Exception(
            "Valid ID upload failed.",
          );
        }
      }

      // =====================================================
      // DEBUG
      // =====================================================

      debugPrint(
        "=================================",
      );

      debugPrint(
        "STARTING REGISTRATION",
      );

      debugPrint(
        "EMAIL: $email",
      );

      debugPrint(
        "ROLE: $selectedRole",
      );

      debugPrint(
        "=================================",
      );

      // =====================================================
      // FIREBASE REGISTER
      // =====================================================

      await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: selectedRole,
        storeName:
            selectedRole == "Store Owner"
                ? storeName
                : "",
        storeAddress:
            selectedRole == "Store Owner"
                ? storeAddress
                : "",
        permitNumber:
            selectedRole == "Store Owner"
                ? permitNumber
                : "",
        permitImageUrl: permitImageUrl,
        validIdImageUrl: validIdImageUrl,
      );

      // =====================================================
      // SUCCESS
      // =====================================================

      debugPrint(
        "=================================",
      );

      debugPrint(
        "REGISTRATION SUCCESSFUL",
      );

      debugPrint(
        "=================================",
      );

      if (!mounted) return;

      setState(() {
        isRegistering = false;
      });

      _showMessage(
        "Registration Successful!",
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        "=================================",
      );

      debugPrint(
        "REGISTRATION ERROR",
      );

      debugPrint(
        e.toString(),
      );

      debugPrint(
        "=================================",
      );

      if (!mounted) return;

      setState(() {
        isRegistering = false;
      });

      String errorMessage = e.toString();

      if (errorMessage.startsWith(
        "Exception: ",
      )) {
        errorMessage =
            errorMessage.substring(11);
      }

      _showMessage(
        "Registration failed:\n$errorMessage",
        error: true,
      );
    }
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    storeNameController.dispose();
    storeAddressController.dispose();
    permitController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    // =======================================================
    // DETECT ANDROID KEYBOARD
    // =======================================================

    final bool keyboardIsOpen =
        MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: backgroundColor,

      // IMPORTANT:
      // Allow Flutter to resize the screen when
      // Android keyboard opens.
      resizeToAvoidBottomInset: true,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: motoDarkBlue,
          ),
          onPressed: isRegistering
              ? null
              : () {
                  FocusManager
                      .instance
                      .primaryFocus
                      ?.unfocus();

                  Navigator.pop(context);
                },
        ),

        title: const Text(
          "Create Account",
          style: TextStyle(
            color: motoDarkBlue,
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: true,
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        child: ListView(
          // IMPORTANT:
          // Manual means scrolling does not dismiss
          // the keyboard automatically.
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.manual,

          padding: EdgeInsets.fromLTRB(
            20,
            keyboardIsOpen ? 4 : 8,
            20,
            40,
          ),

          children: [
            // =================================================
            // BRANDING
            //
            // IMPORTANT:
            // Offstage hides the logo visually and removes
            // its layout space, BUT keeps the widget alive.
            //
            // This prevents TextField focus from being lost.
            // =================================================

            Offstage(
              offstage: keyboardIsOpen,

              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: motoBlue.withValues(
                              alpha: 0.12,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding:
                          const EdgeInsets.all(8),

                      child: ClipOval(
                        child: Image.asset(
                          "assets/motofind.png",

                          width: double.infinity,
                          height: double.infinity,

                          fit: BoxFit.cover,

                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons
                                  .two_wheeler_rounded,
                              size: 48,
                              color: motoBlue,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Moto",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight:
                                FontWeight.w800,
                            color: motoDarkBlue,
                          ),
                        ),

                        Text(
                          "Find",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight:
                                FontWeight.w800,
                            color: motoOrange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Find motorcycle parts near you",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // =================================================
            // MAIN CARD
            // =================================================

            Container(
              width: double.infinity,

              // Slightly smaller padding while
              // keyboard is open.
              padding: EdgeInsets.all(
                keyboardIsOpen ? 16 : 20,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 25,
                    offset:
                        const Offset(0, 10),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  // =========================================
                  // HEADER
                  // =========================================

                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: motoLightBlue,
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .person_add_alt_1_rounded,
                          color: motoBlue,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              "Join MotoFind",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.w800,
                                color:
                                    motoDarkBlue,
                              ),
                            ),

                            SizedBox(height: 2),

                            Text(
                              "Create your account to get started.",
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // =========================================
                  // PERSONAL INFORMATION
                  // =========================================

                  const Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: motoDarkBlue,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        fullNameController,
                    enabled: !isRegistering,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        _inputDecoration(
                      label: "Full Name",
                      icon:
                          Icons.person_outline_rounded,
                      hint:
                          "Enter your full name",
                    ),
                  ),

                  const SizedBox(height: 13),

                  TextField(
                    controller:
                        emailController,
                    enabled: !isRegistering,
                    keyboardType:
                        TextInputType.emailAddress,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        _inputDecoration(
                      label: "Email",
                      icon:
                          Icons.email_outlined,
                      hint:
                          "example@email.com",
                    ),
                  ),

                  const SizedBox(height: 13),

                  TextField(
                    controller:
                        phoneController,
                    enabled: !isRegistering,
                    keyboardType:
                        TextInputType.phone,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        _inputDecoration(
                      label: "Phone Number",
                      icon:
                          Icons.phone_outlined,
                      hint:
                          "09XXXXXXXXX",
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =========================================
                  // ACCOUNT TYPE
                  // =========================================

                  const Text(
                    "Choose Account Type",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: motoDarkBlue,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Select how you want to use MotoFind.",
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _roleCard(
                        role: "Customer",
                        description:
                            "Find and reserve motorcycle parts",
                        icon:
                            Icons.person_rounded,
                      ),

                      const SizedBox(width: 12),

                      _roleCard(
                        role: "Store Owner",
                        description:
                            "Manage your motorcycle parts store",
                        icon:
                            Icons.storefront_rounded,
                      ),
                    ],
                  ),

                  // =========================================
                  // STORE OWNER SECTION
                  // =========================================

                  if (selectedRole ==
                      "Store Owner") ...[
                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(16),
                      decoration:
                          BoxDecoration(
                        color: motoLightBlue,
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        border: Border.all(
                          color:
                              motoBlue.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                ),
                                child: const Icon(
                                  Icons
                                      .storefront_rounded,
                                  color: motoBlue,
                                ),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      "Store Information",
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                        color:
                                            motoDarkBlue,
                                      ),
                                    ),

                                    SizedBox(height: 2),

                                    Text(
                                      "Provide your store details for verification.",
                                      style:
                                          TextStyle(
                                        fontSize: 11,
                                        color:
                                            Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          TextField(
                            controller:
                                storeNameController,
                            enabled:
                                !isRegistering,
                            textInputAction:
                                TextInputAction.next,
                            decoration:
                                _inputDecoration(
                              label:
                                  "Store Name",
                              icon: Icons
                                  .storefront_outlined,
                              hint:
                                  "Enter store name",
                            ),
                          ),

                          const SizedBox(
                            height: 13,
                          ),

                          TextField(
                            controller:
                                storeAddressController,
                            enabled:
                                !isRegistering,
                            textInputAction:
                                TextInputAction.next,
                            keyboardType:
                                TextInputType
                                    .streetAddress,
                            maxLines: 2,
                            decoration:
                                _inputDecoration(
                              label:
                                  "Store Address",
                              icon: Icons
                                  .location_on_outlined,
                              hint:
                                  "Enter complete store address",
                            ),
                          ),

                          const SizedBox(
                            height: 13,
                          ),

                          TextField(
                            controller:
                                permitController,
                            enabled:
                                !isRegistering,
                            textInputAction:
                                TextInputAction.next,
                            decoration:
                                _inputDecoration(
                              label:
                                  "Business Permit Number",
                              icon: Icons
                                  .badge_outlined,
                              hint:
                                  "Enter permit number",
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          const Text(
                            "Verification Documents",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w800,
                              color: motoDarkBlue,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            "Upload the required documents for store verification.",
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  Colors.grey
                                      .shade600,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          _uploadCard(
                            title:
                                "Business Permit",
                            subtitle:
                                "Upload a clear photo of your business permit",
                            icon: Icons
                                .description_outlined,
                            image: permitImage,
                            onTap:
                                pickPermitImage,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          _uploadCard(
                            title: "Valid ID",
                            subtitle:
                                "Upload a clear photo of your valid ID",
                            icon: Icons
                                .badge_outlined,
                            image: validIdImage,
                            onTap:
                                pickValidIdImage,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // =========================================
                  // SECURITY
                  // =========================================

                  const Text(
                    "Security",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: motoDarkBlue,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        passwordController,
                    enabled: !isRegistering,
                    obscureText:
                        obscurePassword,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        _inputDecoration(
                      label: "Password",
                      icon:
                          Icons.lock_outline_rounded,
                      hint:
                          "At least 6 characters",
                      suffixIcon:
                          IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons
                                  .visibility_outlined
                              : Icons
                                  .visibility_off_outlined,
                          color: motoBlue,
                        ),
                        onPressed:
                            isRegistering
                                ? null
                                : () {
                                    setState(() {
                                      obscurePassword =
                                          !obscurePassword;
                                    });
                                  },
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  TextField(
                    controller:
                        confirmPasswordController,
                    enabled: !isRegistering,
                    obscureText:
                        obscureConfirmPassword,
                    textInputAction:
                        TextInputAction.done,
                    onSubmitted: (_) {
                      if (!isRegistering) {
                        registerAccount();
                      }
                    },
                    decoration:
                        _inputDecoration(
                      label:
                          "Confirm Password",
                      icon:
                          Icons.lock_reset_outlined,
                      hint:
                          "Re-enter your password",
                      suffixIcon:
                          IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons
                                  .visibility_outlined
                              : Icons
                                  .visibility_off_outlined,
                          color: motoBlue,
                        ),
                        onPressed:
                            isRegistering
                                ? null
                                : () {
                                    setState(() {
                                      obscureConfirmPassword =
                                          !obscureConfirmPassword;
                                    });
                                  },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =========================================
                  // REGISTER BUTTON
                  // =========================================

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient:
                            const LinearGradient(
                          colors: [
                            motoBlue,
                            motoDarkBlue,
                          ],
                          begin:
                              Alignment.centerLeft,
                          end:
                              Alignment.centerRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                motoBlue.withValues(
                              alpha: 0.20,
                            ),
                            blurRadius: 12,
                            offset:
                                const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed:
                            isRegistering
                                ? null
                                : registerAccount,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent,
                          disabledBackgroundColor:
                              Colors.transparent,
                          shadowColor:
                              Colors.transparent,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        child: isRegistering
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    Icons
                                        .person_add_alt_1_rounded,
                                    color:
                                        Colors.white,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    "CREATE ACCOUNT",
                                    style:
                                        TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                      color:
                                          Colors.white,
                                      letterSpacing:
                                          0.4,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // LOGIN LINK
            // =================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account?",
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                TextButton(
                  onPressed: isRegistering
                      ? null
                      : () {
                          FocusManager
                              .instance
                              .primaryFocus
                              ?.unfocus();

                          Navigator.pop(context);
                        },
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: motoBlue,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              "Find parts. Find stores. Ride with confidence.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color:
                    Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}