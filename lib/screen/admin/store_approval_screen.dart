
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class StoreApprovalScreen extends StatelessWidget {
  const StoreApprovalScreen({super.key});
  // ============================================================
  // EMAILJS CONFIGURATION
  // ============================================================
  static const String emailServiceId = 'service_z8yg44j';
  static const String emailTemplateId = 'template_179fbqg';
  static const String emailPublicKey = 'bztIZU2pTXe7p315I';
  // ============================================================
  // SEND EMAIL TO STORE OWNER
  // ============================================================
  Future<bool> sendOwnerEmail({
    required String email,
    required String ownerName,
    required String storeName,
    required String status,
    required String message,
  }) async {
    final String cleanEmail = email.trim();
    final String cleanOwnerName = ownerName.trim();
    final String cleanStoreName = storeName.trim();
    final String cleanStatus = status.trim();
    final String cleanMessage = message.trim();
    debugPrint('');
    debugPrint('==================================================');
    debugPrint('EMAILJS REST API: SEND EMAIL START');
    debugPrint('==================================================');
    debugPrint('To Email    : $cleanEmail');
    debugPrint('Owner Name  : $cleanOwnerName');
    debugPrint('Store Name  : $cleanStoreName');
    debugPrint('Status      : $cleanStatus');
    debugPrint('Service ID  : $emailServiceId');
    debugPrint('Template ID : $emailTemplateId');
    debugPrint('Public Key  : $emailPublicKey');
    debugPrint('==================================================');
    if (cleanEmail.isEmpty) {
      debugPrint('EMAILJS ERROR: Email is empty.');
      return false;
    }
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      debugPrint('EMAILJS ERROR: Invalid email: $cleanEmail');
      return false;
    }
    try {
      final Uri uri = Uri.parse(
        'https://api.emailjs.com/api/v1.0/email/send',
      );
      final Map<String, dynamic> requestBody = {
        'service_id': emailServiceId,
        'template_id': emailTemplateId,
        'user_id': emailPublicKey,
        'template_params': {
          'to_name': cleanOwnerName,
          'status': cleanStatus,
          'store_name': cleanStoreName,
          'message': cleanMessage,
          'to_email': cleanEmail,
        },
      };
      debugPrint('EMAILJS REST API: Sending request...');
      debugPrint('Request body:');
      debugPrint(jsonEncode(requestBody));
      final http.Response response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      debugPrint('');
      debugPrint('==================================================');
      debugPrint('EMAILJS REST API RESPONSE');
      debugPrint('==================================================');
      debugPrint('HTTP Status : ${response.statusCode}');
      debugPrint('Response    : ${response.body}');
      debugPrint('==================================================');
      if (response.statusCode == 200) {
        debugPrint('EMAILJS: EMAIL SENT SUCCESSFULLY.');
        debugPrint('To: $cleanEmail');
        return true;
      }
      debugPrint('EMAILJS ERROR: Email was not sent.');
      debugPrint('HTTP ${response.statusCode}');
      debugPrint('Response: ${response.body}');
      return false;
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('==================================================');
      debugPrint('EMAILJS REST API ERROR');
      debugPrint('==================================================');
      debugPrint('Error: $e');
      debugPrint('StackTrace:');
      debugPrint('$stackTrace');
      debugPrint('==================================================');
      return false;
    }
  }
  // ============================================================
  // CREATE OR REPAIR STORE RECORD
  // ENSURE STORE ID IS SAVED IN USERS AND STORES
  // ============================================================
  Future<String> createOrRepairStore(String uid) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference<Map<String, dynamic>> ownerRef =
        firestore.collection("users").doc(uid);
    final DocumentSnapshot<Map<String, dynamic>> owner =
        await ownerRef.get();
    if (!owner.exists || owner.data() == null) {
      throw Exception("Store owner account not found.");
    }
    final Map<String, dynamic> ownerData = owner.data()!;
    final String storeName =
        ownerData["storeName"]?.toString().trim() ?? "";
    if (storeName.isEmpty) {
      throw Exception("Store name is missing.");
    }
    String storeId = ownerData["storeId"]?.toString().trim() ?? "";
    // STEP 1: CHECK THE STORE ID ALREADY SAVED IN USERS
    if (storeId.isNotEmpty) {
      final existingStore = await firestore
          .collection("stores")
          .doc(storeId)
          .get();
      if (!existingStore.exists) {
        storeId = "";
      }
    }
    // STEP 2: FIND AN EXISTING STORE BY OWNER ID
    if (storeId.isEmpty) {
      final existingStores = await firestore
          .collection("stores")
          .where("ownerId", isEqualTo: uid)
          .limit(1)
          .get();
      if (existingStores.docs.isNotEmpty) {
        storeId = existingStores.docs.first.id;
      }
    }
    // STEP 3: CHECK WHETHER THE STORE DOCUMENT USES THE OWNER UID
    // REUSE IT ONLY IF IT BELONGS TO THIS OWNER OR HAS NO ownerId.
    if (storeId.isEmpty) {
      final storeUsingOwnerUid =
          await firestore.collection("stores").doc(uid).get();
      if (storeUsingOwnerUid.exists) {
        final Map<String, dynamic> existingData =
            storeUsingOwnerUid.data() ?? {};
        final String existingOwnerId =
            existingData["ownerId"]?.toString().trim() ?? "";
        if (existingOwnerId.isEmpty || existingOwnerId == uid) {
          storeId = uid;
        }
      }
    }
    // STEP 4: GENERATE AN ID ONLY IF NO EXISTING STORE WAS FOUND
    if (storeId.isEmpty) {
      storeId = firestore.collection("stores").doc().id;
    }
    final DocumentReference<Map<String, dynamic>> storeRef =
        firestore.collection("stores").doc(storeId);

    final DocumentSnapshot<Map<String, dynamic>> existingStore =
        await storeRef.get();
    // STEP 5: PREPARE STORE INFORMATION
    final Map<String, dynamic> storeData = {
      "storeId": storeId,
      "ownerId": uid,
      "storeName": storeName,
      "ownerName": ownerData["fullName"] ??
          ownerData["name"] ??
          "Store Owner",
      "storeAddress": ownerData["storeAddress"] ?? "",
      "phone": ownerData["phone"] ?? "",
      "permitNumber": ownerData["permitNumber"] ?? "",
      "permitImageUrl": ownerData["permitImageUrl"] ?? "",
      "validIdImageUrl": ownerData["validIdImageUrl"] ?? "",
    };
    if (!existingStore.exists) {
      storeData["createdAt"] =
          ownerData["createdAt"] ?? FieldValue.serverTimestamp();
    } else {
      storeData["updatedAt"] = FieldValue.serverTimestamp();
    }
    // STEP 6: SAVE THE STORE AND ITS ID TO THE USER ATOMICALLY
    final WriteBatch batch = firestore.batch();
    batch.set(
      storeRef,
      storeData,
      SetOptions(merge: true),
    );
    batch.set(
      ownerRef,
      {
        "storeId": storeId,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    // STEP 7: VERIFY THAT THE USER NOW HAS THE STORE ID
    final DocumentSnapshot<Map<String, dynamic>> verifiedOwner =
        await ownerRef.get();
    final String savedStoreId =
        verifiedOwner.data()?["storeId"]?.toString().trim() ?? "";
    if (savedStoreId != storeId) {
      throw Exception("Failed to save Store ID to the user account.");
    }
    debugPrint("STORE RECORD SAVED SUCCESSFULLY");
    debugPrint("OWNER UID: $uid");
    debugPrint("STORE ID: $storeId");
    debugPrint("STORE NAME: $storeName");
    return storeId;
  }
  // ============================================================
  // APPROVE STORE
  // ============================================================
  Future<void> approveStore(
    BuildContext context,
    String uid,
  ) async {
    final ownerRef =
        FirebaseFirestore.instance.collection("users").doc(uid);
    final owner = await ownerRef.get();
    if (!owner.exists) {
      throw Exception("Store owner account not found.");
    }
    final ownerData = owner.data() as Map<String, dynamic>;
    // ==========================================================
    // OWNER INFORMATION
    // ==========================================================
    final String ownerEmail =
        ownerData["email"]?.toString().trim() ?? "";
    final String ownerName =
        (ownerData["fullName"] ??
                ownerData["name"] ??
                "Store Owner")
            .toString()
            .trim();
    final String storeName =
    ownerData["storeName"]?.toString().trim() ?? "";
    debugPrint('');
    debugPrint('==================================================');
    debugPrint('APPROVE STORE START');
    debugPrint('==================================================');
    debugPrint('UID: $uid');
    debugPrint('OWNER EMAIL: $ownerEmail');
    debugPrint('OWNER NAME: $ownerName');
    debugPrint('STORE NAME: $storeName');
    debugPrint('==================================================');
    // ==========================================================
    // CREATE OR REPAIR STORE PROFILE
    // ==========================================================
    final String storeId = await createOrRepairStore(uid);
    debugPrint('STORE PROFILE SAVED: $storeId');
    // ==========================================================
    // UPDATE OWNER STATUS
    // ==========================================================
    await ownerRef.update({
      "status": "Approved",
      "storeId": storeId,
    });
    debugPrint('OWNER STATUS UPDATED TO APPROVED');
    // ==========================================================
    // SEND APPROVAL EMAIL
    // ==========================================================
    if (ownerEmail.isNotEmpty) {
      final bool emailSent = await sendOwnerEmail(
        email: ownerEmail,
        ownerName: ownerName,
        storeName: storeName,
        status: "Approved",
        message:
            "Congratulations! Your Store Owner application has been approved. You may now access your Store Owner account.",
      );
      if (!emailSent) {
        debugPrint(
          'WARNING: Store approved but email was not sent.',
        );
      }
    } else {
      debugPrint(
        'WARNING: Store approved but owner email is empty.',
      );
    }
    debugPrint('');
    debugPrint('==================================================');
    debugPrint('APPROVE STORE COMPLETE');
    debugPrint('STORE ID: $storeId');
    debugPrint('==================================================');
  }
  // ============================================================
  // REJECT STORE
  // ============================================================
  Future<void> rejectStore(
    BuildContext context,
    String uid,
  ) async {
    final ownerRef =
        FirebaseFirestore.instance.collection("users").doc(uid);
    final owner = await ownerRef.get();
    if (!owner.exists) {
      throw Exception("Store owner account not found.");
    }
    final ownerData = owner.data() as Map<String, dynamic>;
    // ==========================================================
    // OWNER INFORMATION
    // ==========================================================
    final String ownerEmail =
        ownerData["email"]?.toString().trim() ?? "";
    final String ownerName =
        (ownerData["fullName"] ??
                ownerData["name"] ??
                "Store Owner")
            .toString()
            .trim();
    final String storeName =
    ownerData["storeName"]?.toString().trim() ?? "";
    debugPrint('');
    debugPrint('==================================================');
    debugPrint('REJECT STORE START');
    debugPrint('==================================================');
    debugPrint('UID: $uid');
    debugPrint('OWNER EMAIL: $ownerEmail');
    debugPrint('OWNER NAME: $ownerName');
    debugPrint('STORE NAME: $storeName');
    debugPrint('==================================================');
    // ==========================================================
    // DO NOT DELETE.
    // STATUS ONLY.
    // ==========================================================
    await ownerRef.update({
      "status": "Rejected",
    });
    debugPrint('OWNER STATUS UPDATED TO REJECTED');
    // ==========================================================
    // SEND REJECTION EMAIL
    // ==========================================================
    if (ownerEmail.isNotEmpty) {
      final bool emailSent = await sendOwnerEmail(
        email: ownerEmail,
        ownerName: ownerName,
        storeName: storeName,
        status: "Rejected",
        message:
            "We are sorry, but your Store Owner application has been rejected. Please review your application details and contact the MotoFind Team if you need further assistance.",
      );
      if (!emailSent) {
        debugPrint(
          'WARNING: Application rejected but email was not sent.',
        );
      }
    } else {
      debugPrint(
        'WARNING: Application rejected but owner email is empty.',
      );
    }
    debugPrint('');
    debugPrint('==================================================');
    debugPrint('REJECT STORE COMPLETE');
    debugPrint('==================================================');
  }
  // ============================================================
  // SHOW FULL APPLICATION DETAILS
  // ============================================================
  void _showApplicationDetails(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
  ) {
    final String storeName =
        data["storeName"]?.toString().trim().isNotEmpty == true
            ? data["storeName"].toString()
            : "Unnamed Store";
    final String ownerName =
        (data["fullName"] ?? data["name"] ?? "Store Owner")
            .toString();
    final String email = data["email"]?.toString() ?? "";
    final String phone = data["phone"]?.toString() ?? "";
    final String address = data["storeAddress"]?.toString() ?? "";
    final String permitNumber = data["permitNumber"]?.toString() ?? "";
    final String permitImageUrl =
        data["permitImageUrl"]?.toString().trim() ?? "";
    final String validIdImageUrl =
        data["validIdImageUrl"]?.toString().trim() ?? "";
    final String status = data["status"]?.toString() ?? "Pending";
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: 600,
            height: MediaQuery.of(context).size.height * 0.88,
            child: Column(
              children: [
                // ==================================================
                // HEADER
                // ==================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 8, 15),
                  child: Row(
                    children: [
                      const Icon(Icons.store, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          storeName,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // ==================================================
                // CONTENT
                // ==================================================
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==========================================
                        // STATUS
                        // ==========================================
                        _statusBox(status),

                        const SizedBox(height: 22),
                        // ==========================================
                        // STORE INFORMATION
                        // ==========================================
                        const Text(
                          "Store Information",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _detailRow(
                          Icons.store,
                          "Store Name",
                          storeName,
                        ),
                        _detailRow(
                          Icons.person,
                          "Owner",
                          ownerName,
                        ),
                        _detailRow(
                          Icons.email,
                          "Email",
                          email,
                        ),
                        _detailRow(
                          Icons.phone,
                          "Phone",
                          phone,
                        ),
                        _detailRow(
                          Icons.location_on,
                          "Address",
                          address,
                        ),
                        _detailRow(
                          Icons.badge,
                          "Permit Number",
                          permitNumber,
                        ),
                        _detailRow(
                          Icons.link,
                          "Store ID",
                          data["storeId"]?.toString() ?? "",
                        ),
                        const SizedBox(height: 22),
                        // ==========================================
                        // BUSINESS PERMIT
                        // ==========================================
                        const Text(
                          "Business Permit",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _documentImage(
                          permitImageUrl,
                          "Business Permit",
                        ),
                        const SizedBox(height: 22),
                        // ==========================================
                        // VALID ID
                        // ==========================================
                        const Text(
                          "Valid ID",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _documentImage(
                          validIdImageUrl,
                          "Valid ID",
                        ),
                        const SizedBox(height: 25),
                        // ==========================================
                        // PENDING ACTIONS
                        // ==========================================
                        if (status == "Pending")
                          Row(
                            children: [
                              // ====================================
                              // APPROVE
                              // ====================================
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: const Icon(Icons.check),
                                  label: const Text("Approve"),
                             onPressed: () async {
                         final bool? confirm = await showDialog<bool>(
                     context: dialogContext,
                 builder: (confirmContext) {
                return AlertDialog(
                   title: const Text("Approve Store"),
               content: const Text(
          "Are you sure you want to approve this store owner application?",
          ),
           actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(confirmContext, false);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(confirmContext, true);
            },
            child: const Text("Approve"),
          ),
        ],
      );
    },
  );
  if (confirm != true) return;
  try {
    await approveStore(context, uid);
    if (!context.mounted) return;
    // Isara lang ang details kapag successful ang approval.
    Navigator.pop(dialogContext);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Store approved successfully."),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error approving store: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
},
   ),
                              ),
                              const SizedBox(width: 10),
                              // ====================================
                              // REJECT
                              // ====================================
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: const Icon(Icons.close),
                                  label: const Text("Reject"),
                                  onPressed: () async {
                                    final bool? confirm =
                                        await showDialog<bool>(
                                      context: dialogContext,
                                      builder: (confirmContext) {
                                        return AlertDialog(
                                          title: const Text("Reject Store"),
                                          content: const Text(
                                            "Are you sure you want to reject this store owner application?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  confirmContext,
                                                  false,
                                                );
                                              },
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              style:
                                                  ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () {
                                                Navigator.pop(
                                                  confirmContext,
                                                  true,
                                                );
                                              },
                                              child: const Text("Reject"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (confirm != true) {
                                      return;
                                    }
                                    Navigator.pop(dialogContext);
                                    try {
                                      await rejectStore(context, uid);
                                      if (!context.mounted) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Store application rejected.",
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Error rejecting store: $e",
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        // ==========================================
                        // APPROVED
                        // ==========================================
                        if (status == "Approved")
                          _resultMessage(
                            icon: Icons.check_circle,
                            color: Colors.green,
                            message:
                                "This store application has been approved.",
                          ),
                        // ==========================================
                        // REPAIR / SYNC APPROVED STORE
                        // ==========================================
                        if (status == "Approved")
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.build_circle),
                                label: const Text(
                                  "Repair / Sync Store Record",
                                ),
                                onPressed: () async {
                                  try {
                                    final String storeId =
                                        await createOrRepairStore(uid);
                                    if (!context.mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Store record saved. Store ID: $storeId",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Error repairing store: $e",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        // ==========================================
                        // REJECTED
                        // ==========================================
                        if (status == "Rejected")
                          _resultMessage(
                            icon: Icons.cancel,
                            color: Colors.red,
                            message:
                                "This store application has been rejected.",
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // ============================================================
  // DETAIL ROW
  // ============================================================
  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? "N/A" : value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ============================================================
  // STATUS BOX
  // ============================================================
  Widget _statusBox(String status) {
    Color color;
    IconData icon;
    if (status == "Approved") {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (status == "Rejected") {
      color = Colors.red;
      icon = Icons.cancel;
    } else {
      color = Colors.orange;
      icon = Icons.pending;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(
            "Status: $status",
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  // ============================================================
  // DOCUMENT IMAGE
  // ============================================================
  Widget _documentImage(
    String imageUrl,
    String title,
  ) {
    if (imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Text(
          "No $title image available.",
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 280,
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
              height: 280,
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
            return SizedBox(
              height: 280,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.broken_image,
                      size: 45,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Unable to load $title image.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  // ============================================================
  // RESULT MESSAGE
  // ============================================================
  Widget _resultMessage({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Store Owner Applications"),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Container(
                width: double.infinity,
                height: constraints.maxHeight,
                constraints: const BoxConstraints(
                  maxWidth: 1000,
                ),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    218,
                    212,
                    229,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .where(
                          "role",
                          isEqualTo: "Store Owner",
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      // ==========================================
                      // LOADING
                      // ==========================================
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      // ==========================================
                      // ERROR
                      // ==========================================
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              "Error:\n${snapshot.error}",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      // ==========================================
                      // NO DATA
                      // ==========================================
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No Store Applications",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      // ==========================================
                      // SORT APPLICATIONS
                      // Pending -> Approved -> Rejected
                      // ==========================================
                      final applications =
                          snapshot.data!.docs.toList();
                      applications.sort((a, b) {
                        final aData =
                            a.data() as Map<String, dynamic>;
                        final bData =
                            b.data() as Map<String, dynamic>;
                        final String aStatus =
                            aData["status"]?.toString() ??
                                "Pending";
                        final String bStatus =
                            bData["status"]?.toString() ??
                                "Pending";
                        int priority(String status) {
                          switch (status) {
                            case "Pending":
                              return 0;
                            case "Approved":
                              return 1;
                            case "Rejected":
                              return 2;
                            default:
                              return 3;
                          }
                        }
                        return priority(aStatus)
                            .compareTo(priority(bStatus));
                      });
                      // ==========================================
                      // APPLICATION LIST
                      // ==========================================
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: applications.length,
                        itemBuilder: (context, index) {
                          final doc = applications[index];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final String storeName =
                              data["storeName"]
                                          ?.toString()
                                          .trim()
                                          .isNotEmpty ==
                                      true
                                  ? data["storeName"].toString()
                                  : "Unnamed Store";
                          final String status =
                              data["status"]?.toString() ??
                                  "Pending";
                          Color statusColor;
                          if (status == "Approved") {
                            statusColor = Colors.green;
                          } else if (status == "Rejected") {
                            statusColor = Colors.red;
                          } else {
                            statusColor = Colors.orange;
                          }
                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            elevation: 2,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(12),
                              onTap: () {
                                _showApplicationDetails(
                                  context,
                                  doc.id,
                                  data,
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 18,
                                ),
                                child: Row(
                                  children: [
                                    // ==========================
                                    // STORE ICON
                                    // ==========================
                                    Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: statusColor
                                            .withOpacity(0.10),
                                        borderRadius:
                                            BorderRadius.circular(
                                          10,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.store,
                                        color: statusColor,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // ==========================
                                    // STORE NAME
                                    // ==========================
                                    Expanded(
                                      child: Text(
                                        storeName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // ==========================
                                    // STATUS
                                    // ==========================
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor
                                            .withOpacity(0.10),
                                        borderRadius:
                                            BorderRadius.circular(
                                          20,
                                        ),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // ==========================
                                    // ARROW
                                    // ==========================
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}