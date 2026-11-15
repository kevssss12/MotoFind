class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  // Customer profile image
  final String profileImageUrl;
  // Store Owner fields
  final String storeName;
  final String storeAddress;
  final String permitNumber;
  final String permitImageUrl;
  final String validIdImageUrl;
  // Account status
  final String status;
  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    // Customer profile image
    this.profileImageUrl = "",
    // Store Owner fields
    this.storeName = "",
    this.storeAddress = "",
    this.permitNumber = "",
    this.permitImageUrl = "",
    this.validIdImageUrl = "",
    // Account status
    this.status = "Approved",
  });
  // ============================================================
  // FROM FIRESTORE
  // ============================================================
  factory UserModel.fromFirestore(String uid,Map<String, dynamic> data,) {      
    return UserModel(
      uid: uid,
      fullName: data['fullName'] ?? "",
      email: data['email'] ?? "",
      phone: data['phone'] ?? "",
      role: data['role'] ?? "",
      // Customer profile image
      profileImageUrl:data['profileImageUrl'] ?? "",
      // Store Owner fields
      storeName:data['storeName'] ?? "",
      storeAddress:data['storeAddress'] ?? "",         
      permitNumber:data['permitNumber'] ?? "",         
      permitImageUrl:data['permitImageUrl'] ?? "",         
      validIdImageUrl:data['validIdImageUrl'] ?? "",         
      // Account status
      status:data['status'] ?? "Approved",          
    );
  }
  // ============================================================
  // TO FIRESTORE
  // ============================================================
  Map<String, dynamic> toMap() {
    // ==========================================================
    // CUSTOMER
    // ==========================================================
    if (role == "Customer") {
      return {
        "fullName": fullName,
        "email": email,
        "phone": phone,
        "role": role,
        // Keep customer profile picture
        if (profileImageUrl.trim().isNotEmpty)
          "profileImageUrl":
              profileImageUrl.trim(),
      };
    }
    // ==========================================================
    // STORE OWNER
    // ==========================================================
    return {
      "fullName": fullName,
      "email": email,
      "phone": phone,
      "role": role,
      // Customer profile image field can still be used
      // if the Store Owner has a profile image.
      if (profileImageUrl.trim().isNotEmpty)
        "profileImageUrl":
            profileImageUrl.trim(),
      // Store Owner fields
      "storeName":storeName,         
      "storeAddress":storeAddress,         
      "permitNumber":permitNumber,        
      "permitImageUrl":permitImageUrl,        
      "validIdImageUrl":validIdImageUrl,
      // Account status
      "status":status,          
    };
  }
}