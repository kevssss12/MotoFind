import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/cloudinary_service.dart';
import '../../services/subscription_service.dart';
import 'store_dashboard.dart';
import '../auth/login_screen.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
final String plan;
final int amount;
final bool isRenewal;
final bool isExpiredRenewal;

const SubscriptionPaymentScreen({
super.key,
required this.plan,
required this.amount,
this.isRenewal = false,
this.isExpiredRenewal = false,
});

@override
State<SubscriptionPaymentScreen> createState() =>
_SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState
extends State<SubscriptionPaymentScreen> {
XFile? selectedImage;

final ImagePicker picker = ImagePicker();

bool isSubmitting = false;
bool hasPendingRenewal = false;
bool checkingRenewal = true;

// ============================================================
// INIT
// ============================================================

@override
void initState() {
super.initState();
if (widget.isRenewal) {
  checkPendingRenewal();
} else {
  checkingRenewal = false;
}

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
      checkingRenewal = false;
    });

    return;
  }

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!userDoc.exists) {
    if (!mounted) return;

    setState(() {
      checkingRenewal = false;
    });

    return;
  }

  final data = userDoc.data() ?? {};

  final String renewalStatus =
      data['renewalStatus']
              ?.toString()
              .trim()
              .toLowerCase() ??
          '';

  final bool pending = renewalStatus == 'pending';

  debugPrint('RENEWAL STATUS: $renewalStatus');

  if (!mounted) return;

  setState(() {
    hasPendingRenewal = pending;
    checkingRenewal = false;
  });
} catch (e) {
  debugPrint('Error checking pending renewal: $e');

  if (!mounted) return;

  setState(() {
    checkingRenewal = false;
  });
}

}

// ============================================================
// PICK PAYMENT SCREENSHOT
// ============================================================

Future<void> pickPaymentScreenshot() async {
if (isSubmitting ||
checkingRenewal ||
hasPendingRenewal) {
return;
}
try {
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );

  if (image != null) {
    if (!mounted) return;

    setState(() {
      selectedImage = image;
    });
  }
} catch (e) {
  debugPrint('Image picker error: $e');

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Unable to select image: $e'),
      backgroundColor: Colors.red,
    ),
  );
}

}

// ============================================================
// SUBMIT PAYMENT
// ============================================================

Future<void> submitPayment() async {
if (isSubmitting) {
return;
}
// ----------------------------------------------------------
// BLOCK SECOND RENEWAL
// ----------------------------------------------------------

if (widget.isRenewal && hasPendingRenewal) {
  showPendingMessage();
  return;
}

// ----------------------------------------------------------
// REQUIRE PAYMENT SCREENSHOT
// ----------------------------------------------------------

if (selectedImage == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Please upload payment screenshot first.',
      ),
    ),
  );

  return;
}

