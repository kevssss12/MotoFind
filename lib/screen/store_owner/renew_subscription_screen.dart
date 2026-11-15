import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/login_screen.dart';
import '../../services/cloudinary_service.dart';

class RenewSubscriptionScreen extends StatefulWidget {
  final String plan;
  final int amount;

  // true = advance renewal
  // false = expired renewal
  final bool isAdvanceRenewal;

  const RenewSubscriptionScreen({
    super.key,
    required this.plan,
    required this.amount,
    this.isAdvanceRenewal = false,
  });

  @override
  State<RenewSubscriptionScreen> createState() =>
      _RenewSubscriptionScreenState();
}

class _RenewSubscriptionScreenState
    extends State<RenewSubscriptionScreen> {
  final ImagePicker picker = ImagePicker();

  XFile? selectedImage;

  bool isSubmitting = false;
  bool isChecking = true;
  bool hasPending = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    checkPendingRenewal();
  }

  // ============================================================
  // CHECK PENDING RENEWAL
  // ============================================================

  Future<void> checkPendingRenewal() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isChecking = false;
        });

        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        if (!mounted) return;

        setState(() {
          isChecking = false;
        });

        return;
      }

      final data = doc.data();

      if (data == null) {
        if (!mounted) return;

        setState(() {
          isChecking = false;
        });

        return;
      }

      // ==========================================================
      // CHECK renewalStatus
      // ==========================================================

      final renewalStatus =
          data['renewalStatus']?.toString().trim().toLowerCase() ?? '';

      if (renewalStatus == 'pending') {
        if (!mounted) return;

        setState(() {
          hasPending = true;
          isChecking = false;
        });

        return;
      }

      // ==========================================================
      // EXTRA CHECK
      // subscriptions collection
      // ==========================================================

      final storeId = data['storeId']?.toString();

      if (storeId != null && storeId.isNotEmpty) {
        final query = await FirebaseFirestore.instance
            .collection('subscriptions')
            .where(
              'storeId',
              isEqualTo: storeId,
            )
            .where(
              'status',
              isEqualTo: 'Pending',
            )
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          if (!mounted) return;

          setState(() {
            hasPending = true;
            isChecking = false;
          });

          return;
        }
      }

      if (!mounted) return;

      setState(() {
        hasPending = false;
        isChecking = false;
      });
    } catch (e) {
      debugPrint(
        'CHECK PENDING RENEWAL ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isChecking = false;
      });
    }
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> pickPaymentScreenshot() async {
    if (isSubmitting || hasPending || isChecking) {
      return;
    }

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
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
        'IMAGE PICKER ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select image: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CHECK AGAIN BEFORE SUBMIT
  // ============================================================

  Future<bool> checkPendingAgain(
    String uid,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data();

      if (data == null) {
        return false;
      }

      final status =
          data['renewalStatus']?.toString().trim().toLowerCase() ?? '';

      return status == 'pending';
    } catch (e) {
      debugPrint(
        'CHECK PENDING AGAIN ERROR: $e',
      );

      return false;
    }
  }

  // ============================================================
  // SUBMIT RENEWAL
  // ============================================================

  Future<void> submitRenewal() async {
    // ----------------------------------------------------------
    // PROTECTION
    // ----------------------------------------------------------

    if (isSubmitting) {
      return;
    }

    if (isChecking) {
      return;
    }

    if (hasPending) {
      showPendingDialog();
      return;
    }

    // ----------------------------------------------------------
    // CHECK IMAGE
    // ----------------------------------------------------------

    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload your renewal screenshot first.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CHECK USER
    // ----------------------------------------------------------

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User not logged in.',
          ),
        ),
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      // ========================================================
      // GET USER DATA
      // ========================================================

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception(
          'User information not found.',
        );
      }

      final data = userDoc.data();

      if (data == null) {
        throw Exception(
          'User information is empty.',
        );
      }

      final storeId = data['storeId']?.toString();

      if (storeId == null || storeId.isEmpty) {
        throw Exception(
          'Store ID not found. Please contact Admin.',
        );
      }

      // ========================================================
      // SECOND PENDING CHECK
      // ========================================================

      final alreadyPending =
          await checkPendingAgain(user.uid);

      if (alreadyPending) {
        if (!mounted) return;

        setState(() {
          hasPending = true;
          isSubmitting = false;
        });

        showPendingDialog();

        return;
      }

      // ========================================================
      // UPLOAD PAYMENT SCREENSHOT
      // ========================================================

      debugPrint(
        'Uploading renewal screenshot...',
      );

      final String? imageUrl =
          await CloudinaryService.uploadImage(
        selectedImage!,
      );

      debugPrint(
        'Cloudinary URL: $imageUrl',
      );

      if (imageUrl == null ||
          imageUrl.trim().isEmpty) {
        throw Exception(
          'Image upload failed.',
        );
      }

      // ========================================================
      // SAVE RENEWAL REQUEST
      // ========================================================

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'renewalPlan': widget.plan,
        'renewalAmount': widget.amount,
        'renewalScreenshot': imageUrl,
        'renewalStatus': 'Pending',
        'renewalSubmittedAt':
            FieldValue.serverTimestamp(),

        // Important:
        // Admin can know whether this is advance renewal.
        'renewalType': widget.isAdvanceRenewal
            ? 'Advance'
            : 'Expired',
      });

      debugPrint(
        'RENEWAL REQUEST SAVED SUCCESSFULLY',
      );

      // ========================================================
      // UPDATE UI
      // ========================================================

      if (!mounted) return;

      setState(() {
        hasPending = true;
        isSubmitting = false;
      });

      // ========================================================
      // SUCCESS MESSAGE
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAdvanceRenewal
                ? 'Advance renewal submitted successfully!\n'
                    'Please wait for Admin approval.'
                : 'Renewal submitted successfully!\n'
                    'Please wait for Admin approval.',
          ),
          duration: const Duration(
            seconds: 3,
          ),
        ),
      );

      // ========================================================
      // WAIT
      // ========================================================

      await Future.delayed(
        const Duration(
          seconds: 2,
        ),
      );

      if (!mounted) return;

      // ========================================================
      // ADVANCE RENEWAL
      // ========================================================
      //
      // Stay in Store Dashboard.
      //
      // Navigator.pop() returns to the screen that opened
      // RenewSubscriptionScreen.
      //

      if (widget.isAdvanceRenewal) {
        Navigator.pop(context);
        return;
      }

      // ========================================================
      // EXPIRED RENEWAL
      // ========================================================
      //
      // Return to Login.
      //

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        'RENEWAL SUBMISSION ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Renewal submission failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // PENDING DIALOG
  // ============================================================

  void showPendingDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.hourglass_top,
                color: Colors.orange,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Renewal Pending',
                ),
              ),
            ],
          ),
          content: const Text(
            'You already have a pending renewal request.\n\n'
            'Please wait for Admin approval before submitting another payment.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'OK',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  Widget buildImagePreview() {
    if (selectedImage == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Column(
        children: [
          const Text(
            'Renewal Screenshot Preview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: kIsWeb
                ? Image.network(
                    selectedImage!.path,
                    height: 200,
                    fit: BoxFit.contain,
                  )
                : Image.file(
                    File(
                      selectedImage!.path,
                    ),
                    height: 200,
                    fit: BoxFit.contain,
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool disabled =
        isChecking ||
        isSubmitting ||
        hasPending;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Renew Subscription',
        ),
        centerTitle: true,

        // ------------------------------------------------------
        // BACK BUTTON
        // ------------------------------------------------------

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: isSubmitting
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
          ),

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // TITLE
                // ==================================================

                Text(
                  widget.isAdvanceRenewal
                      ? 'Advance Renewal'
                      : 'Renew Subscription',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // TYPE MESSAGE
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(15),

                  decoration: BoxDecoration(
                    color: widget.isAdvanceRenewal
                        ? Colors.blue.shade50
                        : Colors.orange.shade50,

                    borderRadius:
                        BorderRadius.circular(12),

                    border: Border.all(
                      color: widget.isAdvanceRenewal
                          ? Colors.blue
                          : Colors.orange,
                    ),
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Icon(
                        widget.isAdvanceRenewal
                            ? Icons.autorenew
                            : Icons.warning_amber,

                        color:
                            widget.isAdvanceRenewal
                                ? Colors.blue
                                : Colors.orange,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          widget.isAdvanceRenewal
                              ? 'You are renewing your subscription in advance. '
                                  'After submitting, you will remain in the Store Dashboard '
                                  'while waiting for Admin approval.'
                              : 'Your subscription has expired. '
                                  'After submitting your renewal, you will be returned to Login '
                                  'while waiting for Admin approval.',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // PENDING WARNING
                // ==================================================

                if (hasPending)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(15),

                    decoration: BoxDecoration(
                      color:
                          Colors.orange.shade50,

                      borderRadius:
                          BorderRadius.circular(12),

                      border: Border.all(
                        color: Colors.orange,
                      ),
                    ),

                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Icon(
                          Icons.hourglass_top,
                          color: Colors.orange,
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'Your renewal request is already pending. '
                            'Please wait for Admin approval. '
                            'You cannot submit another renewal.',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (hasPending)
                  const SizedBox(height: 20),

                // ==================================================
                // PLAN CARD
                // ==================================================

                Card(
                  elevation: 3,

                  child: Padding(
                    padding:
                        const EdgeInsets.all(18),

                    child: Row(
                      children: [
                        Container(
                          width: 55,
                          height: 55,

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.blue.shade50,

                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),

                          child: const Icon(
                            Icons.workspace_premium,
                            size: 30,
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              const Text(
                                'Subscription Plan',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                widget.plan,
                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                'Amount: ₱${widget.amount}',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // GCASH
                // ==================================================

                const Text(
                  'GCash Number',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const SelectableText(
                  '09123456789',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Account Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'MotoFind Subscription',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // QR
                // ==================================================

                const Text(
                  'Scan this QR Code',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: Container(
                    width: 220,
                    height: 220,

                    decoration:
                        BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),

                    child: const Center(
                      child: Text(
                        'GCash QR Code\n\n'
                        '(Replace with QR Image)',
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // UPLOAD
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton.icon(
                    onPressed: disabled
                        ? null
                        : pickPaymentScreenshot,

                    icon: const Icon(
                      Icons.image,
                    ),

                    label: Text(
                      hasPending
                          ? 'Renewal Already Submitted'
                          : 'Upload Renewal Screenshot',
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // PREVIEW
                // ==================================================

                buildImagePreview(),

                if (selectedImage != null)
                  const SizedBox(height: 30),

                // ==================================================
                // SUBMIT
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton.icon(
                    onPressed: disabled
                        ? null
                        : submitRenewal,

                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check,
                          ),

                    label: Text(
                      isChecking
                          ? 'Checking...'
                          : isSubmitting
                              ? 'Submitting...'
                              : hasPending
                                  ? 'Renewal Pending'
                                  : 'Submit Renewal',
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}