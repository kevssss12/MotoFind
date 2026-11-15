
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // REGISTER
  // ============================================================

  Future<UserCredential> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String storeName = "",
    String storeAddress = "",
    String permitNumber = "",
    String permitImageUrl = "",
    String validIdImageUrl = "",
  }) async {
    final String cleanEmail =
        email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw Exception(
        "Please enter your email address.",
      );
    }

    if (password.isEmpty) {
      throw Exception(
        "Please enter your password.",
      );
    }

    // ==========================================================
    // CREATE FIREBASE AUTH ACCOUNT
    //
    // We do NOT check the users collection here because a newly
    // registering user is not authenticated yet.
    //
    // Firebase Authentication automatically detects:
    // - email-already-in-use
    // - invalid-email
    // - weak-password
    // - etc.
    // ==========================================================

    UserCredential userCredential;

    try {
      userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(
        _getAuthErrorMessage(e),
      );
    }

    // ==========================================================
    // GET CREATED USER
    // ==========================================================

    final User? user =
        userCredential.user;

    if (user == null) {
      throw Exception(
        "Unable to create user account.",
      );
    }

    // ==========================================================
    // CREATE USER MODEL
    // ==========================================================

    final UserModel userModel =
        UserModel(
      uid: user.uid,
      fullName: fullName.trim(),
      email: cleanEmail,
      phone: phone.trim(),
      role: role,

      storeName:
          storeName.trim(),

      storeAddress:
          storeAddress.trim(),

      permitNumber:
          permitNumber.trim(),

      permitImageUrl:
          permitImageUrl.trim(),

      validIdImageUrl:
          validIdImageUrl.trim(),

      // ========================================================
      // IMPORTANT:
      // EVERY NEW ACCOUNT MUST WAIT FOR ADMIN APPROVAL
      // ========================================================

      status: "Pending",
    );

    // ==========================================================
    // SAVE USER TO FIRESTORE
    // ==========================================================

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        userModel.toMap(),
      );
    } on FirebaseException catch (e) {
      // Firebase Auth account was created successfully,
      // but Firestore user document failed.
      //
      // Sign out so the user does not remain logged in.

      await _auth.signOut();

      throw Exception(
        "Account was created but user data could not be saved: "
        "${e.message ?? e.code}",
      );
    }

    return userCredential;
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final String cleanEmail =
        email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw Exception(
        "Please enter your email address.",
      );
    }

    if (password.isEmpty) {
      throw Exception(
        "Please enter your password.",
      );
    }

    try {
      return await _auth
          .signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(
        _getAuthErrorMessage(e),
      );
    }
  }

  // ============================================================
  // CHECK IF EMAIL IS REGISTERED
  //
  // NOTE:
  // This method is NOT used during registration anymore.
  //
  // It may still be used elsewhere in the application.
  // Since it reads Firestore, the caller should already be
  // authenticated according to the current Firestore Rules.
  // ============================================================

  Future<bool> isEmailRegistered(
    String email,
  ) async {
    final String cleanEmail =
        email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      return false;
    }

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where(
                'email',
                isEqualTo: cleanEmail,
              )
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw Exception(
        "Unable to check email: ${e.message ?? e.code}",
      );
    }
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> resetPassword(
    String email,
  ) async {
    final String cleanEmail =
        email.trim().toLowerCase();

    // ==========================================================
    // EMPTY EMAIL
    // ==========================================================

    if (cleanEmail.isEmpty) {
      throw Exception(
        "Please enter your email address.",
      );
    }

    // ==========================================================
    // EMAIL FORMAT
    // ==========================================================

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(cleanEmail)) {
      throw Exception(
        "Please enter a valid email address.",
      );
    }

    // ==========================================================
    // SEND PASSWORD RESET EMAIL
    // ==========================================================

    try {
      print(
        "PASSWORD RESET: Sending request to $cleanEmail",
      );

      await _auth.sendPasswordResetEmail(
        email: cleanEmail,
      );

      print(
        "PASSWORD RESET: Email request sent successfully",
      );
    } on FirebaseAuthException catch (e) {
      print(
        "PASSWORD RESET FIREBASE ERROR: "
        "${e.code} - ${e.message}",
      );

      switch (e.code) {
        case 'invalid-email':
          throw Exception(
            "The email address is invalid.",
          );

        case 'user-disabled':
          throw Exception(
            "This account has been disabled.",
          );

        case 'too-many-requests':
          throw Exception(
            "Too many password reset requests. "
            "Please wait a while before trying again.",
          );

        case 'network-request-failed':
          throw Exception(
            "Please check your internet connection.",
          );

        case 'operation-not-allowed':
          throw Exception(
            "Password reset is not enabled in Firebase Authentication.",
          );

        default:
          throw Exception(
            e.message ??
                "Unable to send password reset email.",
          );
      }
    }
  }

  // ============================================================
  // GET USER DATA
  // ============================================================

  Future<UserModel?> getUserData(
    String uid,
  ) async {
    try {
      final DocumentSnapshot doc =
          await _firestore
              .collection('users')
              .doc(uid)
              .get();

      if (doc.exists) {
        final data =
            doc.data();

        if (data == null) {
          return null;
        }

        return UserModel.fromFirestore(
          doc.id,
          data as Map<String, dynamic>,
        );
      }

      return null;
    } on FirebaseException catch (e) {
      throw Exception(
        "Unable to get user data: ${e.message ?? e.code}",
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser =>
      _auth.currentUser;

  // ============================================================
  // FIREBASE AUTH ERROR MESSAGES
  // ============================================================

  String _getAuthErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-email':
        return "The email address is invalid.";

      case 'user-not-found':
        return "No account was found with this email.";

      case 'wrong-password':
      case 'invalid-credential':
        return "Incorrect email or password.";

      case 'email-already-in-use':
        return "This email is already registered.";

      case 'weak-password':
        return "Password is too weak.";

      case 'user-disabled':
        return "This account has been disabled.";

      case 'too-many-requests':
        return "Too many attempts. Please try again later.";

      case 'network-request-failed':
        return "Please check your internet connection.";

      case 'operation-not-allowed':
        return "Email/password login is not enabled in Firebase.";

      default:
        return e.message ??
            "Authentication failed. Please try again.";
    }
  }
}