// ----------------------------------------------------------
// CHECK LOGIN
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
  // GET USER
  // ========================================================

  final userRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid);

  final userDoc = await userRef.get();

  if (!userDoc.exists) {
    throw Exception(
      'User information not found.',
    );
  }

  final data = userDoc.data() ?? {};

  // ========================================================
  // GET STORE ID
  // ========================================================

  final storeIdValue = data['storeId'];

  if (storeIdValue == null ||
      storeIdValue.toString().trim().isEmpty) {
    throw Exception(
      'Store ID not found. Please contact Admin.',
    );
  }

  final String storeId =
      storeIdValue.toString().trim();

  // ========================================================
  // RENEWAL
  // ========================================================

  if (widget.isRenewal) {
    // ------------------------------------------------------
    // ATOMIC CHECK + LOCK
    // ------------------------------------------------------

    final bool locked =
        await FirebaseFirestore.instance
            .runTransaction<bool>(
      (transaction) async {
        final freshDoc =
            await transaction.get(userRef);

        if (!freshDoc.exists) {
          throw Exception(
            'User information not found.',
          );
        }

        final freshData =
            freshDoc.data() ?? {};

        final String renewalStatus =
            freshData['renewalStatus']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        // --------------------------------------------------
        // ALREADY PENDING
        // --------------------------------------------------

        if (renewalStatus == 'pending') {
          return false;
        }

        // --------------------------------------------------
        // CREATE PENDING LOCK
        // --------------------------------------------------

        transaction.update(
          userRef,
          {
            'renewalPlan': widget.plan,
            'renewalAmount': widget.amount,
            'renewalStatus': 'Pending',
            'renewalSubmittedAt':
                FieldValue.serverTimestamp(),
          },
        );

        return true;
      },
    );

    // ------------------------------------------------------
    // SECOND REQUEST BLOCKED
    // ------------------------------------------------------

    if (!locked) {
      if (!mounted) return;

      setState(() {
        hasPendingRenewal = true;
        isSubmitting = false;
      });

      showPendingMessage();

      return;
    }

    // ------------------------------------------------------
    // UPLOAD SCREENSHOT
    // ------------------------------------------------------

    final String? imageUrl =
        await CloudinaryService.uploadImage(
      selectedImage!,
    );

    debugPrint(
      'Cloudinary URL: $imageUrl',
    );

    // ------------------------------------------------------
    // IF UPLOAD FAILED → REMOVE LOCK
    // ------------------------------------------------------

    if (imageUrl == null ||
        imageUrl.trim().isEmpty) {
      await userRef.update({
        'renewalStatus':
            FieldValue.delete(),
        'renewalPlan':
            FieldValue.delete(),
        'renewalAmount':
            FieldValue.delete(),
        'renewalSubmittedAt':
            FieldValue.delete(),
      });

      throw Exception(
        'Image upload failed.',
      );
    }

    // ------------------------------------------------------
    // SAVE RENEWAL SCREENSHOT
    // ------------------------------------------------------

    await userRef.update({
      'renewalPlan': widget.plan,
      'renewalAmount': widget.amount,
      'renewalScreenshot': imageUrl,
      'renewalStatus': 'Pending',
      'renewalSubmittedAt':
          FieldValue.serverTimestamp(),
    });

    debugPrint(
      'Renewal request submitted successfully.',
    );
  }

  // ========================================================
  // FIRST SUBSCRIPTION
  // ========================================================

  else {
    // ------------------------------------------------------
    // UPLOAD PAYMENT SCREENSHOT
    // ------------------------------------------------------

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

    // ------------------------------------------------------
    // CREATE SUBSCRIPTION
    // ------------------------------------------------------

    await SubscriptionService()
        .createSubscription(
      storeId: storeId,
      storeName:
          data['storeName'] ?? '',
      storeAddress:
          data['storeAddress'] ?? '',
      ownerId:
          user.uid,
      ownerName:
          data['fullName'] ?? '',
      email:
          data['email'] ?? '',
      phone:
          data['phone'] ?? '',
      plan:
          widget.plan,
      amount:
          widget.amount,
      paymentImageUrl:
          imageUrl,
    );

    debugPrint(
      'First subscription submitted successfully.',
    );
  }

  // ========================================================
  // SUCCESS MESSAGE
  // ========================================================

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        widget.isRenewal
            ? 'Renewal submitted successfully!\n'
                'Please wait for Admin approval.'
            : 'Payment submitted successfully!\n'
                'Please wait for Admin approval.',
      ),
      duration:
          const Duration(seconds: 2),
    ),
  );

  await Future.delayed(
    const Duration(seconds: 2),
  );

  if (!mounted) return;

  // ========================================================
  // FIRST SUBSCRIPTION → LOGIN
  // ========================================================

  if (!widget.isRenewal) {
    debugPrint(
      'FIRST SUBSCRIPTION → LOGIN',
    );

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );

    return;
  }

  // ========================================================
  // CHECK ACTUAL SUBSCRIPTION STATUS
  // ========================================================

  bool actualSubscriptionExpired = false;

  try {
    final latestUserDoc =
        await userRef.get();

    if (latestUserDoc.exists) {
      final latestData =
          latestUserDoc.data() ?? {};

      final String subscriptionStatus =
          latestData['subscriptionStatus']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      Timestamp? subscriptionEnd;

      if (latestData['subscriptionEnd']
          is Timestamp) {
        subscriptionEnd =
            latestData['subscriptionEnd']
                as Timestamp;
      } else if (latestData[
              'subscriptionEndDate']
          is Timestamp) {
        subscriptionEnd =
            latestData[
                    'subscriptionEndDate']
                as Timestamp;
      }

      final bool expiredByStatus =
          subscriptionStatus == 'expired';

      final bool expiredByDate =
          subscriptionEnd != null &&
          !DateTime.now().isBefore(
            subscriptionEnd.toDate(),
          );

      actualSubscriptionExpired =
          expiredByStatus ||
              expiredByDate;

      debugPrint(
        'LATEST SUBSCRIPTION STATUS: '
        '$subscriptionStatus',
      );

      debugPrint(
        'LATEST SUBSCRIPTION END: '
        '$subscriptionEnd',
      );

      debugPrint(
        'EXPIRED BY STATUS: '
        '$expiredByStatus',
      );

      debugPrint(
        'EXPIRED BY DATE: '
        '$expiredByDate',
      );

      debugPrint(
        'ACTUAL SUBSCRIPTION EXPIRED: '
        '$actualSubscriptionExpired',
      );
    }
  } catch (e) {
    debugPrint(
      'Error checking latest subscription status: $e',
    );
  }

  // ========================================================
  // EXPIRED RENEWAL → LOGIN
  // ========================================================

  if (actualSubscriptionExpired) {
    debugPrint(
      'EXPIRED RENEWAL → LOGIN',
    );

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) => false,
    );

    return;
  }

  // ========================================================
  // ADVANCE RENEWAL → DASHBOARD
  // ========================================================

  debugPrint(
    'ADVANCE RENEWAL → STORE DASHBOARD',
  );

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) =>
          const StoreDashboard(),
    ),
    (route) => false,
  );
} catch (e) {
  // ========================================================
  // ERROR
  // ========================================================

  debugPrint(
    'Payment submission error: $e',
  );

  if (!mounted) return;

  setState(() {
    isSubmitting = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Submission failed: $e',
      ),
      backgroundColor: Colors.red,
    ),
  );
}

}

