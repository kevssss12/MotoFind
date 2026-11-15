import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_screen.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../customer/customer_home.dart';
import '../store_owner/store_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../store_owner/subscription_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  // ============================================================
  // SERVICES
  // ============================================================

  final AuthService _authService = AuthService();

  final FirestoreService _firestoreService =
      FirestoreService();

  // ============================================================
  // STATE
  // ============================================================

  bool obscurePassword = true;
  bool isLoggingIn = false;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color motoBlue = Color(0xFF0D47A1);
  static const Color motoDarkBlue = Color(0xFF062B63);
  static const Color motoLightBlue = Color(0xFFEAF2FF);
  static const Color motoOrange = Color(0xFFFF8A00);
  static const Color backgroundColor = Color(0xFFF5F8FC);

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
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
      fillColor: const Color(0xFFF7F9FC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: motoBlue,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> _showForgotPasswordDialog() async {
    FocusManager.instance.primaryFocus?.unfocus();

    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) {
      return;
    }

    final String? sentEmail =
        await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ForgotPasswordDialog(
          initialEmail: emailController.text.trim(),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (sentEmail == null ||
        sentEmail.trim().isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (successContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            8,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            10,
            24,
            10,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Email Sent",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: motoDarkBlue,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "A password reset link has been sent to:\n\n"
            "$sentEmail\n\n"
            "Please check your Gmail inbox and spam folder.",
            style: const TextStyle(
              height: 1.5,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  successContext,
                ).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: motoBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "OK",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        "Please enter email and password.",
        isError: true,
      );

      return;
    }

    // ----------------------------------------------------------
    // HIDE KEYBOARD
    // ----------------------------------------------------------

    FocusManager.instance.primaryFocus?.unfocus();

    if (!mounted) {
      return;
    }

    setState(() {
      isLoggingIn = true;
    });

    try {
      // ========================================================
      // FIREBASE LOGIN
      // ========================================================

      await _authService.login(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      final user = _authService.currentUser;

      if (user == null) {
        _showMessage(
          "Unable to get current user.",
          isError: true,
        );

        return;
      }

      debugPrint(
        "LOGIN UID: ${user.uid}",
      );

      // ========================================================
      // GET ROLE
      // ========================================================

      final role =
          await _firestoreService.getUserRole(
        user.uid,
      );

      debugPrint(
        "USER ROLE: $role",
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // CUSTOMER
      // ========================================================

      if (role == "Customer") {
        final userDoc =
            await FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .get();

        if (!mounted) {
          return;
        }

        if (!userDoc.exists) {
          _showMessage(
            "Customer account not found.",
            isError: true,
          );

          await _authService.logout();

          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const CustomerHome(),
          ),
        );

        return;
      }

      // ========================================================
      // STORE OWNER
      // ========================================================

      if (role == "Store Owner") {
        // ------------------------------------------------------
        // APPROVAL STATUS
        // ------------------------------------------------------

        final approvalStatus =
            await _firestoreService
                .getStoreApprovalStatus(
          user.uid,
        );

        debugPrint(
          "STORE APPROVAL STATUS: $approvalStatus",
        );

        if (!mounted) {
          return;
        }

        // ------------------------------------------------------
        // PENDING
        // ------------------------------------------------------

        if (approvalStatus == "Pending") {
          _showMessage(
            "Your store application is still pending.",
          );

          await _authService.logout();

          return;
        }

        // ------------------------------------------------------
        // REJECTED
        // ------------------------------------------------------

        if (approvalStatus == "Rejected") {
          _showMessage(
            "Your store application was rejected.",
            isError: true,
          );

          await _authService.logout();

          return;
        }

        // ------------------------------------------------------
        // GET USER DATA
        // ------------------------------------------------------

        final userDoc =
            await FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .get();

        if (!mounted) {
          return;
        }

        if (!userDoc.exists) {
          _showMessage(
            "Store owner account information was not found.",
            isError: true,
          );

          await _authService.logout();

          return;
        }

        final data = userDoc.data()!;

        // ======================================================
        // OLD SUBSCRIPTION END
        // ======================================================

        if (data["subscriptionEnd"] != null) {
          try {
            final subscriptionEnd =
                (data["subscriptionEnd"] as Timestamp)
                    .toDate();

            if (DateTime.now()
                .isAfter(subscriptionEnd)) {
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .update({
                "subscriptionStatus":
                    "Expired",
                "hasSubscribed": false,
              });
            }
          } catch (e) {
            debugPrint(
              "subscriptionEnd error: $e",
            );
          }
        }

        // ======================================================
        // NEW SUBSCRIPTION END DATE
        // ======================================================

        if (data["subscriptionEndDate"] != null) {
          try {
            final subscriptionEndDate =
                (data["subscriptionEndDate"]
                        as Timestamp)
                    .toDate();

            if (!DateTime.now()
                .isBefore(subscriptionEndDate)) {
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .update({
                "subscriptionStatus":
                    "Expired",
                "hasSubscribed": false,
              });
            }
          } catch (e) {
            debugPrint(
              "subscriptionEndDate error: $e",
            );
          }
        }

        // ======================================================
        // GET SUBSCRIPTION STATUS
        // ======================================================

        final subscriptionStatus =
            await _firestoreService
                .getSubscriptionStatus(
          user.uid,
        );

        debugPrint(
          "SUBSCRIPTION STATUS: $subscriptionStatus",
        );

        if (!mounted) {
          return;
        }

        // ======================================================
        // EXPIRED
        // ======================================================

        if (subscriptionStatus == "Expired") {
          final latestUserDoc =
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .get();

          if (!mounted) {
            return;
          }

          if (!latestUserDoc.exists) {
            _showMessage(
              "User information not found.",
              isError: true,
            );

            return;
          }

          final latestData =
              latestUserDoc.data()!;

          // ----------------------------------------------------
          // RENEWAL PENDING
          // ----------------------------------------------------

          if (latestData["renewalStatus"] ==
              "Pending") {
            _showMessage(
              "Your renewal request is still pending.\n"
              "Please wait for the Admin's approval.",
            );

            return;
          }

          // ----------------------------------------------------
          // RENEW
          // ----------------------------------------------------

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const SubscriptionScreen(
                isRenewal: true,
              ),
            ),
          );

          return;
        }

        // ======================================================
        // NO SUBSCRIPTION
        // ======================================================

        if (subscriptionStatus == null) {
          final latestUserDoc =
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .get();

          if (!mounted) {
            return;
          }

          if (!latestUserDoc.exists) {
            _showMessage(
              "User information not found.",
              isError: true,
            );

            return;
          }

          final latestData =
              latestUserDoc.data()!;

          // ----------------------------------------------------
          // PAYMENT ALREADY SUBMITTED
          // ----------------------------------------------------

          if (latestData["hasSubscribed"] == true) {
            _showMessage(
              "Your subscription payment is still pending.\n"
              "Please wait for the Admin's approval.",
            );

            await _authService.logout();

            return;
          }

          // ----------------------------------------------------
          // NEW SUBSCRIPTION
          // ----------------------------------------------------

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const SubscriptionScreen(
                isRenewal: false,
              ),
            ),
          );

          return;
        }

        // ======================================================
        // PENDING
        // ======================================================

        if (subscriptionStatus == "Pending") {
          _showMessage(
            "Your subscription is still waiting for admin approval.",
          );

          await _authService.logout();

          return;
        }

        // ======================================================
        // REJECTED
        // ======================================================

        if (subscriptionStatus == "Rejected") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const SubscriptionScreen(),
            ),
          );

          return;
        }

        // ======================================================
        // APPROVED / ACTIVE
        // ======================================================

        if (subscriptionStatus == "Approved" ||
            subscriptionStatus == "Active") {
          final latestUserDoc =
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user.uid)
                  .get();

          if (!mounted) {
            return;
          }

          if (!latestUserDoc.exists) {
            _showMessage(
              "User information not found.",
              isError: true,
            );

            return;
          }

          final latestData =
              latestUserDoc.data()!;

          final status =
              latestData["status"];

          // ----------------------------------------------------
          // DISABLED
          // ----------------------------------------------------

          if (status == "Disabled") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const SubscriptionScreen(),
              ),
            );

            return;
          }

          // ----------------------------------------------------
          // STORE DASHBOARD
          // ----------------------------------------------------

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const StoreDashboard(),
            ),
          );

          return;
        }

        // ======================================================
        // UNKNOWN SUBSCRIPTION
        // ======================================================

        _showMessage(
          "Unable to verify your subscription status.",
          isError: true,
        );

        await _authService.logout();

        return;
      }

      // ========================================================
      // ADMIN
      // ========================================================

      if (role == "Admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AdminDashboard(),
          ),
        );

        return;
      }

      // ========================================================
      // INVALID ROLE
      // ========================================================

      _showMessage(
        "Invalid user role.",
        isError: true,
      );

      await _authService.logout();
    } catch (e) {
      debugPrint(
        "LOGIN ERROR: $e",
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _getLoginErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoggingIn = false;
        });
      }
    }
  }

  // ============================================================
  // LOGIN ERROR MESSAGE
  // ============================================================

  String _getLoginErrorMessage(
    Object error,
  ) {
    final text =
        error.toString().toLowerCase();

    if (text.contains("user-not-found")) {
      return "Incorrect email or password.";
    }

    if (text.contains("wrong-password")) {
      return "Incorrect email or password.";
    }

    if (text.contains("invalid-credential")) {
      return "Incorrect email or password.";
    }

    if (text.contains("invalid-email")) {
      return "Please enter a valid email address.";
    }

    if (text.contains("too-many-requests")) {
      return "Too many login attempts. Please try again later.";
    }

    if (text.contains(
      "network-request-failed",
    )) {
      return "Network error. Please check your internet connection.";
    }

    return "Login failed. Please try again.";
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : motoBlue,
          behavior:
              SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Detect Android keyboard.
    final bool keyboardOpen =
        MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: backgroundColor,

      // Keep Scaffold resizing when keyboard opens.
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: AnimatedPadding(
          duration:
              const Duration(milliseconds: 220),

          curve: Curves.easeOut,

          padding: EdgeInsets.only(
            top: keyboardOpen ? 4 : 20,
          ),

          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.manual,

            padding: EdgeInsets.fromLTRB(
              20,
              keyboardOpen ? 4 : 0,
              20,
              keyboardOpen ? 24 : 40,
            ),

            child: Column(
              children: [
                // ==================================================
                // LOGO + BRANDING
                //
                // Hidden while keyboard is open.
                // ==================================================

                AnimatedSize(
                  duration:
                      const Duration(milliseconds: 220),

                  curve: Curves.easeOut,

                  child: keyboardOpen
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            const SizedBox(
                              height: 10,
                            ),

                            // LOGO
                            Container(
                              width: 105,
                              height: 105,

                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,

                                shape:
                                    BoxShape.circle,

                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        motoBlue.withValues(
                                      alpha: 0.14,
                                    ),

                                    blurRadius:
                                        22,

                                    offset:
                                        const Offset(
                                      0,
                                      8,
                                    ),
                                  ),
                                ],
                              ),

                              padding:
                                  const EdgeInsets.all(
                                8,
                              ),

                              child: ClipOval(
                                child:
                                    Container(
                                  color:
                                      Colors.white,

                                  child:
                                      Image.asset(
                                    'assets/motofind.png',

                                    width:
                                        double.infinity,

                                    height:
                                        double.infinity,

                                    fit:
                                        BoxFit.contain,

                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return const Icon(
                                        Icons
                                            .two_wheeler_rounded,
                                        color:
                                            motoBlue,
                                        size: 55,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            // APP NAME
                            const Text(
                              "MotoFind",

                              style:
                                  TextStyle(
                                fontSize: 32,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                letterSpacing:
                                    -0.5,
                                color:
                                    motoDarkBlue,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Container(
                              width: 45,
                              height: 4,

                              decoration:
                                  BoxDecoration(
                                color:
                                    motoOrange,

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            const Text(
                              "Find motorcycle parts near you",

                              textAlign:
                                  TextAlign.center,

                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(
                              height: 24,
                            ),
                          ],
                        ),
                ),

                // ==================================================
                // LOGIN CARD
                // ==================================================

                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(22),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),

                    border: Border.all(
                      color:
                          Colors.grey.shade100,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(
                          alpha: 0.07,
                        ),

                        blurRadius: 25,

                        offset:
                            const Offset(
                          0,
                          10,
                        ),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,

                    children: [
                      // ==========================================
                      // HEADER
                      // ==========================================

                      Row(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets
                                    .all(
                              10,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  motoLightBlue,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),

                            child:
                                const Icon(
                              Icons
                                  .login_rounded,
                              color:
                                  motoBlue,
                              size: 24,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                Text(
                                  "Welcome Back",

                                  style:
                                      TextStyle(
                                    fontSize:
                                        20,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        motoDarkBlue,
                                  ),
                                ),

                                SizedBox(
                                  height: 3,
                                ),

                                Text(
                                  "Login to your MotoFind account",

                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .grey,
                                    fontSize:
                                        12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // ==========================================
                      // EMAIL
                      // ==========================================

                      TextField(
                        controller:
                            emailController,

                        keyboardType:
                            TextInputType
                                .emailAddress,

                        textInputAction:
                            TextInputAction.next,

                        enabled:
                            !isLoggingIn,

                        // Extra space above the keyboard.
                        scrollPadding:
                            const EdgeInsets.only(
                          top: 40,
                          bottom: 140,
                        ),

                        decoration:
                            _inputDecoration(
                          label: "Email",
                          hint:
                              "Enter your email",
                          icon:
                              Icons.email_outlined,
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==========================================
                      // PASSWORD
                      // ==========================================

                      TextField(
                        controller:
                            passwordController,

                        obscureText:
                            obscurePassword,

                        textInputAction:
                            TextInputAction.done,

                        enabled:
                            !isLoggingIn,

                        // Extra space above the keyboard.
                        scrollPadding:
                            const EdgeInsets.only(
                          top: 40,
                          bottom: 140,
                        ),

                        onSubmitted: (_) {
                          if (!isLoggingIn) {
                            _login();
                          }
                        },

                        decoration:
                            _inputDecoration(
                          label: "Password",
                          hint:
                              "Enter your password",
                          icon:
                              Icons
                                  .lock_outline_rounded,

                          suffixIcon:
                              IconButton(
                            tooltip:
                                obscurePassword
                                    ? "Show password"
                                    : "Hide password",

                            icon: Icon(
                              obscurePassword
                                  ? Icons
                                      .visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,

                              color:
                                  Colors.grey,
                            ),

                            onPressed:
                                isLoggingIn
                                    ? null
                                    : () {
                                        setState(
                                          () {
                                            obscurePassword =
                                                !obscurePassword;
                                          },
                                        );
                                      },
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ==========================================
                      // FORGOT PASSWORD
                      // ==========================================

                      Align(
                        alignment:
                            Alignment.centerRight,

                        child: TextButton(
                          onPressed:
                              isLoggingIn
                                  ? null
                                  : _showForgotPasswordDialog,

                          style:
                              TextButton.styleFrom(
                            foregroundColor:
                                motoBlue,

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                          ),

                          child:
                              const Text(
                            "Forgot Password?",

                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ==========================================
                      // LOGIN BUTTON
                      // ==========================================

                      SizedBox(
                        height: 56,

                        child: DecoratedBox(
                          decoration:
                              BoxDecoration(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),

                            gradient:
                                const LinearGradient(
                              colors: [
                                motoBlue,
                                motoDarkBlue,
                              ],

                              begin:
                                  Alignment
                                      .centerLeft,

                              end:
                                  Alignment
                                      .centerRight,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color:
                                    motoBlue
                                        .withValues(
                                  alpha: 0.25,
                                ),

                                blurRadius:
                                    12,

                                offset:
                                    const Offset(
                                  0,
                                  5,
                                ),
                              ),
                            ],
                          ),

                          child:
                              ElevatedButton(
                            onPressed:
                                isLoggingIn
                                    ? null
                                    : _login,

                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  Colors
                                      .transparent,

                              disabledBackgroundColor:
                                  Colors
                                      .transparent,

                              shadowColor:
                                  Colors
                                      .transparent,

                              foregroundColor:
                                  Colors.white,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                              ),
                            ),

                            child:
                                AnimatedSwitcher(
                              duration:
                                  const Duration(
                                milliseconds:
                                    200,
                              ),

                              child:
                                  isLoggingIn
                                      ? const Row(
                                          key: ValueKey(
                                            "loading",
                                          ),

                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,

                                          children: [
                                            SizedBox(
                                              width:
                                                  21,
                                              height:
                                                  21,

                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2.5,

                                                color:
                                                    Colors.white,
                                              ),
                                            ),

                                            SizedBox(
                                              width:
                                                  12,
                                            ),

                                            Text(
                                              "Signing in...",

                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    16,

                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Row(
                                          key: ValueKey(
                                            "login",
                                          ),

                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,

                                          children: [
                                            Icon(
                                              Icons
                                                  .login_rounded,
                                              size:
                                                  20,
                                            ),

                                            SizedBox(
                                              width:
                                                  9,
                                            ),

                                            Text(
                                              "LOGIN",

                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    16,

                                                fontWeight:
                                                    FontWeight
                                                        .bold,

                                                letterSpacing:
                                                    0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ==========================================
                      // OR
                      // ==========================================

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color:
                                  Colors.grey
                                      .shade200,
                            ),
                          ),

                          const Padding(
                            padding:
                                EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                            ),

                            child: Text(
                              "OR",

                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,

                                fontSize:
                                    11,

                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),

                          Expanded(
                            child: Divider(
                              color:
                                  Colors.grey
                                      .shade200,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==========================================
                      // REGISTER
                      // ==========================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [
                          const Text(
                            "Don't have an account?",

                            style:
                                TextStyle(
                              color:
                                  Colors.grey,

                              fontSize:
                                  13,
                            ),
                          ),

                          TextButton(
                            onPressed:
                                isLoggingIn
                                    ? null
                                    : () {
                                        FocusManager
                                            .instance
                                            .primaryFocus
                                            ?.unfocus();

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const RegisterScreen(),
                                          ),
                                        );
                                      },

                            style:
                                TextButton.styleFrom(
                              foregroundColor:
                                  motoBlue,

                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 6,
                              ),
                            ),

                            child:
                                const Text(
                              "Register",

                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // FOOTER
                //
                // Hidden while keyboard is open.
                // ==================================================

                AnimatedSize(
                  duration:
                      const Duration(milliseconds: 220),

                  curve: Curves.easeOut,

                  child: keyboardOpen
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            const SizedBox(
                              height: 20,
                            ),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,

                              children: [
                                Icon(
                                  Icons
                                      .location_on_outlined,

                                  size: 15,

                                  color:
                                      Colors.grey
                                          .shade600,
                                ),

                                const SizedBox(
                                  width: 4,
                                ),

                                Text(
                                  "Motorcycle Parts Finder",

                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .grey
                                            .shade600,

                                    fontSize:
                                        11,
                                  ),
                                ),

                                const SizedBox(
                                  width: 8,
                                ),

                                Container(
                                  width: 4,
                                  height: 4,

                                  decoration:
                                      const BoxDecoration(
                                    color:
                                        motoOrange,

                                    shape:
                                        BoxShape
                                            .circle,
                                  ),
                                ),

                                const SizedBox(
                                  width: 8,
                                ),

                                Text(
                                  "MotoFind",

                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .grey
                                            .shade600,

                                    fontSize:
                                        11,

                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// FORGOT PASSWORD DIALOG
// ==================================================================

class ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordDialog({
    super.key,
    this.initialEmail = "",
  });

  @override
  State<ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState
    extends State<ForgotPasswordDialog> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  late final TextEditingController emailController;

  // ============================================================
  // STATE
  // ============================================================

  bool isSending = false;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color motoBlue =
      Color(0xFF0D47A1);

  static const Color motoDarkBlue =
      Color(0xFF062B63);

  static const Color motoLightBlue =
      Color(0xFFEAF2FF);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    emailController =
        TextEditingController(
      text: widget.initialEmail,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // INPUT
  // ============================================================

  InputDecoration _inputDecoration() {
    return InputDecoration(
      labelText: "Email",
      hintText:
          "Enter your registered email",

      prefixIcon: const Icon(
        Icons.email_outlined,
        color: motoBlue,
      ),

      filled: true,
      fillColor:
          const Color(0xFFF7F9FC),

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),

        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),

        borderSide:
            BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),

        borderSide:
            const BorderSide(
          color: motoBlue,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _getErrorMessage(
    Object error,
  ) {
    final text =
        error.toString().toLowerCase();

    if (text.contains(
          "user-not-found",
        ) ||
        text.contains(
          "user not found",
        )) {
      return "No account found with this email.";
    }

    if (text.contains(
      "invalid-email",
    )) {
      return "The email address is invalid.";
    }

    if (text.contains(
      "too-many-requests",
    )) {
      return "Too many attempts. Please try again later.";
    }

    if (text.contains(
      "network-request-failed",
    )) {
      return "Network error. Please check your internet connection.";
    }

    return "Unable to send password reset email. Please try again.";
  }

  // ============================================================
  // SEND RESET EMAIL
  // ============================================================

  Future<void> _sendResetEmail() async {
    if (isSending) {
      return;
    }

    final email =
        emailController.text.trim();

    // ----------------------------------------------------------
    // EMPTY
    // ----------------------------------------------------------

    if (email.isEmpty) {
      _showMessage(
        "Please enter your email.",
        isError: true,
      );

      return;
    }

    // ----------------------------------------------------------
    // VALIDATE EMAIL
    // ----------------------------------------------------------

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showMessage(
        "Please enter a valid email address.",
        isError: true,
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      // ========================================================
      // SEND FIREBASE RESET EMAIL
      // ========================================================

      final authService =
          AuthService();

      await authService.resetPassword(
        email,
      );

      debugPrint(
        "PASSWORD RESET EMAIL SENT: $email",
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        email,
      );
    } catch (e) {
      debugPrint(
        "PASSWORD RESET ERROR: $e",
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSending = false;
      });

      _showMessage(
        _getErrorMessage(e),
        isError: true,
      );
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),

          backgroundColor:
              isError
                  ? Colors.red
                  : motoBlue,

          behavior:
              SnackBarBehavior
                  .floating,

          margin:
              const EdgeInsets.all(
            16,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      );
  }

  // ============================================================
  // BUILD DIALOG
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      backgroundColor:
          Colors.white,

      insetPadding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      titlePadding:
          const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        8,
      ),

      contentPadding:
          const EdgeInsets.fromLTRB(
        24,
        10,
        24,
        10,
      ),

      actionsPadding:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16,
      ),

      // ========================================================
      // TITLE
      // ========================================================

      title: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(
              10,
            ),

            decoration:
                BoxDecoration(
              color:
                  motoLightBlue,

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child: const Icon(
              Icons.lock_reset_rounded,
              color: motoBlue,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          const Expanded(
            child: Text(
              "Forgot Password",

              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,

                color:
                    motoDarkBlue,
              ),
            ),
          ),
        ],
      ),

      // ========================================================
      // CONTENT
      // ========================================================

      content:
          SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              "Enter the email address registered "
              "to your MotoFind account.",

              style:
                  TextStyle(
                color:
                    Colors.grey,

                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            TextField(
              controller:
                  emailController,

              keyboardType:
                  TextInputType
                      .emailAddress,

              textInputAction:
                  TextInputAction.done,

              enabled:
                  !isSending,

              autofocus:
                  false,

              scrollPadding:
                  const EdgeInsets
                      .only(
                bottom: 100,
              ),

              onSubmitted: (_) {
                if (!isSending) {
                  _sendResetEmail();
                }
              },

              decoration:
                  _inputDecoration(),
            ),
          ],
        ),
      ),

      // ========================================================
      // ACTIONS
      // ========================================================

      actions: [
        // ======================================================
        // CANCEL
        // ======================================================

        TextButton(
          onPressed: isSending
              ? null
              : () {
                  Navigator.of(
                    context,
                  ).pop();
                },

          child: const Text(
            "Cancel",

            style:
                TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        // ======================================================
        // SEND
        // ======================================================

        ElevatedButton(
          onPressed: isSending
              ? null
              : _sendResetEmail,

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                motoBlue,

            foregroundColor:
                Colors.white,

            elevation: 0,

            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 18,
              vertical: 12,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
          ),

          child: isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,

                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,

                    color:
                        Colors.white,
                  ),
                )
              : const Text(
                  "SEND RESET LINK",

                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}