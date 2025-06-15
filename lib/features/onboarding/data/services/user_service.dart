import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/collections.dart';
import 'package:mymink/core/utils/firestore_utils.dart';
import 'package:mymink/core/utils/result.dart';
import 'package:mymink/core/widgets/custom_dialog.dart';
import 'package:mymink/features/onboarding/data/services/auth_service.dart';
import '../models/user_model.dart';

class UserService {
  // Singleton instance
  static final UserService _instance = UserService._internal();

  // Private constructor
  UserService._internal();

  // Factory constructor
  factory UserService() => _instance;

  // Firebase Firestore instance
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get user by email
  static Future<Result<UserModel>> getUserByEmail({
    required String email,
    String? regiType,
  }) async {
    try {
      var query =
          _db.collection(Collections.users).where('email', isEqualTo: email);
      if (regiType != null && regiType.isNotEmpty) {
        query = query.where('regiType', isEqualTo: regiType);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final userModel =
            fromFirestore(snapshot.docs.first, UserModel.fromJson);
        return Result(data: userModel);
      }

      return Result(
          error: 'No user found or data deleted. Please create a new account.');
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  static Future<Result<UserModel>> getUserByPhone(
      {required String phoneNumber}) async {
    try {
      var query = _db
          .collection(Collections.users)
          .where('phoneNumber', isEqualTo: phoneNumber);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final userModel =
            fromFirestore(snapshot.docs.first, UserModel.fromJson);
        return Result(data: userModel);
      }

      return Result(
          error: 'No user found or data deleted. Please create a new account.');
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  /// Handle user state by UID
  static Future<void> handleUserStateByUid(
      BuildContext context, String uid) async {
    try {
      final result = await getUserByUid(uid: uid);

      if (result.hasError) {
        await CustomDialog.show(context,
            title: 'Error', message: result.error!);
        AuthService.logout(context);
        return;
      }

      final user = result.data!;
      UserModel.data = user;

      // Check if user is blocked
      if (user.isBlocked ?? false) {
        await CustomDialog.show(context,
            title: 'Blocked', message: 'Your account has been blocked.');
        AuthService.logout(context);
        return;
      }

      // Check if username is missing
      if (user.username == null || user.username!.isEmpty) {
        context.push(AppRoutes.complete_profile);
        return;
      }

      // Navigate to TabBar if all checks pass
      context.go(AppRoutes.tabbar);
    } catch (e) {
      await CustomDialog.show(context,
          title: 'Error', message: 'Something went wrong.');
      AuthService.logout(context);
    }
  }

  /// Get user by UID
  static Future<Result<UserModel>> getUserByUid({required String uid}) async {
    try {
      final snapshot = await _db.collection(Collections.users).doc(uid).get();

      if (snapshot.exists) {
        final userModel = fromFirestore(snapshot, UserModel.fromJson);
        return Result(data: userModel);
      }

      return Result(
          error: 'No user found or data deleted. Please create a new account.');
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  static Future<bool> isUsernameAvailable(String sUsername) async {
    try {
      final snapshot = await _db
          .collection(Collections.users)
          .where('username', isEqualTo: sUsername)
          .get();

      // Return true if the username is available (not found in Firestore)
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // Handle error
      print('Error checking username availability: $e');
      return false;
    }
  }

  static Future<Result<String?>> updateUser(UserModel userModel) async {
    try {
      UserModel.data = userModel;
      await _db
          .collection(Collections.users)
          .doc(userModel.uid!)
          .set(userModel.toJson(), SetOptions(merge: true));

      return Result(error: null);
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  /// Add a new user
  static Future<Result<UserModel>> addNewUser(
    String uid,
    String name,
    String? email,
    String regiType,
    String? phoneNumber,
    String? encryptKey,
    String? encryptPassword,
  ) async {
    try {
      final userModel = UserModel()
        ..isBlocked = false
        ..regiType = regiType
        ..registredAt = DateTime.now()
        ..fullName = name
        ..encryptKey = encryptKey
        ..encryptPassword = encryptPassword
        ..email = email
        ..phoneNumber = phoneNumber
        ..uid = uid;

      UserModel.data = userModel;

      await _db
          .collection(Collections.users)
          .doc(userModel.uid!)
          .set(userModel.toJson());

      return Result(data: userModel);
    } catch (e) {
      return Result(error: e.toString());
    }
  }
}