// ============================================================
// PENDING MESSAGE
// ============================================================

void showPendingMessage() {
if (!mounted) return;

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
        'You already have a renewal request '
        'waiting for Admin approval.\n\n'
        'You cannot submit another renewal '
        'payment while the current request '
        'is pending.',
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              dialogContext,
            );
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
// PAYMENT DETAILS
// ============================================================

Widget buildPaymentDetails() {
return Card(
elevation: 2,
child: Padding(
padding:
const EdgeInsets.all(18),
child: Row(
crossAxisAlignment:
CrossAxisAlignment.center,
children: [
Container(
width: 55,
height: 55,
decoration:
BoxDecoration(
color:
Colors.blue.withOpacity(
0.1,
),
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
'Plan',
style: TextStyle(
color: Colors.grey,
),
),
const SizedBox(height: 3),
Text(
widget.plan,
style:
const TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 5),
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
);
}

// ============================================================
// IMAGE PREVIEW
// ============================================================

Widget buildImagePreview() {
if (selectedImage == null) {
return const SizedBox();
}


return Center(
  child: Column(
    children: [
      const Text(
        'Payment Screenshot Preview',
        style: TextStyle(
          fontWeight:
              FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius:
            BorderRadius.circular(
          10,
        ),
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
// GCASH QR CODE
// ============================================================

// ============================================================
// GCASH PAYMENT
// ============================================================

Widget buildGcashPayment() {
  return Card(
    elevation: 2,
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'GCash Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'GCash Number',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 4),

          const SelectableText(
            '09636751649',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Account Name',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Kevin P. saturinas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          const Text(
            'Scan this QR Code to pay',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          // ==================================================
          // QR CODE
          // ==================================================

          Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.shade400,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          child: Image.asset(
  'assets/gcash_qr.png',
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) {
    debugPrint('================================');
    debugPrint('GCASH QR IMAGE ERROR: $error');
    debugPrint('STACK: $stackTrace');
    debugPrint('================================');

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 40,
          ),
          SizedBox(height: 8),
          Text(
            'QR Code unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  },
),
          ),

          const SizedBox(height: 12),

          Text(
            'Please pay ₱${widget.amount} before uploading your payment screenshot.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
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

  final bool disableAll = isSubmitting ||
      checkingRenewal ||
      (widget.isRenewal && hasPendingRenewal);

  return Scaffold(
    backgroundColor: pageBackground,
    appBar: AppBar(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Subscription Payment',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
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
                    color: darkBlue.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  const Row(
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        color: primaryBlue,
                        size: 29,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subscription Details',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: darkBlue,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Review your plan and submit your payment.',
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
                  const Divider(color: Color(0xFFD6DDEC)),
                  const SizedBox(height: 20),

                  // PLAN DETAILS
                  buildPaymentDetails(),

                  const SizedBox(height: 18),

                  // GCASH PAYMENT
                  buildGcashPayment(),

                  const SizedBox(height: 20),

                  // PENDING RENEWAL WARNING
                  if (widget.isRenewal && hasPendingRenewal) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade400,
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.hourglass_top,
                            color: Colors.deepOrange,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your renewal request is currently pending. '
                              'Please wait for Admin approval before submitting another payment.',
                              style: TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // UPLOAD SCREENSHOT
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed:
                          disableAll ? null : pickPaymentScreenshot,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(
                        hasPendingRenewal
                            ? 'Renewal Already Submitted'
                            : 'Upload Payment Screenshot',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // IMAGE PREVIEW
                  if (selectedImage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE1E8F0),
                        ),
                      ),
                      child: buildImagePreview(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // SUBMIT PAYMENT
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: disableAll ? null : submitPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        checkingRenewal
                            ? 'Checking...'
                            : isSubmitting
                                ? 'Submitting...'
                                : hasPendingRenewal
                                    ? 'Renewal Pending'
                                    : 'Submit Payment',
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
  );
}
}
